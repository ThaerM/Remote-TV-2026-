import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../logging/app_logger.dart';

/// One SSDP answer (an HTTP-over-UDP response to M-SEARCH).
class SsdpResponse {
  const SsdpResponse({required this.headers, required this.sender});

  /// Header names lower-cased.
  final Map<String, String> headers;
  final InternetAddress sender;

  String? get location => headers['location'];
  String? get usn => headers['usn'];
  String? get st => headers['st'];

  /// Parses an `HTTP/1.1 200 OK` search response; returns null for
  /// anything else (NOTIFY announcements, M-SEARCH echoes, garbage).
  static SsdpResponse? parse(List<int> datagram, InternetAddress sender) {
    final String text;
    try {
      text = utf8.decode(datagram, allowMalformed: true);
    } catch (_) {
      return null;
    }
    final lines = const LineSplitter().convert(text);
    if (lines.isEmpty ||
        !lines.first.toUpperCase().startsWith('HTTP/1.1 200')) {
      return null;
    }
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final colon = line.indexOf(':');
      if (colon <= 0) continue;
      headers[line.substring(0, colon).trim().toLowerCase()] = line
          .substring(colon + 1)
          .trim();
    }
    return SsdpResponse(headers: headers, sender: sender);
  }
}

/// Why an SSDP search couldn't run. Mirrors the discovery issues the TV
/// layer reports, without `core` depending on the TV domain.
enum SsdpFailure { multicastRestricted, networkUnavailable, failed }

class SsdpSearchResult {
  const SsdpSearchResult(this.responses, {this.failure});

  final List<SsdpResponse> responses;
  final SsdpFailure? failure;
}

/// The datagram surface [SsdpSearcher] needs, injectable so tests never
/// open a real socket.
abstract interface class SsdpTransport {
  Future<void> open();
  void send(List<int> bytes, InternetAddress address, int port);
  Stream<({List<int> data, InternetAddress sender})> get datagrams;
  void close();
}

/// A UDP socket on an ephemeral port. M-SEARCH responses are *unicast*
/// back to this port, so no multicast group join (and no Android multicast
/// lock) is needed to receive them - only the outgoing search is sent to
/// the multicast group. On iOS even that send requires Apple's
/// `com.apple.developer.networking.multicast` entitlement; without it the
/// send fails and the search reports [SsdpFailure.multicastRestricted].
class UdpSsdpTransport implements SsdpTransport {
  RawDatagramSocket? _socket;
  final _datagrams =
      StreamController<({List<int> data, InternetAddress sender})>();

  @override
  Future<void> open() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.multicastHops = 4;
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram != null) {
        _datagrams.add((data: datagram.data, sender: datagram.address));
      }
    });
    _socket = socket;
  }

  @override
  void send(List<int> bytes, InternetAddress address, int port) {
    final sent = _socket?.send(bytes, address, port) ?? 0;
    if (sent == 0) {
      throw const SocketException('SSDP search datagram was not sent');
    }
  }

  @override
  Stream<({List<int> data, InternetAddress sender})> get datagrams =>
      _datagrams.stream;

  @override
  void close() {
    _socket?.close();
    _socket = null;
    unawaited(_datagrams.close());
  }
}

/// Bounded SSDP M-SEARCH. Never throws: failures come back as
/// [SsdpSearchResult.failure] with whatever answered before them.
class SsdpSearcher {
  SsdpSearcher({SsdpTransport Function()? transportFactory})
    : _transportFactory = transportFactory ?? UdpSsdpTransport.new,
      _logger = AppLogger('Network.SSDP');

  static final multicastAddress = InternetAddress('239.255.255.250');
  static const multicastPort = 1900;

  final SsdpTransport Function() _transportFactory;
  final AppLogger _logger;

  /// Sends the M-SEARCH a few times (UDP is lossy) and collects answers for
  /// [timeout], de-duplicated by USN (or location, or sender).
  Future<SsdpSearchResult> search(
    String searchTarget, {
    Duration timeout = const Duration(seconds: 4),
    int mx = 2,
  }) async {
    final request = utf8.encode(
      'M-SEARCH * HTTP/1.1\r\n'
      'HOST: 239.255.255.250:1900\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: $mx\r\n'
      'ST: $searchTarget\r\n'
      '\r\n',
    );
    final byKey = <String, SsdpResponse>{};
    SsdpFailure? failure;
    SsdpTransport? transport;
    StreamSubscription<({List<int> data, InternetAddress sender})>? sub;
    final resend = <Timer>[];

    try {
      transport = _transportFactory();
      await transport.open().timeout(timeout);
      sub = transport.datagrams.listen((datagram) {
        final response = SsdpResponse.parse(datagram.data, datagram.sender);
        if (response == null) return;
        final st = response.st;
        if (st != null && st.toLowerCase() != searchTarget.toLowerCase()) {
          return;
        }
        final key =
            response.usn ?? response.location ?? response.sender.address;
        byKey.putIfAbsent(key, () => response);
      });

      final activeTransport = transport;
      void sendSearch() {
        activeTransport.send(request, multicastAddress, multicastPort);
      }

      sendSearch();
      for (final delay in const [300, 900]) {
        resend.add(
          Timer(Duration(milliseconds: delay), () {
            try {
              sendSearch();
            } catch (_) {
              // The first send already proved the path works or failed.
            }
          }),
        );
      }
      await Future<void>.delayed(timeout);
    } catch (error) {
      failure = classifySsdpError(error);
      _logger.warning(
        '[NETWORK][SSDP] search_failed st=$searchTarget reason=${failure.name} '
        'type=${error.runtimeType}',
      );
    } finally {
      for (final timer in resend) {
        timer.cancel();
      }
      await sub?.cancel();
      transport?.close();
    }

    _logger.info(
      '[NETWORK][SSDP] search_completed st=$searchTarget count=${byKey.length}',
    );
    return SsdpSearchResult(byKey.values.toList(), failure: failure);
  }
}

/// EHOSTUNREACH/EPERM/EACCES on the multicast send is how iOS (without the
/// multicast entitlement) and sandboxes refuse it; ENETDOWN/ENETUNREACH
/// mean no usable network.
SsdpFailure classifySsdpError(Object error) {
  final code = switch (error) {
    OSError(:final errorCode) => errorCode,
    SocketException(:final osError) => osError?.errorCode,
    _ => null,
  };
  return switch (code) {
    1 || 13 || 65 || 113 => SsdpFailure.multicastRestricted,
    50 || 51 || 100 || 101 => SsdpFailure.networkUnavailable,
    _ => SsdpFailure.failed,
  };
}
