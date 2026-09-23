import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/secure_credential_store.dart';
import '../security/android_tv_identity.dart';

/// Non-sensitive metadata about a paired Android TV, safe for ordinary
/// (non-encrypted) local storage.
class PairedAndroidTvMetadata {
  const PairedAndroidTvMetadata({
    required this.deviceId,
    required this.name,
    required this.lastKnownHost,
    required this.lastConnectedAt,
  });

  final String deviceId;
  final String name;
  final String lastKnownHost;
  final DateTime lastConnectedAt;

  Map<String, Object?> toJson() => {
    'deviceId': deviceId,
    'name': name,
    'lastKnownHost': lastKnownHost,
    'lastConnectedAt': lastConnectedAt.toIso8601String(),
  };

  factory PairedAndroidTvMetadata.fromJson(Map<String, Object?> json) {
    return PairedAndroidTvMetadata(
      deviceId: json['deviceId']! as String,
      name: json['name']! as String,
      lastKnownHost: json['lastKnownHost']! as String,
      lastConnectedAt: DateTime.parse(json['lastConnectedAt']! as String),
    );
  }

  PairedAndroidTvMetadata copyWith({
    String? name,
    String? lastKnownHost,
    DateTime? lastConnectedAt,
  }) {
    return PairedAndroidTvMetadata(
      deviceId: deviceId,
      name: name ?? this.name,
      lastKnownHost: lastKnownHost ?? this.lastKnownHost,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }
}

/// Persists paired Android TV devices: non-sensitive metadata (device id,
/// name, last known host, last connected time) via `shared_preferences`,
/// and the per-device pairing identity (self-signed cert + private key)
/// via [SecureCredentialStore] - never in the same place, per
/// `docs/architecture/security.md`.
class AndroidTvPairedDeviceStore {
  AndroidTvPairedDeviceStore({
    required this._secureStore,
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _metadataKey = 'android_tv.paired_devices';
  static const _certKeyPrefix = 'android_tv.identity.cert.';
  static const _privateKeyPrefix = 'android_tv.identity.key.';

  final SecureCredentialStore _secureStore;
  final Future<SharedPreferences> _preferences;

  Future<List<PairedAndroidTvMetadata>> loadAll() async {
    final prefs = await _preferences;
    final raw = prefs.getStringList(_metadataKey) ?? const [];
    return raw
        .map(
          (entry) => PairedAndroidTvMetadata.fromJson(
            jsonDecode(entry) as Map<String, Object?>,
          ),
        )
        .toList();
  }

  Future<void> saveMetadata(PairedAndroidTvMetadata metadata) async {
    final prefs = await _preferences;
    final all = await loadAll();
    final withoutExisting = all
        .where((m) => m.deviceId != metadata.deviceId)
        .toList();
    withoutExisting.add(metadata);
    await prefs.setStringList(
      _metadataKey,
      withoutExisting.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  Future<void> saveIdentity(String deviceId, AndroidTvIdentity identity) async {
    await _secureStore.write(
      key: '$_certKeyPrefix$deviceId',
      value: identity.certificatePem,
    );
    await _secureStore.write(
      key: '$_privateKeyPrefix$deviceId',
      value: identity.privateKeyPem,
    );
  }

  Future<AndroidTvIdentity?> loadIdentity(String deviceId) async {
    final cert = await _secureStore.read(key: '$_certKeyPrefix$deviceId');
    final key = await _secureStore.read(key: '$_privateKeyPrefix$deviceId');
    if (cert == null || key == null) return null;
    return AndroidTvIdentity(certificatePem: cert, privateKeyPem: key);
  }

  /// Removes everything about [deviceId]: metadata, identity, and any
  /// cached session data. Used by "Forget device".
  Future<void> forget(String deviceId) async {
    final prefs = await _preferences;
    final all = await loadAll();
    final remaining = all.where((m) => m.deviceId != deviceId).toList();
    await prefs.setStringList(
      _metadataKey,
      remaining.map((m) => jsonEncode(m.toJson())).toList(),
    );
    await _secureStore.delete(key: '$_certKeyPrefix$deviceId');
    await _secureStore.delete(key: '$_privateKeyPrefix$deviceId');
  }
}
