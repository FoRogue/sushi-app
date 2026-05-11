import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/auth/presentation/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SushiApp());
}

class SushiApp extends StatelessWidget {
  const SushiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Суши Дом',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFD9381E),
          onPrimary: Colors.white,
          surface: Color(0xFFF9F6F0),
          onSurface: Color(0xFF222222),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
