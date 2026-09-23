import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../tv/providers/android_tv/storage/android_tv_paired_device_store.dart';
import '../../../tv/providers/tv_provider_registry_provider.dart';

/// Loads the list of previously-paired Android TV devices for the
/// Devices screen. Connection state for whichever one is currently
/// active still comes from [tvSessionControllerProvider] - this only
/// answers "what have I paired with before".
final pairedAndroidTvDevicesProvider =
    FutureProvider<List<PairedAndroidTvMetadata>>((ref) async {
      final store = ref.watch(androidTvPairedDeviceStoreProvider);
      return store.loadAll();
    });

/// Forgets a paired Android TV: disconnects if active, stops reconnect
/// attempts, and deletes both its metadata and its secure credentials.
class ForgetAndroidTvDevice {
  ForgetAndroidTvDevice(this._ref);

  final Ref _ref;

  Future<void> call(String deviceId) async {
    final provider = _ref.read(androidTvProviderProvider);
    await provider.forget(deviceId);
    _ref.invalidate(pairedAndroidTvDevicesProvider);
  }
}

final forgetAndroidTvDeviceProvider = Provider<ForgetAndroidTvDevice>((ref) {
  return ForgetAndroidTvDevice(ref);
});
