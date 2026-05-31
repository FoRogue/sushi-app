import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SushiApp()));
}

class SushiApp extends ConsumerWidget {
  const SushiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Суши Дом',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFD9381E),
          onPrimary: Colors.white,
          surface: Color(0xFFF9F6F0),
          onSurface: Color(0xFF222222),
        ),
        useMaterial3: true,
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFFD9381E).withOpacity(0.12),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFD9381E));
            }
            return const IconThemeData(color: Color(0xFF888888));
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFFD9381E),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              );
            }
            return const TextStyle(color: Color(0xFF888888), fontSize: 12);
          }),
        ),
        navigationRailTheme: NavigationRailThemeData(
          indicatorColor: const Color(0xFFD9381E).withOpacity(0.12),
          selectedIconTheme:
              const IconThemeData(color: Color(0xFFD9381E)),
          unselectedIconTheme:
              const IconThemeData(color: Color(0xFF888888)),
          selectedLabelTextStyle: const TextStyle(
            color: Color(0xFFD9381E),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelTextStyle: const TextStyle(
            color: Color(0xFF888888),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
