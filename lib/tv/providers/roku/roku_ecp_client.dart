import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/tv_domain.dart';

/// Roku External Control Protocol constants - see
/// https://developer.roku.com/docs/developer-program/dev-tools/external-control-api.md
abstract final class RokuConstants {
  static const int ecpPort = 8060;
  static const String ssdpSearchTarget = 'roku:ecp';
  static const Duration requestTimeout = Duration(seconds: 3);
}

class RokuHttpResponse {
  const RokuHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;

  bool get ok => statusCode >= 200 && statusCode < 300;
}

/// The HTTP surface the ECP client needs, injectable for tests.
abstract interface class RokuHttpTransport {
  Future<RokuHttpResponse> get(Uri uri);
  Future<RokuHttpResponse> post(Uri uri);
}

class IoRokuHttpTransport implements RokuHttpTransport {
  IoRokuHttpTransport({HttpClient? client})
    : _client =
          client ??
          (HttpClient()..connectionTimeout = RokuConstants.requestTimeout);

  final HttpClient _client;

  @override
  Future<RokuHttpResponse> get(Uri uri) => _send('GET', uri);

  @override
  Future<RokuHttpResponse> post(Uri uri) => _send('POST', uri);

  Future<RokuHttpResponse> _send(String method, Uri uri) async {
    final request = await _client
        .openUrl(method, uri)
        .timeout(RokuConstants.requestTimeout);
    if (method == 'POST') request.contentLength = 0;
    final response = await request.close().timeout(
      RokuConstants.requestTimeout,
    );
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(RokuConstants.requestTimeout);
    return RokuHttpResponse(response.statusCode, body);
  }
}

/// `/query/device-info` fields this app uses. Everything else is ignored.
class RokuDeviceInfo {
  const RokuDeviceInfo({
    required this.serialNumber,
    required this.name,
    required this.isTv,
    this.modelName,
    this.supportsFindRemote = false,
  });

  final String serialNumber;
  final String name;
  final bool isTv;
  final String? modelName;
  final bool supportsFindRemote;

  static RokuDeviceInfo? parse(String xml) {
    final serial = _tag(xml, 'serial-number') ?? _tag(xml, 'device-id');
    if (serial == null || serial.isEmpty) return null;
    final model = _tag(xml, 'model-name');
    final name =
        _nonEmpty(_tag(xml, 'user-device-name')) ??
        _nonEmpty(_tag(xml, 'friendly-device-name')) ??
        _nonEmpty(_tag(xml, 'friendly-model-name')) ??
        model ??
        'Roku';
    return RokuDeviceInfo(
      serialNumber: serial,
      name: name,
      isTv: _tag(xml, 'is-tv') == 'true',
      modelName: model,
      supportsFindRemote: _tag(xml, 'supports-find-remote') == 'true',
    );
  }
}

/// `/query/apps` entries. Only `type="appl"` (channels); TV inputs
/// (`tvin`) and menu entries aren't apps a user launches from a list.
List<TvApplication> parseRokuApps(String xml) {
  final apps = <TvApplication>[];
  final pattern = RegExp(r'<app\s+([^>]*)>([^<]*)</app>');
  for (final match in pattern.allMatches(xml)) {
    final attributes = match.group(1)!;
    final id = RegExp(r'id="([^"]*)"').firstMatch(attributes)?.group(1);
    final type = RegExp(r'type="([^"]*)"').firstMatch(attributes)?.group(1);
    final name = _decodeXml(match.group(2)!.trim());
    if (id == null || id.isEmpty || name.isEmpty) continue;
    if (type != null && type != 'appl') continue;
    apps.add(TvApplication(id: id, name: name));
  }
  return apps;
}

/// Minimal ECP client. Each call is one bounded HTTP request; failures are
/// translated into the [TvException] hierarchy.
class RokuEcpClient {
  RokuEcpClient(this.host, this._transport);

  final String host;
  final RokuHttpTransport _transport;

  Uri _uri(String path) =>
      Uri(scheme: 'http', host: host, port: RokuConstants.ecpPort, path: path);

  Future<RokuDeviceInfo> deviceInfo() async {
    final response = await _call(
      () => _transport.get(_uri('/query/device-info')),
    );
    final info = RokuDeviceInfo.parse(response.body);
    if (info == null) {
      throw const ProtocolErrorException(
        'The Roku device-info response was not recognized.',
      );
    }
    return info;
  }

  Future<List<TvApplication>> apps() async {
    final response = await _call(() => _transport.get(_uri('/query/apps')));
    return parseRokuApps(response.body);
  }

  Future<void> keypress(String key) =>
      _call(() => _transport.post(_uri('/keypress/$key')));

  Future<void> launch(String appId) => _call(
    () => _transport.post(_uri('/launch/${Uri.encodeComponent(appId)}')),
  );

  /// Types [text] one character at a time with ECP's `Lit_` keys.
  Future<void> typeText(String text) async {
    for (final rune in text.runes) {
      await keypress('Lit_${Uri.encodeComponent(String.fromCharCode(rune))}');
    }
  }

  Future<RokuHttpResponse> _call(
    Future<RokuHttpResponse> Function() request,
  ) async {
    final RokuHttpResponse response;
    try {
      response = await request();
    } on TimeoutException {
      throw DeviceNotReachableException('The Roku at $host did not respond.');
    } on SocketException catch (error) {
      throw DeviceNotReachableException(
        'Could not reach the Roku at $host (${error.osError?.message ?? error.message}).',
      );
    } on HttpException catch (error) {
      throw DeviceNotReachableException(
        'Could not reach the Roku at $host (${error.message}).',
      );
    }
    if (response.statusCode == 403) {
      // Roku OS gates ECP behind Settings > System > Advanced system
      // settings > Control by mobile apps; "Disabled" (and some "Limited"
      // cases) answer 403 rather than dropping the connection.
      throw const AuthenticationFailedException(
        'This Roku refused remote control. On the Roku, open Settings > '
        'System > Advanced system settings > Control by mobile apps and '
        'set Network access to Default.',
      );
    }
    if (!response.ok) {
      throw ProtocolErrorException(
        'The Roku answered HTTP ${response.statusCode}.',
      );
    }
    return response;
  }
}

String? _tag(String xml, String name) {
  final match = RegExp('<$name>([^<]*)</$name>').firstMatch(xml);
  return match == null ? null : _decodeXml(match.group(1)!.trim());
}

String? _nonEmpty(String? value) =>
    value == null || value.isEmpty ? null : value;

String _decodeXml(String value) => value
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');
