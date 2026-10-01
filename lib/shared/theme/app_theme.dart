import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color cardBackground = Color(0xFF1E293B);
  static const Color successGreen = Color(0xFF00E676);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color dangerRed = Color(0xFFEF5350);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryGold,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryGold,
      secondary: primaryGold,
      surface: cardBackground,
      error: dangerRed,
    ),
    cardTheme: const CardThemeData(
      color: cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: primaryGold,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGold,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
