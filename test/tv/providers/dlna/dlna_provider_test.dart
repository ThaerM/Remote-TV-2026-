import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/network/ssdp.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/dlna/dlna_provider.dart';
import 'package:remote_tv_2026/tv/providers/dlna/dlna_soap.dart';

import '../../../core/fake_ssdp_transport.dart';

String _description({bool rendering = true, bool avTransport = true}) =>
    '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>Bedroom TV (DLNA)</friendlyName>
    <manufacturer>ACME</manufacturer>
    <UDN>uuid:dlna-1</UDN>
    <serviceList>
      ${avTransport ? '''<service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <serviceId>urn:upnp-org:serviceId:AVTransport</serviceId>
        <controlURL>/upnp/control/AVTransport1</controlURL>
      </service>''' : ''}
      ${rendering ? '''<service>
        <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
        <serviceId>urn:upnp-org:serviceId:RenderingControl</serviceId>
        <controlURL>upnp/control/RenderingControl1</controlURL>
      </service>''' : ''}
    </serviceList>
  </device>
</root>''';

/// A fake MediaRenderer answering SOAP like a real one.
class _FakeRenderer {
  _FakeRenderer({this.faultOnSetUri});

  final String? faultOnSetUri;
  String state = 'NO_MEDIA_PRESENT';
  String relTime = '0:00:00';
  int volume = 20;
  bool muted = false;
  final calls = <String>[];
  final bodies = <String, String>{};

  Future<SoapResponse> post(Uri url, String soapAction, String body) async {
    final action = soapAction.split('#').last;
    calls.add('${url.path} $action');
    bodies[action] = body;
    String arg(String name) =>
        RegExp('<$name>([^<]*)</$name>').firstMatch(body)?.group(1) ?? '';
    final out = <String, String>{};
    switch (action) {
      case 'SetAVTransportURI':
        if (faultOnSetUri != null) {
          return SoapResponse(
            500,
            '<s:Envelope><s:Body><s:Fault><detail><UPnPError>'
            '<errorCode>$faultOnSetUri</errorCode></UPnPError></detail>'
            '</s:Fault></s:Body></s:Envelope>',
          );
        }
        state = 'STOPPED';
      case 'Play':
        state = 'PLAYING';
      case 'Pause':
        state = 'PAUSED_PLAYBACK';
      case 'Stop':
        state = 'STOPPED';
      case 'Seek':
        relTime = arg('Target');
      case 'GetTransportInfo':
        out['CurrentTransportState'] = state;
        out['CurrentTransportStatus'] = 'OK';
      case 'GetPositionInfo':
        out['RelTime'] = relTime;
        out['TrackDuration'] = '0:10:00';
      case 'GetVolume':
        out['CurrentVolume'] = '$volume';
      case 'SetVolume':
        volume = int.parse(arg('DesiredVolume'));
      case 'GetMute':
        out['CurrentMute'] = muted ? '1' : '0';
      case 'SetMute':
        muted = arg('DesiredMute') == '1';
    }
    final args = out.entries
        .map((e) => '<${e.key}>${e.value}</${e.key}>')
        .join();
    return SoapResponse(
      200,
      '<?xml version="1.0"?><s:Envelope><s:Body>'
      '<u:${action}Response xmlns:u="x">$args</u:${action}Response>'
      '</s:Body></s:Envelope>',
    );
  }
}

Future<(DlnaProvider, TvDevice)> _discovered(
  _FakeRenderer renderer, {
  bool rendering = true,
}) async {
  final provider = DlnaProvider(
    ssdp: SsdpSearcher(
      transportFactory: () => FakeSsdpTransport(
        replies: [
          (
            ssdpReply(
              st: 'urn:schemas-upnp-org:device:MediaRenderer:1',
              location: 'http://10.0.0.30:49152/description.xml',
              usn: 'uuid:dlna-1::urn:schemas-upnp-org:device:MediaRenderer:1',
            ),
            '10.0.0.30',
          ),
        ],
      ),
    ),
    httpGet: (uri) async => _description(rendering: rendering),
    post: renderer.post,
    pollInterval: const Duration(hours: 1),
  );
  final devices = (await provider.discover()).devices;
  return (provider, devices.single);
}

final _video = TvMediaItem(
  url: Uri.parse('http://10.0.0.2:8000/movie.mp4?a=1&b=2'),
  contentType: 'video/mp4',
  title: 'Tom & Jerry',
);

void main() {
  test('time format round-trips', () {
    expect(
      parseUpnpTime('1:02:03.500'),
      const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 500),
    );
    expect(parseUpnpTime('NOT_IMPLEMENTED'), isNull);
    expect(formatUpnpTime(const Duration(minutes: 75, seconds: 5)), '1:15:05');
  });

  test(
    'discovers renderers with AVTransport, resolving relative control URLs',
    () async {
      final renderer = _FakeRenderer();
      final (provider, device) = await _discovered(renderer);

      expect(device.name, 'Bedroom TV (DLNA)');
      expect(device.id, 'dlna:dlna-1');
      await provider.connect(device);
      expect(
        renderer.calls.single,
        '/upnp/control/AVTransport1 GetTransportInfo',
      );
    },
  );

  test(
    'a media target: casting + transport + volume, never remote keys',
    () async {
      final (provider, device) = await _discovered(_FakeRenderer());
      await provider.connect(device);

      final caps = await provider.getCapabilities();
      expect(caps.casting && caps.mediaControls && caps.volume, isTrue);
      expect(caps.dpad || caps.keyboard || caps.launchApps, isFalse);
      expect(await provider.probeHost('10.0.0.30'), isNull);
    },
  );

  test('without RenderingControl there is no volume', () async {
    final (provider, device) = await _discovered(
      _FakeRenderer(),
      rendering: false,
    );
    await provider.connect(device);

    expect((await provider.getCapabilities()).volume, isFalse);
  });

  test('casting sets the URI with escaped DIDL-Lite, then plays', () async {
    final renderer = _FakeRenderer();
    final (provider, device) = await _discovered(renderer);
    final statuses = <TvMediaStatus?>[];
    provider.mediaStatus.listen(statuses.add);
    await provider.connect(device);

    await provider.castMedia(_video);
    await Future<void>.delayed(Duration.zero);

    expect(
      renderer.calls.map((c) => c.split(' ').last),
      containsAllInOrder([
        'SetAVTransportURI',
        'Play',
        'GetTransportInfo',
        'GetPositionInfo',
      ]),
    );
    final body = renderer.bodies['SetAVTransportURI']!;
    expect(
      body,
      contains(
        '<CurrentURI>http://10.0.0.2:8000/movie.mp4?a=1&amp;b=2</CurrentURI>',
      ),
    );
    expect(body, contains('protocolInfo=&quot;http-get:*:video/mp4:*&quot;'));
    expect(body, contains('Tom &amp;amp; Jerry'));
    expect(statuses.last?.playerState, TvPlayerState.playing);
    expect(statuses.last?.duration, const Duration(minutes: 10));
    expect(statuses.last?.title, 'Tom & Jerry');
  });

  test('toggle, seek and stop map to AVTransport actions', () async {
    final renderer = _FakeRenderer();
    final (provider, device) = await _discovered(renderer);
    await provider.connect(device);
    await provider.castMedia(_video);

    await provider.togglePlayback();
    expect(renderer.state, 'PAUSED_PLAYBACK');
    await provider.seek(const Duration(minutes: 2, seconds: 5));
    expect(renderer.relTime, '0:02:05');
    await provider.stopMedia();
    expect(renderer.state, 'STOPPED');
  });

  test('an unsupported format fault is explained', () async {
    final (provider, device) = await _discovered(
      _FakeRenderer(faultOnSetUri: '714'),
    );
    await provider.connect(device);

    await expectLater(
      provider.castMedia(_video),
      throwsA(
        isA<TvMediaSessionException>().having(
          (e) => e.message,
          'message',
          contains('cannot play this media'),
        ),
      ),
    );
  });

  test('volume steps by 5 within 0..100, mute toggles', () async {
    final renderer = _FakeRenderer()..volume = 98;
    final (provider, device) = await _discovered(renderer);
    await provider.connect(device);

    await provider.sendCommand(const TvCommand.key(TvCommandKey.volumeUp));
    expect(renderer.volume, 100);
    await provider.sendCommand(const TvCommand.key(TvCommandKey.mute));
    expect(renderer.muted, isTrue);
  });

  test('a device not discovered this session asks for a rescan', () async {
    final provider = DlnaProvider(post: _FakeRenderer().post);

    await expectLater(
      provider.connect(
        const TvDevice(id: 'dlna:x', name: 'x', platform: TvPlatform.dlna),
      ),
      throwsA(isA<DeviceNotReachableException>()),
    );
  });
}
