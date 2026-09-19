import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/storage/in_memory_credential_store.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/security/android_tv_identity.dart';
import 'package:remote_tv_2026/tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AndroidTvPairedDeviceStore buildStore() =>
      AndroidTvPairedDeviceStore(secureStore: InMemoryCredentialStore());

  group('AndroidTvPairedDeviceStore', () {
    test('loadAll is empty when nothing has been saved', () async {
      final store = buildStore();

      expect(await store.loadAll(), isEmpty);
    });

    test('saveMetadata then loadAll round-trips a device', () async {
      final store = buildStore();
      final metadata = PairedAndroidTvMetadata(
        deviceId: 'android_tv:1',
        name: 'Living Room TV',
        lastKnownHost: '192.168.1.42',
        lastConnectedAt: DateTime.utc(2026, 1, 1),
      );

      await store.saveMetadata(metadata);
      final all = await store.loadAll();

      expect(all, hasLength(1));
      expect(all.single.deviceId, 'android_tv:1');
      expect(all.single.name, 'Living Room TV');
    });

    test(
      'saveMetadata replaces an existing entry for the same device id',
      () async {
        final store = buildStore();
        await store.saveMetadata(
          PairedAndroidTvMetadata(
            deviceId: 'android_tv:1',
            name: 'Old Name',
            lastKnownHost: '192.168.1.1',
            lastConnectedAt: DateTime.utc(2026, 1, 1),
          ),
        );
        await store.saveMetadata(
          PairedAndroidTvMetadata(
            deviceId: 'android_tv:1',
            name: 'New Name',
            lastKnownHost: '192.168.1.2',
            lastConnectedAt: DateTime.utc(2026, 1, 2),
          ),
        );

        final all = await store.loadAll();

        expect(all, hasLength(1));
        expect(all.single.name, 'New Name');
      },
    );

    test(
      'saveIdentity then loadIdentity round-trips the cert/key pair',
      () async {
        final store = buildStore();
        final identity = AndroidTvIdentity.generate();

        await store.saveIdentity('android_tv:1', identity);
        final loaded = await store.loadIdentity('android_tv:1');

        expect(loaded?.certificatePem, identity.certificatePem);
        expect(loaded?.privateKeyPem, identity.privateKeyPem);
      },
    );

    test('loadIdentity returns null for an unpaired device', () async {
      final store = buildStore();

      expect(await store.loadIdentity('unknown'), isNull);
    });

    test('forget removes metadata and identity together', () async {
      final store = buildStore();
      final identity = AndroidTvIdentity.generate();
      await store.saveMetadata(
        PairedAndroidTvMetadata(
          deviceId: 'android_tv:1',
          name: 'Living Room TV',
          lastKnownHost: '192.168.1.42',
          lastConnectedAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await store.saveIdentity('android_tv:1', identity);

      await store.forget('android_tv:1');

      expect(await store.loadAll(), isEmpty);
      expect(await store.loadIdentity('android_tv:1'), isNull);
    });
  });
}
