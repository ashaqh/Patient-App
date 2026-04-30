import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors for medical/healthcare theme
  static const Color primaryColor = Color(0xFF2196F3); // Blue - medical/trust
  static const Color secondaryColor = Color(0xFF4CAF50); // Green - health/vitality
  static const Color accentColor = Color(0xFFFF9800); // Orange - attention/alert
  static const Color errorColor = Color(0xFFF44336); // Red - error/warning
  static const Color successColor = Color(0xFF4CAF50); // Green - success
  static const Color warningColor = Color(0xFFFF9800); // Orange - warning
  
  // High contrast colors for elderly users
  static const Color highContrastText = Color(0xFF000000);
  static const Color highContrastBackground = Color(0xFFFFFFFF);
  static const Color highContrastSurface = Color(0xFFF5F5F5);
  
  // Light theme with high contrast for elderly users
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: highContrastSurface,
        background: highContrastBackground,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: highContrastText,
        onBackground: highContrastText,
        onError: Colors.white,
      ),
      textTheme: _elderlyFriendlyTextTheme,
      inputDecorationTheme: _elderlyFriendlyInputDecorationTheme,
      buttonTheme: _elderlyFriendlyButtonTheme,
      elevatedButtonTheme: _elderlyFriendlyElevatedButtonTheme,
      outlinedButtonTheme: _elderlyFriendlyOutlinedButtonTheme,
      textButtonTheme: _elderlyFriendlyTextButtonTheme,
      appBarTheme: _elderlyFriendlyAppBarTheme,
      cardTheme: _elderlyFriendlyCardTheme,
      dialogTheme: _elderlyFriendlyDialogTheme,
    );
  }
  
  // Dark theme with high contrast for elderly users
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: const Color(0xFF424242),
        background: const Color(0xFF303030),
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
        onError: Colors.white,
      ),
      textTheme: _elderlyFriendlyTextTheme,
      inputDecorationTheme: _elderlyFriendlyInputDecorationTheme,
      buttonTheme: _elderlyFriendlyButtonTheme,
      elevatedButtonTheme: _elderlyFriendlyElevatedButtonTheme,
      outlinedButtonTheme: _elderlyFriendlyOutlinedButtonTheme,
      textButtonTheme: _elderlyFriendlyTextButtonTheme,
      appBarTheme: _elderlyFriendlyAppBarTheme,
      cardTheme: _elderlyFriendlyCardTheme,
      dialogTheme: _elderlyFriendlyDialogTheme,
    );
  }
  
  // Text theme with large fonts for elderly users
  static TextTheme get _elderlyFriendlyTextTheme {
    return const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
      displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.2),
      titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.2),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, height: 1.5),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5),
      bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.5),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.2),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2),
      labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.2),
    );
  }
  
  // Input decoration with large text and clear borders
  static InputDecorationTheme get _elderlyFriendlyInputDecorationTheme {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(width: 2, color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(width: 3, color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(width: 2, color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(width: 3, color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      labelStyle: const TextStyle(fontSize: 16),
      hintStyle: const TextStyle(fontSize: 16),
      errorStyle: const TextStyle(fontSize: 14),
    );
  }
  
  // Button theme with large touch targets
  static ButtonThemeData get _elderlyFriendlyButtonTheme {
    return ButtonThemeData(
      minWidth: 120,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
  
  static ElevatedButtonThemeData get _elderlyFriendlyElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(120, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  static OutlinedButtonThemeData get _elderlyFriendlyOutlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        side: BorderSide(width: 2, color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  static TextButtonThemeData get _elderlyFriendlyTextButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(120, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
  
  // App bar theme with large title
  static AppBarTheme get _elderlyFriendlyAppBarTheme {
    return const AppBarTheme(
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      centerTitle: true,
      elevation: 4,
    );
  }
  
  // Card theme with clear elevation and padding
  static CardTheme get _elderlyFriendlyCardTheme {
    return CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
    );
  }
  
  // Dialog theme with large text and clear layout
  static DialogTheme get _elderlyFriendlyDialogTheme {
    return DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
    );
  }
  
  // Helper method to get text style for different importance levels
  static TextStyle get headlineStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
  
  static TextStyle get titleStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  
  static TextStyle get bodyStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  static TextStyle get buttonStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle get captionStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
}