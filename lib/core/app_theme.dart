import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF00686E);
  static const teal = Color(0xFF1E8289);
  static const navy = Color(0xFF0F2537);
  static const amber = Color(0xFFF4A261);
  static const brown = Color(0xFF8C4D12);
  static const surface = Color(0xFFFBF9F6);
  static const secondary = Color(0xFF4C6075);
  static const muted = Color(0xFF6B7B8A);
  static const container = Color(0xFFEFEEEB);
  static const ink = Color(0xFF1B1C1A);
  static const error = Color(0xFFBA1A1A);
}

class AppText {
  // Font judul desain: Bricolage Grotesque
  static TextStyle headline(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.ink,
  }) => GoogleFonts.bricolageGrotesque(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static TextStyle label({
    double size = 12,
    Color color = AppColors.muted,
    FontWeight weight = FontWeight.w700,
  }) => GoogleFonts.beVietnamPro(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: 0.6,
  );
}

class AppTheme {
  static OutlineInputBorder _border(Color c, [double w = 1.5]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );

    return base.copyWith(
      textTheme: GoogleFonts.beVietnamProTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: _border(const Color(0x1A0F2537)),
        enabledBorder: _border(const Color(0x1A0F2537)),
        focusedBorder: _border(AppColors.teal, 2),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 2),
        labelStyle: const TextStyle(color: AppColors.muted),
        prefixIconColor: AppColors.muted,
        suffixIconColor: AppColors.muted,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 52),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.teal, width: 1.5),
          shape: const StadiumBorder(),
          minimumSize: const Size(0, 52),
          textStyle: GoogleFonts.beVietnamPro(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.primary
              : const Color(0xFFE4E2DF),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 72,
        indicatorColor: const Color(0x1F1E8289),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.secondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
