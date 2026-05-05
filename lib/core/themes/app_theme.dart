import 'package:flutter/material.dart';

class AppTheme {
  // Provided Color Palette - Strict adherence
  static const Color primaryColor = Color(0xFF1A2B4C); // Dark Navy Blue - Primary actions
  static const Color secondaryColor = Color(0xFFE6F0FA); // Very Light Blue - Backgrounds
  static const Color tertiaryColor = Color(0xFF3F2600); // Dark Brown - Warnings/Critical
  static const Color neutralColor = Color(0xFF77777A); // Medium Gray - Secondary text
  
  // Derived colors from palette
  static const Color surfaceColor = Color(0xFFFFFFFF); // White for surfaces
  static const Color onPrimaryColor = Color(0xFFFFFFFF); // White on primary
  static const Color onSurfaceColor = Color(0xFF1A2B4C); // Primary color for main text
  static const Color onSurfaceVariant = Color(0xFF77777A); // Neutral for secondary text
  
  // Status colors (using provided palette)
  static const Color errorColor = Color(0xFF3F2600); // Brown for errors/warnings
  static const Color errorContainer = Color(0xFFFFF8F0); // Light amber background
  static const Color successColor = Color(0xFF1A2B4C); // Navy for success (with checkmark)
  static const Color warningColor = Color(0xFF3F2600); // Brown for warnings
  static const Color infoColor = Color(0xFF1A2B4C); // Navy for info
  
  // Border and outline colors
  static const Color outlineColor = Color(0xFF77777A); // Neutral for borders
  static const Color outlineVariant = Color(0xFFE6F0FA); // Secondary for subtle borders
  
  // Surface containers
  static const Color surfaceContainer = Color(0xFFE6F0FA); // Secondary for containers
  static const Color surfaceContainerHigh = Color(0xFFD9E4F2); // Slightly darker container
  static const Color surfaceContainerHighest = Color(0xFFCCD8E8); // Highest surface container
  
  // Light theme with new color system
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: Color(0x1A1A2B4C), // primaryColor.withAlpha(26)
        secondary: secondaryColor,
        secondaryContainer: secondaryColor,
        tertiary: tertiaryColor,
        tertiaryContainer: Color(0x1A3F2600), // tertiaryColor.withAlpha(26)
        surface: surfaceColor,
        surfaceVariant: secondaryColor,
        background: secondaryColor,
        error: errorColor,
        onPrimary: onPrimaryColor,
        onSecondary: primaryColor,
        onSurface: onSurfaceColor,
        onBackground: onSurfaceColor,
        onError: surfaceColor,
        outline: outlineColor,
        outlineVariant: outlineVariant,
      ),
      textTheme: _carevaultTextTheme,
      inputDecorationTheme: _carevaultInputDecorationTheme,
      elevatedButtonTheme: _carevaultElevatedButtonTheme,
      outlinedButtonTheme: _carevaultOutlinedButtonTheme,
      textButtonTheme: _carevaultTextButtonTheme,
      appBarTheme: _carevaultAppBarTheme,
      cardTheme: _carevaultCardTheme,
      bottomNavigationBarTheme: _carevaultBottomNavBarTheme,
      floatingActionButtonTheme: _carevaultFloatingActionButtonTheme,
    );
  }
  
  // Dark theme matching HTML design
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB6C6F0), // Light blue for dark mode
        primaryContainer: Color(0xFF364669),
        secondary: Color(0xFFBEC8D1),
        secondaryContainer: Color(0xFF3E4850),
        tertiary: Color(0xFFEABF8A),
        tertiaryContainer: Color(0xFF5E4117),
        surface: Color(0xFF121212),
        surfaceVariant: Color(0xFF303033),
        background: Color(0xFF121212),
        error: Color(0xFFFFB4AB),
        onPrimary: Color(0xFF1B1B1E),
        onSecondary: Color(0xFF1B1B1E),
        onSurface: Color(0xFFE4E2E5),
        onBackground: Color(0xFFE4E2E5),
        onError: Color(0xFF690005),
        outline: Color(0xFF8E9099),
        outlineVariant: Color(0xFF44474E),
      ),
      textTheme: _carevaultTextTheme,
      inputDecorationTheme: _carevaultInputDecorationTheme,
      elevatedButtonTheme: _carevaultElevatedButtonTheme,
      outlinedButtonTheme: _carevaultOutlinedButtonTheme,
      textButtonTheme: _carevaultTextButtonTheme,
      appBarTheme: _carevaultAppBarTheme,
      cardTheme: _carevaultCardTheme,
      bottomNavigationBarTheme: _carevaultBottomNavBarTheme,
      floatingActionButtonTheme: _carevaultFloatingActionButtonTheme,
    );
  }
  
  // Typography System - Optimized for Elderly Users
  static TextTheme get _carevaultTextTheme {
    return TextTheme(
      // Display styles - Large headings
      displayLarge: TextStyle(
        fontSize: 32, 
        fontWeight: FontWeight.w700, 
        height: 1.3, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28, 
        fontWeight: FontWeight.w600, 
        height: 1.25, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24, 
        fontWeight: FontWeight.w600, 
        height: 1.2, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      
      // Headline styles - Section headings
      headlineLarge: TextStyle(
        fontSize: 22, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.w600, 
        height: 1.35, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w600, 
        height: 1.3, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      
      // Title styles - Card titles, button text
      titleLarge: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      
      // Body styles - Main content text (minimum 16px for elderly users)
      bodyLarge: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.normal, 
        height: 1.5, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.normal, 
        height: 1.5, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      bodySmall: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.normal, 
        height: 1.5, 
        fontFamily: 'Inter',
        color: onSurfaceColor,
      ),
      
      // Label styles - Labels, captions, metadata (uses neutral color)
      labelLarge: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        color: onSurfaceVariant,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        color: onSurfaceVariant,
        letterSpacing: 0.25,
      ),
      labelSmall: TextStyle(
        fontSize: 10, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        color: onSurfaceVariant,
        letterSpacing: 0.1,
      ),
    );
  }
  
  // Input Decoration Theme - Elderly-friendly
  static InputDecorationTheme get _carevaultInputDecorationTheme {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2, color: outlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2, color: outlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2, color: primaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2, color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2, color: errorColor),
      ),
      filled: true,
      fillColor: secondaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
      hintStyle: const TextStyle(
        fontSize: 16,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: onSurfaceVariant,
      ),
      errorStyle: const TextStyle(
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: errorColor,
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
    );
  }
  
  // Button Themes - Large touch targets for elderly users
  
  static ElevatedButtonThemeData get _carevaultElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56), // Large touch target
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
          letterSpacing: 0.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        foregroundColor: onPrimaryColor,
        backgroundColor: primaryColor,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
  
  static OutlinedButtonThemeData get _carevaultOutlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        side: const BorderSide(width: 2, color: outlineColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        foregroundColor: primaryColor,
        backgroundColor: surfaceColor,
      ),
    );
  }
  
  static TextButtonThemeData get _carevaultTextButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        foregroundColor: primaryColor,
      ),
    );
  }
  
  // App Bar Theme - Primary color background
  static AppBarTheme get _carevaultAppBarTheme {
    return AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        color: onPrimaryColor,
        letterSpacing: -0.5,
      ),
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(
        color: onPrimaryColor,
        size: 28,
      ),
      actionsIconTheme: const IconThemeData(
        color: onPrimaryColor,
        size: 28,
      ),
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      shape: const Border(),
    );
  }
  
  // Card Theme - Clean and accessible
  static CardThemeData get _carevaultCardTheme {
    return CardThemeData(
      color: surfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(width: 1, color: outlineVariant),
      ),
      margin: const EdgeInsets.all(0),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
    );
  }
  
  // Bottom Navigation Bar Theme - Large touch targets
  static BottomNavigationBarThemeData get _carevaultBottomNavBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: neutralColor,
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        fontFamily: 'Inter',
      ),
      elevation: 4,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }
  
  // Floating action button theme
  static FloatingActionButtonThemeData get _carevaultFloatingActionButtonTheme {
    return const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: onPrimaryColor,
      sizeConstraints: BoxConstraints(minWidth: 64, minHeight: 64),
      shape: CircleBorder(),
      elevation: 4,
    );
  }
  
  // Helper methods for consistent styling
  
  // Display styles
  static TextStyle get displayLgStyle => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.3,
    fontFamily: 'Inter',
    color: onSurfaceColor,
  );
  
  // Headline styles
  static TextStyle get headlineLgStyle => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: 'Inter',
    color: onSurfaceColor,
  );
  
  static TextStyle get headlineMdStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.35,
    fontFamily: 'Inter',
    color: onSurfaceColor,
  );
  
  // Body styles
  static TextStyle get bodyLgStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 1.5,
    fontFamily: 'Inter',
    color: onSurfaceColor,
  );
  
  static TextStyle get bodyMdStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    fontFamily: 'Inter',
    color: onSurfaceColor,
  );
  
  // Label styles
  static TextStyle get labelBoldStyle => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    fontFamily: 'Inter',
    color: onSurfaceVariant,
  );
  
  // Card styles
  static BoxDecoration get primaryCardDecoration => BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get surfaceCardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(width: 1, color: outlineVariant),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get alertCardDecoration => BoxDecoration(
    color: errorContainer,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(width: 2, color: errorColor),
  );
  
  // Status badge decorations
  static BoxDecoration get pendingBadgeDecoration => BoxDecoration(
    color: secondaryColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(width: 1, color: outlineColor),
  );
  
  static BoxDecoration get successBadgeDecoration => BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(width: 1, color: primaryColor),
  );
  
  static BoxDecoration get warningBadgeDecoration => BoxDecoration(
    color: errorContainer,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(width: 1, color: errorColor),
  );
  
  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: onPrimaryColor,
    minimumSize: const Size(64, 56),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: primaryColor,
    minimumSize: const Size(64, 56),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );
}
