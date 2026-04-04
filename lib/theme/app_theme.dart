import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF0065FC);
  static const Color secondaryColor = Color(0xFF30C6F6);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);

  // Other Colors
  static const Color cardBackground = Colors.white;
  static const Color notificationColor = Color(0xFFFF3B30);
  static const Color starColor = Color(0xFFFFC107);
  static const Color priceColor = Color(0xFF0065FC);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, secondaryColor],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Text Styles
  static TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Lufga',
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Lufga',
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Lufga',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Lufga',
      fontSize: 16,
      color: textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Lufga',
      fontSize: 14,
      color: textSecondary,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Lufga',
      fontSize: 12,
      color: textLight,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Lufga',
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );

  // Theme Data
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: backgroundColor,
    ),
    textTheme: textTheme,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge,
    ),
  );
}
