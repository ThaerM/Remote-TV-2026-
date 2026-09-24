import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/core/network/multicast_lock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PlatformMulticastLock.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;

  setUp(() {
    calls = [];
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  });

  group('PlatformMulticastLock', () {
    test('on Android, acquire/release call the native lock', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return true;
      });
      final lock = PlatformMulticastLock(isAndroid: true);

      await lock.acquire();
      await lock.release();

      expect(calls, ['acquire', 'release']);
    });

    test('elsewhere it never touches the channel', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return true;
      });
      final lock = PlatformMulticastLock(isAndroid: false);

      await lock.acquire();
      await lock.release();

      expect(calls, isEmpty);
    });

    test('a native failure is swallowed, not thrown into a scan', () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(code: 'multicast_lock_failed'),
      );
      final lock = PlatformMulticastLock(isAndroid: true);

      await expectLater(lock.acquire(), completes);
      await expectLater(lock.release(), completes);
    });
  });
}
