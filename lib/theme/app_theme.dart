import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color neonOrange = Color(0xFFFF6B00);
  static const Color neonGreen = Color(0xFF00FF9D);
  static const Color neonBlue = Color(0xFF00B4FF);
  static const Color textColor = Colors.white;
  static const Color secondaryTextColor = Colors.grey;

  // Theme Data
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: ColorScheme.dark(
      primary: neonOrange,
      secondary: neonGreen,
      tertiary: neonBlue,
      background: backgroundColor,
      surface: surfaceColor,
      error: Colors.red,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceColor,
      elevation: 0,
      iconTheme: IconThemeData(color: neonOrange),
      titleTextStyle: TextStyle(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: neonOrange,
      unselectedItemColor: secondaryTextColor,
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardTheme(
      color: surfaceColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonOrange,
        foregroundColor: backgroundColor,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: neonBlue,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: neonOrange),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: secondaryTextColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: neonOrange),
      ),
      labelStyle: TextStyle(color: secondaryTextColor),
      hintStyle: TextStyle(color: secondaryTextColor),
    ),
    listTileTheme: ListTileThemeData(
      textColor: textColor,
      iconColor: neonOrange,
      selectedColor: neonOrange.withOpacity(0.1),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceColor,
      contentTextStyle: TextStyle(color: textColor),
      actionTextColor: neonOrange,
    ),
  );
}
