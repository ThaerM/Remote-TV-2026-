/// Abstraction over encrypted, per-device pairing secrets (tokens, keys,
/// PINs already used once). Never persist these in plain-text storage
/// (SharedPreferences, plain files, logs) - see docs/architecture/security.md.
abstract interface class SecureCredentialStore {
  Future<void> write({required String key, required String value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
  Future<void> deleteAll();
}
