import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        return Stack(
          children: [
            Container(color: const Color(0xFFF9F6F0)),
            Positioned(
              top: -140 + t * 44,
              right: -100 + t * 32,
              child: _Orb(size: 430, color: const Color(0xFFD9381E), opacity: 0.36 + t * 0.08),
            ),
            Positioned(
              bottom: -130 + t * 28,
              left: -100 + t * 22,
              child: _Orb(size: 390, color: const Color(0xFF222222), opacity: 0.13 + t * 0.05),
            ),
            Positioned(
              top: size.height * 0.38 - t * 35,
              right: -70 + t * 12,
              child: _Orb(size: 260, color: const Color(0xFFFF6B50), opacity: 0.12 + t * 0.05),
            ),
            Positioned(
              bottom: size.height * 0.08 + t * 22,
              right: size.width * 0.08,
              child: _Orb(size: 170, color: const Color(0xFFD9381E), opacity: 0.10 + t * 0.04),
            ),
          ],
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color, required this.opacity});

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0)],
        ),
      ),
    );
  }
}
