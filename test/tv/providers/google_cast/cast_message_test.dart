import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/providers/google_cast/cast_message.dart';

void main() {
  const message = CastMessage(
    sourceId: 'sender-0',
    destinationId: 'receiver-0',
    namespace: CastConstants.nsReceiver,
    payload: '{"type":"GET_STATUS","requestId":1,"name":"Télé 📺"}',
  );

  test('encode/decode round-trips, including non-ASCII payloads', () {
    final decoded = CastMessage.decode(message.encode())!;

    expect(decoded.sourceId, 'sender-0');
    expect(decoded.destinationId, 'receiver-0');
    expect(decoded.namespace, CastConstants.nsReceiver);
    expect(decoded.json['name'], 'Télé 📺');
  });

  test('encoding matches the protobuf wire format', () {
    final bytes = const CastMessage(
      sourceId: 'a',
      destinationId: 'b',
      namespace: 'c',
      payload: 'd',
    ).encode();

    expect(bytes, [
      0x08, 0x00, // 1: protocol_version = CASTV2_1_0
      0x12, 0x01, 0x61, // 2: source_id = "a"
      0x1a, 0x01, 0x62, // 3: destination_id = "b"
      0x22, 0x01, 0x63, // 4: namespace = "c"
      0x28, 0x00, // 5: payload_type = STRING
      0x32, 0x01, 0x64, // 6: payload_utf8 = "d"
    ]);
  });

  test('binary-payload and truncated messages are rejected', () {
    final binary = Uint8List.fromList([
      0x08, 0x00, 0x12, 0x01, 0x61, 0x1a, 0x01, 0x62, //
      0x22, 0x01, 0x63, 0x28, 0x01, // payload_type = BINARY
    ]);
    expect(CastMessage.decode(binary), isNull);

    final truncated = message.encode().sublist(0, 10);
    expect(CastMessage.decode(truncated), isNull);
  });

  test('frame reader reassembles split and merged frames', () {
    final reader = CastFrameReader();
    final frame = message.frame();
    final two = [...frame, ...frame];

    expect(reader.add(two.sublist(0, 3)), isEmpty);
    final first = reader.add(two.sublist(3, frame.length + 5));
    final second = reader.add(two.sublist(frame.length + 5));

    expect(first, hasLength(1));
    expect(second, hasLength(1));
    expect(CastMessage.decode(second.single)!.json['type'], 'GET_STATUS');
  });

  test('an oversized frame is a protocol error, not a buffer', () {
    expect(
      () => CastFrameReader().add([0x00, 0x10, 0x00, 0x01]),
      throwsFormatException,
    );
  });
}
