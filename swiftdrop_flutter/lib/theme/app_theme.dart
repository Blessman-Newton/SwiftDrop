import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';

class AppColors {
  static const primary = Color(0xFF006C49);
  static const primaryLight = Color(0xFF10B981);
  static const accent = Color(0xFFFF7E2D);
  static const accentDark = Color(0xFF9D4300);

  static const lightBackground = Color(0xFFF4FBF4);
  static const lightSurface = Colors.white;
  static const lightCard = Colors.white;

  static const darkBackground = Color(0xFF131B2E);
  static const darkSurface = Color(0xFF1C2541);
  static const darkCard = Color(0xFF18233C);

  // Adaptive helpers — pass isDark from Theme.of(context).brightness.
  static Color background(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkCard : Colors.white;
  static Color textPrimary(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF111813);
  static Color textSecondary(bool isDark) =>
      isDark ? const Color(0xFF93A1B5) : const Color(0xFF6C7A71);
  static Color border(bool isDark) => isDark
      ? Colors.white.withOpacity(0.06)
      : Colors.black.withOpacity(0.05);

  /// Single source of truth for order-status color.
  static Color status(OrderStatus s) {
    switch (s) {
      case OrderStatus.created:
        return const Color(0xFFF59E0B); // amber
      case OrderStatus.confirmed:
      case OrderStatus.preparing:
        return const Color(0xFF0EA5E9); // sky
      case OrderStatus.readyForPickup:
        return const Color(0xFF8B5CF6); // violet
      case OrderStatus.pickedUp:
      case OrderStatus.enRoute:
        return primaryLight;
      case OrderStatus.delivered:
        return const Color(0xFF64748B); // slate
      case OrderStatus.cancelled:
        return const Color(0xFFEF4444); // red
    }
  }
}

/// Consistent spacing scale (multiples of 4).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

/// Shared Inter-based text styles so screens stop re-declaring them.
class AppText {
  static TextStyle heading(bool isDark) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle title(bool isDark) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle body(bool isDark) => GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textPrimary(isDark),
      );

  static TextStyle secondary(bool isDark) => GoogleFonts.inter(
        fontSize: 12,
        color: AppColors.textSecondary(isDark),
      );

  static TextStyle label(bool isDark) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: AppColors.textSecondary(isDark),
      );
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
