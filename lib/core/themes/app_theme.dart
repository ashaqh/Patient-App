import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF3B82F6);
  static const Color secondaryColor = Color(0xFF0F172A);
  static const Color tertiaryColor = Color(0xFF14B8A6);
  static const Color neutralColor = Color(0xFF94A3B8);

  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color onSurfaceColor = Color(0xFFF8FAFC);
  static const Color onSurfaceVariant = Color(0xFFCBD5E1);

  static const Color errorColor = Color(0xFFEF4444);
  static const Color errorContainer = Color(0xFF3B0D18);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF60A5FA);

  static const Color outlineColor = Color(0x33FFFFFF);
  static const Color outlineVariant = Color(0x1FFFFFFF);

  static const Color surfaceContainer = Color(0xFF111827);
  static const Color surfaceContainerHigh = Color(0xFF172033);
  static const Color surfaceContainerHighest = Color(0xFF1E293B);
  static const Color primaryFixed = Color(0xFF93C5FD);
  static const Color tertiaryFixed = Color(0xFF99F6E4);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A),
      Color(0xFF1E3A8A),
      Color(0xFF0F172A),
    ],
    stops: [0, 0.55, 1],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF14B8A6)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
  );

  static Widget datePickerThemeBuilder(BuildContext context, Widget? child) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: child!,
    );
  }

  static Widget timePickerThemeBuilder(BuildContext context, Widget? child) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: child!,
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.dark(
      primary: primaryColor,
      primaryContainer: Color(0xFF1D4ED8),
      secondary: tertiaryColor,
      secondaryContainer: Color(0xFF0F766E),
      tertiary: infoColor,
      tertiaryContainer: Color(0xFF1E40AF),
      surface: Color(0xFF111827),
      surfaceContainerHighest: surfaceContainerHighest,
      error: errorColor,
      onPrimary: onPrimaryColor,
      onSecondary: onPrimaryColor,
      onSurface: onSurfaceColor,
      outline: outlineColor,
      outlineVariant: outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      textTheme: _carevaultTextTheme,
      appBarTheme: _carevaultAppBarTheme,
      cardTheme: _carevaultCardTheme,
      inputDecorationTheme: _carevaultInputDecorationTheme,
      elevatedButtonTheme: _carevaultElevatedButtonTheme,
      outlinedButtonTheme: _carevaultOutlinedButtonTheme,
      textButtonTheme: _carevaultTextButtonTheme,
      bottomNavigationBarTheme: _carevaultBottomNavBarTheme,
      floatingActionButtonTheme: _carevaultFloatingActionButtonTheme,
      chipTheme: _carevaultChipTheme,
      dividerColor: outlineVariant,
      iconTheme: const IconThemeData(color: onSurfaceColor),
      datePickerTheme: _carevaultDatePickerTheme,
      timePickerTheme: _carevaultTimePickerTheme,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;

  static DatePickerThemeData get _carevaultDatePickerTheme {
    return DatePickerThemeData(
      backgroundColor: const Color(0xCC111827),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: outlineColor, width: 1.5),
      ),
      headerBackgroundColor: Colors.transparent,
      headerForegroundColor: onSurfaceColor,
      dayForegroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return onPrimaryColor;
        if (states.contains(MaterialState.disabled)) return onSurfaceVariant.withValues(alpha: 0.38);
        return onSurfaceColor;
      }),
      dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return primaryColor;
        return Colors.transparent;
      }),
      todayForegroundColor: MaterialStateProperty.all(primaryColor),
      yearForegroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return onPrimaryColor;
        if (states.contains(MaterialState.disabled)) return onSurfaceVariant.withValues(alpha: 0.38);
        return onSurfaceColor;
      }),
      yearBackgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return primaryColor;
        return Colors.transparent;
      }),
    );
  }

  static TimePickerThemeData get _carevaultTimePickerTheme {
    return TimePickerThemeData(
      backgroundColor: const Color(0xCC111827),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: outlineColor, width: 1.5),
      ),
      hourMinuteTextColor: onSurfaceColor,
      hourMinuteColor: const Color(0x14FFFFFF),
      dayPeriodTextColor: onSurfaceColor,
      dayPeriodColor: const Color(0x14FFFFFF),
      dayPeriodBorderSide: const BorderSide(color: outlineColor, width: 1),
      dialHandColor: primaryColor,
      dialBackgroundColor: const Color(0x14FFFFFF),
      dialTextColor: onSurfaceColor,
      entryModeIconColor: primaryColor,
    );
  }

  static TextTheme get _carevaultTextTheme {
    final base = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.18,
        color: onSurfaceColor,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: onSurfaceColor,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.22,
        color: onSurfaceColor,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.24,
        color: onSurfaceColor,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.28,
        color: onSurfaceColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: onSurfaceColor,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurfaceColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurfaceColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurfaceColor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurfaceColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurfaceColor,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurfaceVariant,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
    );
  }

  static InputDecorationTheme get _carevaultInputDecorationTheme {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x14FFFFFF),
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: onSurfaceVariant,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: outlineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: outlineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primaryFixed, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: errorColor, width: 1.4),
      ),
      prefixIconColor: onSurfaceVariant,
      suffixIconColor: onSurfaceVariant,
    );
  }

  static ElevatedButtonThemeData get _carevaultElevatedButtonTheme {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        foregroundColor: onPrimaryColor,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static OutlinedButtonThemeData get _carevaultOutlinedButtonTheme {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: outlineColor),
        foregroundColor: onSurfaceColor,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static TextButtonThemeData get _carevaultTextButtonTheme {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: primaryFixed,
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static AppBarTheme get _carevaultAppBarTheme {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: onPrimaryColor,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: onPrimaryColor,
      ),
      iconTheme: const IconThemeData(color: onPrimaryColor, size: 24),
      actionsIconTheme: const IconThemeData(color: onPrimaryColor, size: 24),
      shadowColor: Colors.transparent,
      scrolledUnderElevation: 0,
    );
  }

  static CardThemeData get _carevaultCardTheme {
    return CardThemeData(
      color: glassSurface,
      margin: EdgeInsets.zero,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: outlineColor),
      ),
    );
  }

  static ChipThemeData get _carevaultChipTheme {
    return ChipThemeData(
      backgroundColor: const Color(0x14FFFFFF),
      selectedColor: primaryColor,
      disabledColor: const Color(0x0FFFFFFF),
      side: const BorderSide(color: outlineColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      labelStyle: GoogleFonts.inter(fontSize: 13, color: onSurfaceVariant),
      secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, color: onPrimaryColor),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      brightness: Brightness.dark,
    );
  }

  static BottomNavigationBarThemeData get _carevaultBottomNavBarTheme {
    return BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: onPrimaryColor,
      unselectedItemColor: onSurfaceVariant,
      selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }

  static FloatingActionButtonThemeData get _carevaultFloatingActionButtonTheme {
    return const FloatingActionButtonThemeData(
      backgroundColor: Colors.transparent,
      foregroundColor: onPrimaryColor,
      sizeConstraints: BoxConstraints(minWidth: 72, minHeight: 72),
      shape: CircleBorder(),
      elevation: 0,
      highlightElevation: 0,
    );
  }

  static const Color glassSurface = Color(0x14FFFFFF);
  static const Color glassSurfaceStrong = Color(0x1FFFFFFF);

  static BoxDecoration get appBackgroundDecoration => const BoxDecoration(
    gradient: backgroundGradient,
  );

  static BoxDecoration glassCardDecoration({
    double borderRadius = 28,
    Color? color,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: color ?? glassSurface,
      border: Border.all(color: outlineColor),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ],
    );
  }

  static BoxDecoration solidCardDecoration({double borderRadius = 28}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(borderRadius),
      color: const Color(0xCC111827),
      border: Border.all(color: outlineColor),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration get primaryCardDecoration => solidCardDecoration(borderRadius: 28);
  static BoxDecoration get surfaceCardDecoration => glassCardDecoration();
  static BoxDecoration get alertCardDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    color: const Color(0x1AEF4444),
    border: Border.all(color: const Color(0x55EF4444)),
  );

  static BoxDecoration get pendingBadgeDecoration => BoxDecoration(
    color: const Color(0x14FFFFFF),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: outlineColor),
  );

  static BoxDecoration get successBadgeDecoration => BoxDecoration(
    color: const Color(0x1A22C55E),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: const Color(0x6622C55E)),
  );

  static BoxDecoration get warningBadgeDecoration => BoxDecoration(
    color: const Color(0x1AF59E0B),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: const Color(0x66F59E0B)),
  );

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    minimumSize: const Size(64, 56),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    foregroundColor: onPrimaryColor,
    backgroundColor: primaryColor,
    textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 0,
    shadowColor: Colors.transparent,
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    minimumSize: const Size(64, 56),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    foregroundColor: onSurfaceColor,
    backgroundColor: const Color(0x14FFFFFF),
    textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 0,
    shadowColor: Colors.transparent,
  );

  static TextStyle get displayLgStyle => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.18,
    color: onSurfaceColor,
  );

  static TextStyle get headlineLgStyle => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.24,
    color: onSurfaceColor,
  );

  static TextStyle get headlineMdStyle => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.28,
    color: onSurfaceColor,
  );

  static TextStyle get bodyLgStyle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: onSurfaceColor,
  );

  static TextStyle get bodyMdStyle => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: onSurfaceColor,
  );

  static TextStyle get labelBoldStyle => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: onSurfaceVariant,
  );
}
