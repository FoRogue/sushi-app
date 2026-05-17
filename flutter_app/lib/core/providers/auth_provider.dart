import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/token_storage.dart';

enum UserRole { customer, courier, shop }

UserRole? _parseRole(String? raw) => switch (raw) {
      'customer' => UserRole.customer,
      'courier' => UserRole.courier,
      'shop' => UserRole.shop,
      _ => null,
    };

class AuthNotifier extends AsyncNotifier<UserRole?> {
  @override
  Future<UserRole?> build() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return null;
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
