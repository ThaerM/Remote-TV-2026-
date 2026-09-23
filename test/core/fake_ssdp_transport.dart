import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:remote_tv_2026/core/network/ssdp.dart';

/// Scripted [SsdpTransport]: every M-SEARCH it's asked to send is answered
/// with [replies] (raw response text, sender address).
class FakeSsdpTransport implements SsdpTransport {
  FakeSsdpTransport({this.replies = const [], this.sendError});

  final List<(String, String)> replies;
  final Object? sendError;
  final sent = <String>[];
  bool closed = false;
  final _controller =
      StreamController<({List<int> data, InternetAddress sender})>();

  @override
  Future<void> open() async {}

  @override
  void send(List<int> bytes, InternetAddress address, int port) {
    if (sendError != null) throw sendError!;
    sent.add(utf8.decode(bytes));
    for (final (text, sender) in replies) {
      scheduleMicrotask(
        () => _controller.add((
          data: utf8.encode(text),
          sender: InternetAddress(sender),
        )),
      );
    }
  }

  @override
  Stream<({List<int> data, InternetAddress sender})> get datagrams =>
      _controller.stream;

  @override
  void close() {
    closed = true;
    unawaited(_controller.close());
  }
}

String ssdpReply({
  required String st,
  required String location,
  required String usn,
}) =>
    'HTTP/1.1 200 OK\r\n'
    'Cache-Control: max-age=3600\r\n'
    'ST: $st\r\n'
    'USN: $usn\r\n'
    'Ext: \r\n'
    'Server: Roku/12.0.0 UPnP/1.0 Roku/12.0.0\r\n'
    'LOCATION: $location\r\n'
    '\r\n';
