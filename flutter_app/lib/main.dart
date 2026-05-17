import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
      ),
    );
  }
}
