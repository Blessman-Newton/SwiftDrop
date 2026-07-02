import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// lucide_icons removed - using Material Icons
import 'package:google_fonts/google_fonts.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/app_image.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      title: 'Delicious Food, Delivered Fast',
      description:
          'Get your favorite meals from the best restaurants delivered right to your doorstep.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuArYGeIR602FRVkNfqgHUKhJS2klHNVEOgaCSR7C0axKxo_lVDwSeZQlM_66mDAciRAba_Sw8LYWqM1lpblCTRFZBwGNv7fkMwXoeLd0ar7FUI05W1ZTrSt6fvNjbZRNqYgp6mKp_YfXTMelhYsOoe6cMS9jQR7nMpnbu2bxD3tSguPQTEanWeoekh_UMdQUW5x-hy7HM3uO_i4L0qvw6Y0aOMjWbPoxkPdom7IGE8zrCpuzuBHy4Q_5QON4r7bzV4ffFmO_E_CVm0',
    ),
    _SlideData(
      title: 'Send Anything, Anywhere',
      description:
          'Reliable parcel delivery service for all your personal and business needs.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBWrkxrI6SVOquFzzjFChwA_b3kiHQrpSNfXJgbF2YCEFmho5tw4MUQXrAEDH-RZ6OcJhUT1L5ctTq500ZFyxqhtGULhqZ0l6nmYTT_FjDnGHPRgEeaCwPS3qdrmUYEkr9XOW0Qvn7BvYX0djVvgFZ-mJyODhi1oG5pdrhaWUIM_5BX2VbQ0sL6lH5gIjDEsS7NMNFKV1W63W0qX6ehITVsf8_Uic41fMoSo6_SYptlYsmQdQYySbaVpumfF2INuLuk0TJZQyrPFsk',
    ),
    _SlideData(
      title: 'Real-time Tracking',
      description:
          'Keep an eye on your delivery with our high-tech live tracking system.',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuACxd54f45Pb3_pBggR9h_f7bSxyLfZmBGc40gfRLsm_8-NTN0NKbOL29IDAm7H7XqUZWMSp7NPvy8Td1a5TZIWF_Rb5BFs2w5yQpvnGrzZ7xk8aoE1gMfSUpY3QmXcXVT5djdO92UFZfi9vg-ZgQM7W17Bidp-dtegbgNaEGu9q0jQVj07hjTbX-LH8vEy4tor8Hq4dX0pS2cYOVNF2WzRjJGG6XqoC7cmWQDcegeQHMCHTqRkN6QJc1njbLXWG74JMkJsKD9tA5s',
      hasChips: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ref.read(onboardingDoneProvider.notifier).complete();
      context.go('/role-selection');
    }
  }

  void _skip() {
    ref.read(onboardingDoneProvider.notifier).complete();
    context.go('/role-selection');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            color: isDark ? const Color(0xFF131B2E) : const Color(0xFFF4FBF4),
          ),

          // Top-right green blob
          Positioned(
            top: -80,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: 256,
                height: 256,
                decoration: const BoxDecoration(
                  color: Color(0x1A6FFBBE),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Bottom-left orange blob
          Positioned(
            bottom: -60,
            left: -60,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: 192,
                height: 192,
                decoration: const BoxDecoration(
                  color: Color(0x33FFDBCA),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SWIFTDROP',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFF6FFBBE)
                              : const Color(0xFF006C49),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: 3,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _buildSlide(i, isDark),
                  ),
                ),

                // Bottom panel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  decoration: BoxDecoration(
                    color:
                        isDark ? const Color(0xFF18233C) : Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Pagination dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? (isDark
                                      ? const Color(0xFF6FFBBE)
                                      : const Color(0xFF006C49))
                                  : (isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Button
                      GestureDetector(
                        onTap: _next,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF10B981),
                                Color(0xFF006C49),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _currentPage == 2 ? 'Get Started' : 'Next',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(int index, bool isDark) {
    final slide = _slides[index];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Image with float animation
          Expanded(
            flex: 3,
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final offset = sin(_floatController.value * pi) * 10;
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(
                      url: slide.imageUrl,
                      fit: BoxFit.cover,
                    ),

                    // Chips for slide 3
                    if (slide.hasChips) ...[
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _buildChip(
                          icon: Icons.explore,
                          label: 'Live Sync',
                          isDark: isDark,
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: _buildChip(
                          icon: Icons.local_shipping,
                          label: 'Driver 4 mins away',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isDark ? const Color(0xFF6FFBBE) : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String title;
  final String description;
  final String imageUrl;
  final bool hasChips;

  const _SlideData({
    required this.title,
    required this.description,
    required this.imageUrl,
    this.hasChips = false,
  });
}
