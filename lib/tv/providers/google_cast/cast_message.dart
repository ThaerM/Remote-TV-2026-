import 'dart:convert';
import 'dart:typed_data';

/// CASTV2 protocol constants (`cast_channel.proto`, as used by every
/// open-source sender - pychromecast, node-castv2, VLC).
abstract final class CastConstants {
  static const String serviceType = '_googlecast._tcp';
  static const int defaultPort = 8009;

  /// Google's Default Media Receiver: plays a URL with standard controls,
  /// no receiver app registration needed.
  static const String defaultMediaReceiverAppId = 'CC1AD845';

  static const String senderId = 'sender-0';
  static const String platformReceiverId = 'receiver-0';

  static const String nsConnection = 'urn:x-cast:com.google.cast.tp.connection';
  static const String nsHeartbeat = 'urn:x-cast:com.google.cast.tp.heartbeat';
  static const String nsReceiver = 'urn:x-cast:com.google.cast.receiver';
  static const String nsMedia = 'urn:x-cast:com.google.cast.media';
}

/// One CASTV2 `CastMessage` with a UTF-8 JSON payload (the only payload
/// type the namespaces used here carry).
class CastMessage {
  const CastMessage({
    required this.sourceId,
    required this.destinationId,
    required this.namespace,
    required this.payload,
  });

  final String sourceId;
  final String destinationId;
  final String namespace;
  final String payload;

  Map<String, Object?> get json {
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map<String, Object?> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  static CastMessage withJson({
    required String sourceId,
    required String destinationId,
    required String namespace,
    required Map<String, Object?> body,
  }) => CastMessage(
    sourceId: sourceId,
    destinationId: destinationId,
    namespace: namespace,
    payload: jsonEncode(body),
  );

  /// Protobuf encoding:
  /// 1 protocol_version (varint, CASTV2_1_0 = 0), 2 source_id, 3
  /// destination_id, 4 namespace, 5 payload_type (varint, STRING = 0),
  /// 6 payload_utf8.
  Uint8List encode() {
    final out = BytesBuilder();
    _writeVarintField(out, 1, 0);
    _writeStringField(out, 2, sourceId);
    _writeStringField(out, 3, destinationId);
    _writeStringField(out, 4, namespace);
    _writeVarintField(out, 5, 0);
    _writeStringField(out, 6, payload);
    return out.toBytes();
  }

  /// Returns null for binary-payload messages (not used by these
  /// namespaces) or malformed input.
  static CastMessage? decode(Uint8List bytes) {
    var offset = 0;
    String? source, destination, namespace, payload;
    var payloadType = 0;
    try {
      while (offset < bytes.length) {
        final (key, afterKey) = _readVarint(bytes, offset);
        offset = afterKey;
        final field = key >> 3;
        final wireType = key & 0x7;
        switch (wireType) {
          case 0:
            final (value, next) = _readVarint(bytes, offset);
            offset = next;
            if (field == 5) payloadType = value;
          case 2:
            final (length, next) = _readVarint(bytes, offset);
            final end = next + length;
            if (end > bytes.length) return null;
            final text = utf8.decode(
              bytes.sublist(next, end),
              allowMalformed: true,
            );
            offset = end;
            switch (field) {
              case 2:
                source = text;
              case 3:
                destination = text;
              case 4:
                namespace = text;
              case 6:
                payload = text;
            }
          case 5:
            offset += 4;
          case 1:
            offset += 8;
          default:
            return null;
        }
      }
    } on RangeError {
      return null;
    }
    if (payloadType != 0 ||
        source == null ||
        destination == null ||
        namespace == null) {
      return null;
    }
    return CastMessage(
      sourceId: source,
      destinationId: destination,
      namespace: namespace,
      payload: payload ?? '',
    );
  }

  /// Length-prefixed (4-byte big-endian) frame, as sent on the wire.
  Uint8List frame() {
    final body = encode();
    final header = ByteData(4)..setUint32(0, body.length);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...body]);
  }

  static void _writeVarintField(BytesBuilder out, int field, int value) {
    _writeVarint(out, (field << 3) | 0);
    _writeVarint(out, value);
  }

  static void _writeStringField(BytesBuilder out, int field, String value) {
    final bytes = utf8.encode(value);
    _writeVarint(out, (field << 3) | 2);
    _writeVarint(out, bytes.length);
    out.add(bytes);
  }

  static void _writeVarint(BytesBuilder out, int value) {
    var v = value;
    while (v >= 0x80) {
      out.addByte((v & 0x7f) | 0x80);
      v >>= 7;
    }
    out.addByte(v);
  }

  static (int, int) _readVarint(Uint8List bytes, int start) {
    var result = 0;
    var shift = 0;
    var offset = start;
    while (true) {
      final byte = bytes[offset++];
      result |= (byte & 0x7f) << shift;
      if (byte & 0x80 == 0) return (result, offset);
      shift += 7;
      if (shift > 35) throw RangeError('varint too long');
    }
  }
}

/// Reassembles length-prefixed frames from a TCP byte stream, which may
/// split or merge them arbitrarily.
class CastFrameReader {
  final _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  /// Frames larger than this are a protocol error, not something to
  /// buffer (the Cast spec caps messages at 64 KiB).
  static const maxFrameLength = 64 * 1024;

  List<Uint8List> add(List<int> chunk) {
    _buffer.add(chunk);
    _pending = Uint8List.fromList([..._pending, ..._buffer.takeBytes()]);
    final frames = <Uint8List>[];
    while (_pending.length >= 4) {
      final length = ByteData.sublistView(_pending, 0, 4).getUint32(0);
      if (length > maxFrameLength) {
        throw const FormatException('Cast frame exceeds 64 KiB');
      }
      if (_pending.length < 4 + length) break;
      frames.add(Uint8List.sublistView(_pending, 4, 4 + length));
      _pending = Uint8List.sublistView(_pending, 4 + length);
    }
    return frames;
  }
}
