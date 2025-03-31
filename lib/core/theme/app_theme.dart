import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFFF4437);
  static const Color redGradientStart = Color(0xFFFF4437);
  static const Color redGradientEnd = Color(0xFF8A0303);

  static const Color cardDarkColor = Color(0xFF1E1E1E);
  static const Color backgroundDarkColor = Color(0xFF121212);
  static const Color textLightColor = Color(0xFFFFFFFF);
  static const Color textGreyColor = Color(0xFFA0A0A0);

  static const Color platinumColor = Color(0xFFE5E4E2);
  static const Color rubyColor = Color(0xFFE0115F);

  static const double cardBorderRadius = 24.0;
  static const double smallBorderRadius = 12.0;

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: backgroundDarkColor,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      secondary: redGradientEnd,
      surface: cardDarkColor,
    ),
    cardTheme: CardTheme(
      color: cardDarkColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardBorderRadius),
      ),
    ),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textLightColor,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(smallBorderRadius),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
  );

  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [redGradientStart, redGradientEnd],
  );
}
