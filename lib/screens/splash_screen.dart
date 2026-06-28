import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && !_navigated) {
          _navigated = true;
          context.go('/onboarding');
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.3, -0.5),
            radius: 1.5,
            colors: [Color(0xFF10B981), Color(0xFF006C49), Color(0xFF131B2E)],
          ),
        ),
        child: Stack(
          children: [
            // Grid overlay
            Opacity(
              opacity: 0.1,
              child: Row(
                children: List.generate(
                  6,
                  (i) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo card
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(0, sin(_controller.value * pi) * 8),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: AppImage(
                            url: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAtElRu6NdbfyEWJEfaIm0QTbTu8E3KwqrWqje57jHcnhoQSjTf67RATFYkOnRCNlvO1_8-RnKtNiwyhlRQdYWDjOTd9EbnB7pDjJqH-UBYdBj61KtLEw38ZbG75bow5Sa5p2GCVKaRwp7R7Gs2Ugi7kFhqwwWyopeAxf-P6tLcGhLvFByJO2wF8PKqtwZgDkBawWENUcby0JtmxdGbeo721Zm6r2EUehrQDcoh69WGiYkXSdxEQrIWzr9awyBov4QfocUaRYiMoZA',
                            height: 80,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // Title
                  Text(
                    'Fast. Reliable. Delivered.',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bouncy dots
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (i) {
                          final offset = (_controller.value + i * 0.15) % 1.0;
                          final scale = 0.8 + (offset * 0.4);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6FFBBE),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom badge
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified,
                          size: 16, color: Color(0xFF6FFBBE)),
                      const SizedBox(width: 8),
                      Text(
                        'Secure Logistics Platform',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
