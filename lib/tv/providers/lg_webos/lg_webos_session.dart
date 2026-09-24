import 'dart:async';
import 'dart:convert';

import '../../../core/network/text_socket.dart';
import '../../domain/tv_domain.dart';

/// LG webOS "Second Screen" (SSAP) constants.
///
/// Sourced from `aiowebostv` (Apache-2.0), the library behind Home
/// Assistant's webOS integration: its registration manifest is unsigned
/// (no LG signature blob) and is what current webOS firmware accepts. See
/// `docs/research/lg-webos.md`.
abstract final class LgWebOsConstants {
  static const int wsPort = 3000;
  static const int wssPort = 3001;
  static const String ssdpSearchTarget =
      'urn:lge-com:service:webos-second-screen:1';

  static const Map<String, Object?> registrationPayload = {
    'forcePairing': false,
    'pairingType': 'PROMPT',
    'manifest': {
      'appVersion': '1.1',
      'manifestVersion': 1,
      'permissions': [
        'APP_TO_APP',
        'CLOSE',
        'CONTROL_AUDIO',
        'CONTROL_DISPLAY',
        'CONTROL_INPUT_JOYSTICK',
        'CONTROL_INPUT_MEDIA_PLAYBACK',
        'CONTROL_INPUT_MEDIA_RECORDING',
        'CONTROL_INPUT_TEXT',
        'CONTROL_INPUT_TV',
        'CONTROL_MOUSE_AND_KEYBOARD',
        'CONTROL_POWER',
        'CONTROL_TV_SCREEN',
        'LAUNCH',
        'LAUNCH_WEBAPP',
        'READ_APP_STATUS',
        'READ_COUNTRY_INFO',
        'READ_CURRENT_CHANNEL',
        'READ_INPUT_DEVICE_LIST',
        'READ_INSTALLED_APPS',
        'READ_LGE_SDX',
        'READ_LGE_TV_INPUT_EVENTS',
        'READ_NETWORK_STATE',
        'READ_NOTIFICATIONS',
        'READ_POWER_STATE',
        'READ_RUNNING_APPS',
        'READ_SETTINGS',
        'READ_TV_CHANNEL_LIST',
        'READ_TV_CURRENT_TIME',
        'READ_UPDATE_INFO',
        'SEARCH',
        'TEST_OPEN',
        'TEST_PROTECTED',
        'TEST_SECURE',
        'UPDATE_FROM_REMOTE_APP',
        'WRITE_NOTIFICATION_ALERT',
        'WRITE_NOTIFICATION_TOAST',
        'WRITE_SETTINGS',
      ],
    },
  };

  static const String getPointerInputSocket =
      'ssap://com.webos.service.networkinput/getPointerInputSocket';
  static const String listLaunchPoints =
      'ssap://com.webos.applicationManager/listLaunchPoints';
  static const String launch = 'ssap://system.launcher/launch';
  static const String insertText = 'ssap://com.webos.service.ime/insertText';
  static const String sendEnterKey =
      'ssap://com.webos.service.ime/sendEnterKey';
  static const String turnOff = 'ssap://system/turnOff';
}

/// One SSAP connection: `hello`, `register` (client-key or on-TV prompt),
/// and id-correlated requests with timeouts.
class LgWebOsSession {
  LgWebOsSession(
    this._socket, {
    this.requestTimeout = const Duration(seconds: 8),
    this.pairingTimeout = const Duration(seconds: 60),
  });

  final TextSocket _socket;
  final Duration requestTimeout;
  final Duration pairingTimeout;

  final _pending = <String, Completer<Map<String, Object?>>>{};
  StreamSubscription<String>? _sub;
  var _nextId = 1;
  var _closed = false;

  Completer<String>? _registration;
  void Function()? _onPrompt;

  Future<void> get done => _socket.done;

  void open() {
    _sub = _socket.messages.listen(_onMessage);
    unawaited(_socket.done.then((_) => _shutdown()));
  }

  void _onMessage(String raw) {
    final Map<String, Object?> message;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return;
      message = decoded;
    } catch (_) {
      return;
    }
    final id = message['id']?.toString();
    final type = message['type'];
    final payload =
        (message['payload'] as Map?)?.cast<String, Object?>() ?? const {};

    if (id == 'register_0') {
      final registration = _registration;
      if (registration == null || registration.isCompleted) return;
      if (type == 'registered' && payload['client-key'] is String) {
        registration.complete(payload['client-key'] as String);
      } else if (type == 'response' && payload['pairingType'] == 'PROMPT') {
        _onPrompt?.call();
      } else if (type == 'error') {
        registration.completeError(
          PairingRejectedException(
            'The TV declined the connection (${message['error'] ?? 'rejected'}).',
          ),
        );
      }
      return;
    }

    final completer = id == null ? null : _pending[id];
    if (completer == null || completer.isCompleted) return;
    if (type == 'error') {
      completer.completeError(
        ProtocolErrorException(
          'The TV rejected the request (${message['error']}).',
        ),
      );
    } else {
      completer.complete(payload);
    }
  }

  void _send(Map<String, Object?> message) {
    if (!_closed) _socket.send(jsonEncode(message));
  }

  Future<Map<String, Object?>> hello() =>
      _request({'type': 'hello', 'payload': const <String, Object?>{}});

  /// Registers with [clientKey] if known (accepted silently) or triggers
  /// the on-TV "allow this device?" prompt ([onPrompt] fires when the TV
  /// shows it). Completes with the client key to persist.
  Future<String> register({String? clientKey, void Function()? onPrompt}) {
    final registration = Completer<String>();
    _registration = registration;
    _onPrompt = onPrompt;
    _send({
      'type': 'register',
      'id': 'register_0',
      'payload': {
        ...LgWebOsConstants.registrationPayload,
        'client-key': ?clientKey,
      },
    });
    return registration.future.timeout(
      pairingTimeout,
      onTimeout: () => throw const PairingTimeoutException(
        'The TV did not confirm the connection in time.',
      ),
    );
  }

  Future<Map<String, Object?>> request(
    String uri, [
    Map<String, Object?> payload = const {},
  ]) => _request({'type': 'request', 'uri': uri, 'payload': payload});

  /// Sends without waiting for an answer - `system/turnOff` often never
  /// answers because the TV is already shutting down.
  void fireAndForget(String uri) =>
      _send({'id': '${_nextId++}', 'type': 'request', 'uri': uri});

  Future<Map<String, Object?>> _request(Map<String, Object?> message) {
    if (_closed) {
      return Future.error(
        const ConnectionLostException('The TV connection is closed.'),
      );
    }
    final id = '${_nextId++}';
    final completer = Completer<Map<String, Object?>>();
    _pending[id] = completer;
    _send({...message, 'id': id});
    return completer.future
        .timeout(
          requestTimeout,
          onTimeout: () => throw DeviceNotReachableException(
            'The TV did not answer ${message['uri'] ?? message['type']}.',
          ),
        )
        .whenComplete(() => _pending.remove(id));
  }

  Future<void> close() async {
    _shutdown();
    await _socket.close();
  }

  void _shutdown() {
    if (_closed) return;
    _closed = true;
    unawaited(_sub?.cancel());
    const lost = ConnectionLostException('The TV connection closed.');
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.completeError(lost);
    }
    _pending.clear();
    final registration = _registration;
    if (registration != null && !registration.isCompleted) {
      registration.completeError(lost);
    }
  }
}
