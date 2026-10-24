import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'app_colors.dart';

// Design system "Global Explorer" (Stitch DESIGN.md):
// Oceanic Teal, Admiralty Navy, Sunlit Amber, Warm Cream.
const kNavy = Color(0xFF0F2537);
const kPrimary = Color(0xFF1E8289); // teal
const kSecondary = Color(0xFF4C6075); // biru-abu untuk ikon/teks sekunder
const kTertiary = Color(0xFFF4A261); // amber
const kAmberDark = Color(0xFF8C4D12); // teks eyebrow
const kOnAmber = Color(0xFF2F1400);
const kNeutral = kNavy; // warna teks utama
const kBg = Color(0xFFFAF8F5); // krem hangat
const kTealTint = Color(0xFFDCEFF0);
const kBlueTint = Color(0xFFE3ECF4);
const kAmberTint = Color(0xFFFDEBD9);
const kDanger = Color(0xFFBA1A1A);
const kDangerTint = Color(0xFFFFDAD6);

const kCardRadius = 28.0;
const kSoftShadow = BoxShadow(
  color: Color(0x0F0F2537),
  blurRadius: 24,
  spreadRadius: -4,
  offset: Offset(0, 8),
);

/// Gaya judul (Bricolage Grotesque). Jika font tidak tersedia di versi
/// google_fonts yang terpasang, otomatis memakai font bawaan.
TextStyle headlineStyle(double size,
    {FontWeight weight = FontWeight.w800, Color color = kNeutral, double? height}) {
  final base = TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: -0.02 * size,
  );
  try {
    return GoogleFonts.getFont('Bricolage Grotesque', textStyle: base);
  } catch (_) {
    return base;
  }
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: kPrimary).copyWith(
    primary: kPrimary,
    onPrimary: Colors.white,
    secondary: kSecondary,
    tertiary: kTertiary,
    surface: kBg,
    onSurface: kNeutral,
    error: kDanger,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);

  TextTheme text;
  try {
    text = GoogleFonts.getTextTheme('Be Vietnam Pro', base.textTheme);
  } catch (_) {
    text = base.textTheme;
  }
  text = text.apply(bodyColor: kNeutral, displayColor: kNeutral);

  TextStyle? head(TextStyle? s, FontWeight w) {
    if (s == null) return null;
    final styled = s.copyWith(fontWeight: w);
    try {
      return GoogleFonts.getFont('Bricolage Grotesque', textStyle: styled);
    } catch (_) {
      return styled;
    }
  }

  text = text.copyWith(
    displaySmall: head(text.displaySmall, FontWeight.w800),
    headlineLarge: head(text.headlineLarge, FontWeight.w700),
    headlineMedium: head(text.headlineMedium, FontWeight.w700),
    headlineSmall: head(text.headlineSmall, FontWeight.w700),
    titleLarge: head(text.titleLarge, FontWeight.w700),
  );

  const stadium = StadiumBorder();
  const buttonPadding = EdgeInsets.symmetric(horizontal: 28, vertical: 14);

  OutlineInputBorder inputBorder(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: c, width: 1.5),
      );

  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: kBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: kNeutral,
      centerTitle: false,
      titleTextStyle: headlineStyle(20, weight: FontWeight.w700),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: const Color(0xF2FFFFFF),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      indicatorColor: kTealTint,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? kPrimary : kSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? kPrimary : kSecondary,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: inputBorder(const Color(0x1A0F2537)),
      enabledBorder: inputBorder(const Color(0x1A0F2537)),
      focusedBorder: inputBorder(kPrimary),
      errorBorder: inputBorder(kDanger),
      focusedErrorBorder: inputBorder(kDanger),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        shape: stadium,
        padding: buttonPadding,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimary,
        side: const BorderSide(color: kPrimary, width: 1.5),
        shape: stadium,
        padding: buttonPadding,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimary,
        shape: stadium,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimary,
      foregroundColor: Colors.white,
      shape: stadium,
    ),
    chipTheme: const ChipThemeData(
      shape: stadium,
      side: BorderSide.none,
      backgroundColor: Colors.white,
      selectedColor: kTealTint,
      checkmarkColor: kPrimary,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kPrimary : null,
      ),
      side: const BorderSide(color: kSecondary, width: 1.5),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kNavy,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kPrimary),
  );
}
