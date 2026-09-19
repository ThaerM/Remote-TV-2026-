import 'dart:async';
import 'dart:typed_data';

/// A connected, message-framed duplex channel to an Android TV endpoint
/// (pairing port 6467 or remote-control port 6466).
///
/// Both the pairing and remote-control protocols frame each protobuf
/// message with a varint length prefix on the wire. This interface hides
/// that framing plus the underlying TLS socket behind something the
/// pairing/remote state machines can be tested against without a real
/// network connection - see
/// `test/tv/providers/android_tv/fake_android_tv_transport.dart`.
abstract interface class AndroidTvMessageTransport {
  /// Complete, de-framed protobuf message payloads as they arrive.
  Stream<Uint8List> get messages;

  /// Completes when the underlying connection closes, with the error
  /// that caused it (if any).
  Future<Object?> get done;

  /// Sends one message, adding the varint length prefix.
  void send(Uint8List messageBytes);

  Future<void> close();
}

/// Varint length-prefix framing shared by the real socket transport and
/// tests: encodes/decodes the same way as `google.protobuf`'s own
/// varint-delimited stream helpers.
class VarintFramer {
  const VarintFramer._();

  static Uint8List encodeLength(int length) {
    final bytes = <int>[];
    var value = length;
    while (true) {
      final byte = value & 0x7F;
      value >>= 7;
      if (value == 0) {
        bytes.add(byte);
        break;
      }
      bytes.add(byte | 0x80);
    }
    return Uint8List.fromList(bytes);
  }

  /// Attempts to decode a varint length prefix starting at the buffer's
  /// beginning. Returns null if the buffer doesn't yet contain a
  /// complete varint (caller should wait for more data).
  static (int length, int bytesRead)? decodeLength(Uint8List buffer) {
    var result = 0;
    var shift = 0;
    for (var i = 0; i < buffer.length; i++) {
      final byte = buffer[i];
      result |= (byte & 0x7F) << shift;
      if (byte & 0x80 == 0) {
        return (result, i + 1);
      }
      shift += 7;
      if (shift > 63) {
        throw const FormatException('Varint length prefix is too long.');
      }
    }
    return null;
  }
}

/// Splits a raw incoming byte stream into complete, length-delimited
/// protobuf messages, buffering partial reads exactly like the
/// reference implementation's `data_received` loop.
class MessageDefragmenter {
  final BytesBuilder _buffer = BytesBuilder(copy: true);

  /// Feeds newly received bytes in and returns every complete message
  /// that could be extracted from the buffer so far.
  List<Uint8List> add(Uint8List chunk) {
    _buffer.add(chunk);
    final messages = <Uint8List>[];
    var pending = _buffer.toBytes();

    while (true) {
      final decoded = VarintFramer.decodeLength(pending);
      if (decoded == null) break;
      final (length, headerBytes) = decoded;
      final end = headerBytes + length;
      if (pending.length < end) break;
      messages.add(Uint8List.sublistView(pending, headerBytes, end));
      pending = Uint8List.sublistView(pending, end);
    }

    _buffer.clear();
    _buffer.add(pending);
    return messages;
  }
}
