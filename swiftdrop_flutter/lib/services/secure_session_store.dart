import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the API access token in platform secure storage
/// (Android Keystore / iOS Keychain) instead of plain preferences.
///
/// Every operation is failure-tolerant: if the keystore is unavailable
/// (device locked at boot, corrupted key, unsupported platform) the store
/// marks itself unusable and returns no data rather than throwing during
/// app start-up.
class SecureSessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  /// Key the access token is stored under. Not a secret - it is only the
  /// storage slot name, the token itself is what must stay protected.
  static const String storageKey = 'swiftdrop_api_token_v1';

  final FlutterSecureStorage _storage;
  bool _usable = true;

  bool get isUsable => _usable;

  Future<String?> read() async {
    if (!_usable) return null;
    try {
      return await _storage.read(key: storageKey);
    } catch (_) {
      _usable = false;
      return null;
    }
  }

  Future<bool> write(String token) async {
    if (!_usable) return false;
    try {
      await _storage.write(key: storageKey, value: token);
      return true;
    } catch (_) {
      _usable = false;
      return false;
    }
  }

  Future<void> delete() async {
    if (!_usable) return;
    try {
      await _storage.delete(key: storageKey);
    } catch (_) {
      _usable = false;
    }
  }
}
