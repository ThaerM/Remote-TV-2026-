import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/transport/android_tv_message_transport.dart';

void main() {
  group('VarintFramer', () {
    test('encodes small lengths as a single byte', () {
      expect(VarintFramer.encodeLength(0), [0]);
      expect(VarintFramer.encodeLength(127), [127]);
    });

    test('encodes lengths >= 128 as multiple bytes', () {
      expect(VarintFramer.encodeLength(300), [0xAC, 0x02]);
    });

    test('decodeLength round-trips through encodeLength', () {
      for (final length in [0, 1, 127, 128, 300, 16384, 2097151]) {
        final encoded = VarintFramer.encodeLength(length);
        final decoded = VarintFramer.decodeLength(encoded);
        expect(decoded, isNotNull);
        expect(decoded!.$1, length);
        expect(decoded.$2, encoded.length);
      }
    });

    test('decodeLength returns null for an incomplete varint', () {
      final incomplete = Uint8List.fromList([
        0xAC,
      ]); // continuation bit set, no next byte
      expect(VarintFramer.decodeLength(incomplete), isNull);
    });
  });

  group('MessageDefragmenter', () {
    test('extracts a single message delivered in one chunk', () {
      final defrag = MessageDefragmenter();
      final payload = Uint8List.fromList([1, 2, 3]);
      final framed = Uint8List.fromList([
        ...VarintFramer.encodeLength(3),
        ...payload,
      ]);

      final messages = defrag.add(framed);

      expect(messages, hasLength(1));
      expect(messages.first, payload);
    });

    test('buffers a message split across multiple chunks', () {
      final defrag = MessageDefragmenter();
      final payload = Uint8List.fromList([9, 8, 7, 6, 5]);
      final framed = Uint8List.fromList([
        ...VarintFramer.encodeLength(5),
        ...payload,
      ]);

      expect(defrag.add(Uint8List.sublistView(framed, 0, 2)), isEmpty);
      expect(defrag.add(Uint8List.sublistView(framed, 2, 4)), isEmpty);
      final messages = defrag.add(Uint8List.sublistView(framed, 4));

      expect(messages, hasLength(1));
      expect(messages.first, payload);
    });

    test('extracts multiple messages delivered in one chunk', () {
      final defrag = MessageDefragmenter();
      final first = Uint8List.fromList([1]);
      final second = Uint8List.fromList([2, 2]);
      final combined = Uint8List.fromList([
        ...VarintFramer.encodeLength(1),
        ...first,
        ...VarintFramer.encodeLength(2),
        ...second,
      ]);

      final messages = defrag.add(combined);

      expect(messages, hasLength(2));
      expect(messages[0], first);
      expect(messages[1], second);
    });
  });
}
