import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color.fromARGB(255, 32, 0, 214);

  // Primary color variations
  static const Color primaryLightColor = Color.fromARGB(255, 82, 56, 255);
  static const Color primaryDarkColor = Color.fromARGB(255, 23, 0, 156);
  static Color primaryWithOpacity = primaryColor.withOpacity(0.1);

  // Secondary colors
  static const Color secondaryColor = Color.fromARGB(255, 255, 64, 129);
  static const Color secondaryLightColor = Color.fromARGB(255, 255, 102, 153);
  static const Color secondaryDarkColor = Color.fromARGB(255, 200, 25, 92);

  // Text colors
  static const Color textPrimaryDark = Color.fromARGB(255, 33, 33, 33);
  static const Color textSecondaryDark = Color.fromARGB(255, 117, 117, 117);
  static const Color textPrimaryLight = Color.fromARGB(255, 255, 255, 255);
  static const Color textSecondaryLight = Color.fromARGB(255, 224, 224, 224);

  // Background colors
  static const Color backgroundLight = Color.fromARGB(255, 255, 255, 255);
  static const Color backgroundDark = Color.fromARGB(255, 18, 18, 18);
  static const Color surfaceLight = Color.fromARGB(255, 242, 242, 242);
  static const Color surfaceDark = Color.fromARGB(255, 30, 30, 30);

  // Card colors
  static const Color cardLight = Color.fromARGB(255, 255, 255, 255);
  static const Color cardDark = Color.fromARGB(255, 35, 35, 35);

  // Border colors
  static const Color borderLight = Color.fromARGB(255, 224, 224, 224);
  static const Color borderDark = Color.fromARGB(255, 45, 45, 45);

  // Error colors
  static const Color errorColor = Color.fromARGB(255, 244, 67, 54);
  static const Color errorLightColor = Color.fromARGB(255, 255, 138, 128);
  static const Color errorDarkColor = Color.fromARGB(255, 198, 40, 40);

  // Success colors
  static const Color successColor = Color.fromARGB(255, 76, 175, 80);
  static const Color successLightColor = Color.fromARGB(255, 129, 199, 132);
  static const Color successDarkColor = Color.fromARGB(255, 56, 142, 60);

  // Icon colors
  static const Color iconLight = Color.fromARGB(255, 117, 117, 117);
  static const Color iconDark = Color.fromARGB(255, 189, 189, 189);

  // Button colors
  static const Color buttonPrimary = primaryColor;
  static const Color buttonSecondary = secondaryColor;
  static Color buttonDisabled = primaryColor.withOpacity(0.5);

  // Input field colors
  static const Color inputBorderLight = borderLight;
  static const Color inputBorderDark = borderDark;
  static const Color inputFocusedBorder = primaryColor;
  static const Color inputErrorBorder = errorColor;

  // Shadow colors
  static Color shadowLight = Colors.black.withOpacity(0.1);
  static Color shadowDark = Colors.black.withOpacity(0.2);

  // Get theme data
  static ThemeData getLightTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundLight,
      cardColor: cardLight,
      dividerColor: borderLight,
      shadowColor: shadowLight,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundLight,
        surface: surfaceLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimaryDark),
        elevation: 0,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: textPrimaryDark),
        bodyLarge: TextStyle(color: textPrimaryDark),
        bodyMedium: TextStyle(color: textSecondaryDark),
      ),
      iconTheme: IconThemeData(color: iconLight),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonPrimary,
          foregroundColor: textPrimaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputFocusedBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputErrorBorder),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputErrorBorder),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: cardDark,
      dividerColor: borderDark,
      shadowColor: shadowDark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundDark,
        surface: surfaceDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        titleTextStyle: TextStyle(
          color: textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimaryLight),
        elevation: 0,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(color: textPrimaryLight),
        bodyLarge: TextStyle(color: textPrimaryLight),
        bodyMedium: TextStyle(color: textSecondaryLight),
      ),
      iconTheme: IconThemeData(color: iconDark),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonPrimary,
          foregroundColor: textPrimaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputFocusedBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputErrorBorder),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputErrorBorder),
        ),
      ),
    );
  }
}
