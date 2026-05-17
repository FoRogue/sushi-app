import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kRole = 'user_role';

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) =>
      Future.wait([
        _storage.write(key: _kAccess, value: accessToken),
        _storage.write(key: _kRefresh, value: refreshToken),
        _storage.write(key: _kRole, value: role),
      ]);

  static Future<String?> getAccessToken() => _storage.read(key: _kAccess);
  static Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);
  static Future<String?> getRole() => _storage.read(key: _kRole);

  static Future<void> clear() => _storage.deleteAll();
}
