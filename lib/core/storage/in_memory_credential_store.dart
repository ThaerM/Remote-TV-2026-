import 'secure_credential_store.dart';

/// In-memory [SecureCredentialStore] for tests and the Linux/web dev hosts
/// where platform secure storage isn't available. Never used in release
/// builds on iOS/Android - those use [FlutterSecureCredentialStore].
class InMemoryCredentialStore implements SecureCredentialStore {
  final Map<String, String> _values = {};

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _values[key];

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _values.clear();
  }
}
