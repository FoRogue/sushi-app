import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage._();

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
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_kAccess, accessToken),
      prefs.setString(_kRefresh, refreshToken),
      prefs.setString(_kRole, role),
      prefs.setString(_kUserId, userId),
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

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kAccess);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRefresh);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kRole);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserId);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
