import 'package:flutter/material.dart';

class AppTheme {
  // Modern Healthcare Color Palette
  static const Color primaryColor = Color(0xFF2563EB); // Vibrant blue for trust and reliability
  static const Color primaryContainer = Color(0xFFDBEAFE); // Light blue container
  static const Color primaryFixed = Color(0xFF1D4ED8); // Darker blue for emphasis
  static const Color primaryFixedDim = Color(0xFF93C5FD); // Muted blue for backgrounds
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFF7C3AED); // Purple for complementary actions
  static const Color secondaryContainer = Color(0xFFE9D5FF); // Light purple container
  
  // Tertiary colors
  static const Color tertiaryColor = Color(0xFF059669); // Green for positive actions
  static const Color tertiaryFixed = Color(0xFF34D399); // Light green fixed
  static const Color tertiaryFixedDim = Color(0xFFA7F3D0); // Dimmed light green
  
  // Surface and background colors
  static const Color surfaceColor = Color(0xFFFFFFFF); // Clean white background
  static const Color surfaceContainer = Color(0xFFF8FAFC); // Very light gray container
  static const Color surfaceContainerHigh = Color(0xFFF1F5F9); // Slightly darker container
  static const Color surfaceContainerHighest = Color(0xFFE2E8F0); // Highest surface container
  
  // Text colors
  static const Color onPrimaryColor = Color(0xFFFFFFFF); // White on primary
  static const Color onSurfaceColor = Color(0xFF0F172A); // Dark slate for main text
  static const Color onSurfaceVariant = Color(0xFF475569); // Slate gray for secondary text
  static const Color onSecondaryColor = Color(0xFFFFFFFF); // White on secondary
  
  // Status colors
  static const Color errorColor = Color(0xFFDC2626); // Modern red for errors
  static const Color errorContainer = Color(0xFFFEE2E2); // Light red error container
  static const Color successColor = Color(0xFF059669); // Green success
  static const Color warningColor = Color(0xFFD97706); // Amber warning
  static const Color infoColor = Color(0xFF2563EB); // Blue for info
  
  // Border and outline colors
  static const Color outlineColor = Color(0xFFCBD5E1); // Light slate for outlines
  static const Color outlineVariant = Color(0xFFE2E8F0); // Very light variant
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Light theme matching HTML design
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryContainer,
        secondary: secondaryColor,
        secondaryContainer: secondaryContainer,
        tertiary: tertiaryColor,
        tertiaryContainer: tertiaryFixedDim,
        surface: surfaceColor,
        surfaceVariant: surfaceContainer,
        background: surfaceColor,
        error: errorColor,
        onPrimary: onPrimaryColor,
        onSecondary: onSecondaryColor,
        onSurface: onSurfaceColor,
        onBackground: onSurfaceColor,
        onError: Colors.white,
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
  
  // Modern Text Theme for Healthcare App
  static TextTheme get _carevaultTextTheme {
    return const TextTheme(
      // Display styles - Large headings
      displayLarge: TextStyle(
        fontSize: 48, 
        fontWeight: FontWeight.w800, 
        height: 1.1, 
        fontFamily: 'Inter',
        letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        fontSize: 36, 
        fontWeight: FontWeight.w800, 
        height: 1.15, 
        fontFamily: 'Inter',
        letterSpacing: -1,
      ),
      displaySmall: TextStyle(
        fontSize: 32, 
        fontWeight: FontWeight.w700, 
        height: 1.2, 
        fontFamily: 'Inter',
        letterSpacing: -0.5,
      ),
      
      // Headline styles - Section headings
      headlineLarge: TextStyle(
        fontSize: 28, 
        fontWeight: FontWeight.w700, 
        height: 1.25, 
        fontFamily: 'Inter',
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24, 
        fontWeight: FontWeight.w600, 
        height: 1.3, 
        fontFamily: 'Inter',
        letterSpacing: -0.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 20, 
        fontWeight: FontWeight.w600, 
        height: 1.35, 
        fontFamily: 'Inter',
      ),
      
      // Title styles - Card titles, button text
      titleLarge: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
      ),
      titleMedium: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
      ),
      titleSmall: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
      ),
      
      // Body styles - Main content text
      bodyLarge: TextStyle(
        fontSize: 16, 
        fontWeight: FontWeight.normal, 
        height: 1.5, 
        fontFamily: 'Inter',
      ),
      bodyMedium: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.normal, 
        height: 1.5, 
        fontFamily: 'Inter',
      ),
      bodySmall: TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.normal, 
        height: 1.5, 
        fontFamily: 'Inter',
      ),
      
      // Label styles - Labels, captions, metadata
      labelLarge: TextStyle(
        fontSize: 14, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        letterSpacing: 0.25,
      ),
      labelSmall: TextStyle(
        fontSize: 10, 
        fontWeight: FontWeight.w600, 
        height: 1.4, 
        fontFamily: 'Inter',
        letterSpacing: 0.1,
      ),
    );
  }
  
  // Modern Input Decoration Theme
  static InputDecorationTheme get _carevaultInputDecorationTheme {
    return InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5, color: outlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5, color: outlineColor),
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
      fillColor: surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
      hintStyle: const TextStyle(
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
        color: onSurfaceVariant,
      ),
      errorStyle: const TextStyle(
        fontSize: 12,
        fontFamily: 'Inter',
        fontWeight: FontWeight.normal,
      ),
      floatingLabelStyle: const TextStyle(
        fontSize: 12,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
    );
  }
  
  // Modern Button Themes
  
  static ElevatedButtonThemeData get _carevaultElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56), // Accessible touch target
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
  
  // Modern App Bar Theme
  static AppBarTheme get _carevaultAppBarTheme {
    return AppBarTheme(
      backgroundColor: surfaceColor,
      foregroundColor: onSurfaceColor,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Inter',
        color: onSurfaceColor,
        letterSpacing: -0.5,
      ),
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(
        color: onSurfaceColor,
        size: 28,
      ),
      actionsIconTheme: const IconThemeData(
        color: onSurfaceColor,
        size: 28,
      ),
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(
          width: 1,
          color: outlineVariant,
        ),
      ),
    );
  }
  
  // Modern Card Theme
  static CardThemeData get _carevaultCardTheme {
    return CardThemeData(
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(width: 1, color: outlineVariant),
      ),
      margin: const EdgeInsets.all(0),
      clipBehavior: Clip.antiAlias,
      surfaceTintColor: Colors.transparent,
    );
  }
  
  // Bottom navigation bar theme matching HTML design
  static BottomNavigationBarThemeData get _carevaultBottomNavBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryColor.withOpacity(0.7),
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        fontFamily: 'Inter',
      ),
      elevation: 8,
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
  
  // Helper methods matching HTML design classes
  
  // Display styles
  static TextStyle get displayLgStyle => const TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 56/48,
    fontFamily: 'Inter',
  );
  
  // Headline styles
  static TextStyle get headlineLgStyle => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 40/32,
    fontFamily: 'Inter',
  );
  
  static TextStyle get headlineMdStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32/24,
    fontFamily: 'Inter',
  );
  
  // Body styles
  static TextStyle get bodyLgStyle => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.normal,
    height: 30/20,
    fontFamily: 'Inter',
  );
  
  static TextStyle get bodyMdStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    height: 28/18,
    fontFamily: 'Inter',
  );
  
  // Label styles
  static TextStyle get labelBoldStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 24/18,
    fontFamily: 'Inter',
  );
  
  // Card styles
  static BoxDecoration get primaryCardDecoration => BoxDecoration(
    color: primaryColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(width: 4, color: primaryColor),
  );
  
  static BoxDecoration get surfaceCardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(width: 2, color: outlineVariant),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static BoxDecoration get errorCardDecoration => BoxDecoration(
    color: errorContainer,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(width: 4, color: errorColor),
  );
  
  // Button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: onPrimaryColor,
    minimumSize: const Size(64, 64),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 4,
  );
  
  static ButtonStyle get outlineButtonStyle => OutlinedButton.styleFrom(
    backgroundColor: surfaceColor,
    foregroundColor: primaryColor,
    minimumSize: const Size(64, 64),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    ),
    side: const BorderSide(width: 2, color: primaryColor),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}