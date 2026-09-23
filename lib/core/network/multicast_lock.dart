import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

/// Keeps inbound multicast (mDNS, SSDP) flowing for the duration of a
/// discovery scan. Every [acquire] must be paired with one [release].
abstract interface class MulticastLock {
  Future<void> acquire();
  Future<void> release();
}

/// Android's Wi-Fi stack filters inbound multicast unless the app holds a
/// `WifiManager.MulticastLock` (see `MainActivity.kt`). Other platforms
/// have no equivalent, so this is a no-op there. Failing to take the lock
/// is logged, never thrown - a scan without it may still see some answers.
class PlatformMulticastLock implements MulticastLock {
  PlatformMulticastLock({
    this._channel = const MethodChannel(channelName),
    bool? isAndroid,
  }) : _isAndroid = isAndroid ?? Platform.isAndroid,
       _logger = AppLogger('Network.MulticastLock');

  static const channelName = 'remote_tv_2026/multicast_lock';

  final MethodChannel _channel;
  final bool _isAndroid;
  final AppLogger _logger;

  @override
  Future<void> acquire() => _invoke('acquire');

  @override
  Future<void> release() => _invoke('release');

  Future<void> _invoke(String method) async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<bool>(method);
    } catch (error) {
      _logger.warning(
        '[NETWORK][MULTICAST_LOCK] ${method}_failed type=${error.runtimeType}',
      );
    }
  }
}
