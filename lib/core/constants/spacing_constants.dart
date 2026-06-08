/// Spacing constants based on 8px base unit
class AppSpacing {
  // Base unit
  static const double base = 8.0;

  // Spacing scale
  static const double xs = base * 0.5; // 4px
  static const double s = base;        // 8px
  static const double m = base * 2;    // 16px
  static const double l = base * 3;    // 24px
  static const double xl = base * 4;   // 32px
  static const double xxl = base * 6;  // 48px

  // Screen margins
  static const double screenHorizontal = m;  // 16px
  static const double screenVertical = xl;    // 32px

  // Card padding
  static const double cardPadding = l;        // 24px

  // Button dimensions
  static const double buttonHeight = base * 7; // 56px
  static const double buttonPaddingHorizontal = l; // 24px
  static const double buttonPaddingVertical = m;   // 16px

  // Input field dimensions
  static const double inputHeight = base * 7; // 56px
  static const double inputPaddingHorizontal = m; // 16px
  static const double inputPaddingVertical = l;   // 24px

  // Icon dimensions
  static const double iconSizeSmall = base * 3; // 24px
  static const double iconSizeMedium = base * 4; // 32px
  static const double iconSizeLarge = base * 5; // 40px

  // Border radius
  static const double borderRadiusSmall = base * 1.5; // 12px
  static const double borderRadiusMedium = base * 2;  // 16px
  static const double borderRadiusLarge = base * 3;   // 24px

  // Touch target minimums (accessibility)
  static const double minTouchTarget = base * 6; // 48px
}
