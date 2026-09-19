import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';

void main() {
  group('InMemoryCredentialStore', () {
    test('write then read returns the stored value', () async {
      final store = InMemoryCredentialStore();

      await store.write(key: 'pairing-token', value: 'secret');

      expect(await store.read(key: 'pairing-token'), 'secret');
    });

    test('read returns null for a missing key', () async {
      final store = InMemoryCredentialStore();

      expect(await store.read(key: 'missing'), isNull);
    });

    test('delete removes a single key', () async {
      final store = InMemoryCredentialStore();
      await store.write(key: 'a', value: '1');
      await store.write(key: 'b', value: '2');

      await store.delete(key: 'a');

      expect(await store.read(key: 'a'), isNull);
      expect(await store.read(key: 'b'), '2');
    });

    test('deleteAll clears every key', () async {
      final store = InMemoryCredentialStore();
      await store.write(key: 'a', value: '1');
      await store.write(key: 'b', value: '2');

      await store.deleteAll();

      expect(await store.read(key: 'a'), isNull);
      expect(await store.read(key: 'b'), isNull);
    });
  });
}
