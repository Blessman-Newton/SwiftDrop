import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _navigated = false;

  late Animation<double> _ringAnimation;
  late Animation<double> _stemAnimation;
  late Animation<double> _dotAnimation;
  late Animation<double> _wordmarkAnimation;
  late Animation<double> _taglineAnimation;
  late Animation<double> _loaderAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _ringAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.06, 0.26, curve: Curves.easeInOut),
    );

    _stemAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 0.36, curve: Curves.easeInOut),
    );

    _dotAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.48, curve: Curves.elasticOut),
    );

    _wordmarkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.44, 0.60, curve: Curves.easeOut),
    );

    _taglineAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.52, 0.66, curve: Curves.easeOut),
    );

    _loaderAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.74, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _controller.forward();
        }
      });
      Future.microtask(() {
        if (mounted) {
          ref.read(currentUserProvider.notifier).refreshFromApi();
        }
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_navigated) {
        _navigated = true;
        context.go('/onboarding');
      }
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
      backgroundColor: const Color(0xFF123526),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(150, 150),
                      painter: SplashMarkPainter(
                        ringProgress: _ringAnimation.value,
                        stemProgress: _stemAnimation.value,
                        dotScale: _dotAnimation.value,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: _wordmarkAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _wordmarkAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 14 * (1 - _wordmarkAnimation.value)),
                        child: Text(
                          'doorush',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1.14,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                AnimatedBuilder(
                  animation: _taglineAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _taglineAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, 10 * (1 - _taglineAnimation.value)),
                        child: Text(
                          'Delivery. Pickup. Everything in between.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF8FCDAE),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _loaderAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _loaderAnimation.value,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          child: PulsingDot(delay: i * 150),
                        );
                      }),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SplashMarkPainter extends CustomPainter {
  final double ringProgress;
  final double stemProgress;
  final double dotScale;

  SplashMarkPainter({
    required this.ringProgress,
    required this.stemProgress,
    required this.dotScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    canvas.save();
    canvas.scale(scale);

    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final ringPath = Path();
    ringPath.addArc(
      Rect.fromCircle(center: const Offset(34, 63), radius: 19),
      -pi / 2,
      2 * pi * ringProgress,
    );
    canvas.drawPath(ringPath, ringPaint);

    final stemPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path();
    stemPath.moveTo(53, 63);
    stemPath.lineTo(53, 35);
    stemPath.quadraticBezierTo(53, 22, 63, 18.5);
    stemPath.quadraticBezierTo(70, 16, 76, 17);

    final stemLength = _getPathLength(stemPath);
    final metric = stemPath.computeMetrics().first;
    final extractedPath = metric.extractPath(0, stemLength * stemProgress);
    canvas.drawPath(extractedPath, stemPaint);

    final dotPaint = Paint()..color = const Color(0xFF29B573);
    final dotRadius = 5.5 * dotScale;
    canvas.drawCircle(const Offset(76, 17), dotRadius, dotPaint);

    canvas.restore();
  }

  double _getPathLength(Path path) {
    double length = 0;
    for (final metric in path.computeMetrics()) {
      length += metric.length;
    }
    return length;
  }

  @override
  bool shouldRepaint(covariant SplashMarkPainter oldDelegate) {
    return ringProgress != oldDelegate.ringProgress ||
        stemProgress != oldDelegate.stemProgress ||
        dotScale != oldDelegate.dotScale;
  }
}

class PulsingDot extends StatefulWidget {
  final int delay;

  const PulsingDot({super.key, required this.delay});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF3E6C55),
          end: const Color(0xFF29B573),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: const Color(0xFF29B573),
          end: const Color(0xFF3E6C55),
        ),
        weight: 50,
      ),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 1.0),
        weight: 50,
      ),
    ]).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
