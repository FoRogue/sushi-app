import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRole = 'user_role';
  static const _kUserId = 'user_id';

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    final userId = _extractUserId(accessToken);
    await Future.wait([
      _storage.write(key: _kAccess, value: accessToken),
      _storage.write(key: _kRefresh, value: refreshToken),
      _storage.write(key: _kRole, value: role),
      _storage.write(key: _kUserId, value: userId),
    ]);
  }

  static String _extractUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return '';
      final normalized = base64Url.normalize(parts[1]);
      final decoded =
          jsonDecode(utf8.decode(base64Decode(normalized))) as Map<String, dynamic>;
      return decoded['user_id']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  static Future<String?> getAccessToken() => _storage.read(key: _kAccess);
  static Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);
  static Future<String?> getRole() => _storage.read(key: _kRole);
  static Future<String?> getUserId() => _storage.read(key: _kUserId);

  static Future<void> clear() => _storage.deleteAll();
}
