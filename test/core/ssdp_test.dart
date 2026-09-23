import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/network/ssdp.dart';

import 'fake_ssdp_transport.dart';

void main() {
  group('SsdpResponse.parse', () {
    test('reads headers case-insensitively', () {
      final response = SsdpResponse.parse(
        ssdpReply(
          st: 'roku:ecp',
          location: 'http://192.168.1.134:8060/',
          usn: 'uuid:roku:ecp:P0A070000007',
        ).codeUnits,
        InternetAddress('192.168.1.134'),
      );

      expect(response?.st, 'roku:ecp');
      expect(response?.location, 'http://192.168.1.134:8060/');
      expect(response?.usn, 'uuid:roku:ecp:P0A070000007');
    });

    test('ignores NOTIFY announcements and garbage', () {
      final sender = InternetAddress('10.0.0.1');
      expect(
        SsdpResponse.parse('NOTIFY * HTTP/1.1\r\n\r\n'.codeUnits, sender),
        isNull,
      );
      expect(SsdpResponse.parse(const [0xff, 0x00], sender), isNull);
    });
  });

  group('SsdpSearcher', () {
    test(
      'collects answers, de-duplicated by USN, for the requested target',
      () async {
        final transport = FakeSsdpTransport(
          replies: [
            (
              ssdpReply(
                st: 'roku:ecp',
                location: 'http://10.0.0.5:8060/',
                usn: 'uuid:roku:ecp:A',
              ),
              '10.0.0.5',
            ),
            (
              ssdpReply(
                st: 'roku:ecp',
                location: 'http://10.0.0.5:8060/',
                usn: 'uuid:roku:ecp:A',
              ),
              '10.0.0.5',
            ),
            (
              ssdpReply(
                st: 'urn:dial-multiscreen-org:service:dial:1',
                location: 'http://10.0.0.9/',
                usn: 'x',
              ),
              '10.0.0.9',
            ),
          ],
        );

        final result = await SsdpSearcher(transportFactory: () => transport)
            .search('roku:ecp', timeout: const Duration(milliseconds: 1200));

        expect(result.failure, isNull);
        expect(result.responses.single.usn, 'uuid:roku:ecp:A');
        expect(transport.sent.first, contains('ST: roku:ecp'));
        expect(transport.sent.first, contains('MAN: "ssdp:discover"'));
        expect(
          transport.sent,
          hasLength(3),
          reason: 'resent twice for UDP loss',
        );
        expect(transport.closed, isTrue);
      },
    );

    test('a refused multicast send is reported as restricted', () async {
      final transport = FakeSsdpTransport(
        sendError: const SocketException(
          'Send failed',
          osError: OSError('No route to host', 65),
        ),
      );

      final result = await SsdpSearcher(transportFactory: () => transport)
          .search('roku:ecp', timeout: const Duration(milliseconds: 200));

      expect(result.failure, SsdpFailure.multicastRestricted);
      expect(result.responses, isEmpty);
      expect(transport.closed, isTrue);
    });

    test('no network is reported as networkUnavailable', () {
      expect(
        classifySsdpError(const OSError('Network is unreachable', 51)),
        SsdpFailure.networkUnavailable,
      );
      expect(classifySsdpError(StateError('x')), SsdpFailure.failed);
    });
  });
}
