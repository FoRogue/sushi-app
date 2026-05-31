import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

enum UserRole { customer, courier, shop }

UserRole? _parseRole(String? raw) => switch (raw) {
      'customer' => UserRole.customer,
      'courier' => UserRole.courier,
      'shop' => UserRole.shop,
      _ => null,
    };

bool _isTokenExpired(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return true;
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    final exp = (jsonDecode(decoded) as Map<String, dynamic>)['exp'] as int?;
    if (exp == null) return false;
    return DateTime.now().isAfter(
      DateTime.fromMillisecondsSinceEpoch(exp * 1000),
    );
  } catch (_) {
    return true;
  }
}

class AuthNotifier extends AsyncNotifier<UserRole?> {
  @override
  Future<UserRole?> build() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return null;
    if (_isTokenExpired(token)) {
      await TokenStorage.clear();
      return null;
    }
    final role = await TokenStorage.getRole();
    return _parseRole(role);
  }

  Future<void> onLogin(String role) async {
    state = AsyncData(_parseRole(role));
  }

  Future<void> logout() async {
    await TokenStorage.clear();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, UserRole?>(() => AuthNotifier());

final userIdProvider = FutureProvider<int?>((ref) async {
  ref.watch(authProvider);
  final raw = await TokenStorage.getUserId();
  if (raw == null || raw.isEmpty) return null;
  return int.tryParse(raw);
});
