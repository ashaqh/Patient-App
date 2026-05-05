import 'package:flutter/material.dart';

class ElderlyFriendlyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool disabled;
  final double? width;
  final double? height;
  final double fontSize;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const ElderlyFriendlyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.disabled = false,
    this.width,
    this.height,
    this.fontSize = 18,
    this.fullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: fullWidth ? double.infinity : width,
      height: height ?? 56,
      child: ElevatedButton(
        onPressed: disabled || isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: textColor ?? theme.colorScheme.onPrimary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: fontSize * 1.2,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ElderlyFriendlyOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? borderColor;
  final Color? textColor;
  final bool isLoading;
  final bool disabled;
  final double? width;
  final double? height;
  final double fontSize;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const ElderlyFriendlyOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.borderColor,
    this.textColor,
    this.isLoading = false,
    this.disabled = false,
    this.width,
    this.height,
    this.fontSize = 18,
    this.fullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: fullWidth ? double.infinity : width,
      height: height ?? 56,
      child: OutlinedButton(
        onPressed: disabled || isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            width: 2,
            color: borderColor ?? theme.colorScheme.primary,
          ),
          foregroundColor: textColor ?? theme.colorScheme.primary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? theme.colorScheme.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: fontSize * 1.2,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ElderlyFriendlyTextButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? textColor;
  final bool isLoading;
  final bool disabled;
  final double? width;
  final double? height;
  final double fontSize;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final TextDecoration? decoration;

  const ElderlyFriendlyTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.textColor,
    this.isLoading = false,
    this.disabled = false,
    this.width,
    this.height,
    this.fontSize = 18,
    this.fullWidth = false,
    this.padding,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: fullWidth ? double.infinity : width,
      height: height ?? 56,
      child: TextButton(
        onPressed: disabled || isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? theme.colorScheme.primary,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            height: 1.2,
            decoration: decoration,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? theme.colorScheme.primary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: fontSize * 1.2,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ElderlyFriendlyIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final String? tooltip;
  final bool disabled;

  const ElderlyFriendlyIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.tooltip,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IconButton(
      onPressed: disabled ? null : onPressed,
      icon: Icon(
        icon,
        size: size * 0.6,
        color: iconColor ?? theme.colorScheme.onPrimary,
      ),
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        minimumSize: Size(size, size),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      tooltip: tooltip,
    );
  }
}
