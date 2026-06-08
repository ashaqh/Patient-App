import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/themes/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 28,
    this.blur = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: AppTheme.glassCardDecoration(
        borderRadius: borderRadius,
        color: color,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class GradientOrbBackground extends StatelessWidget {
  final Widget child;

  const GradientOrbBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.appBackgroundDecoration,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned(
            top: -80,
            left: -40,
            child: _GlowOrb(size: 220, color: Color(0x553B82F6)),
          ),
          const Positioned(
            top: 140,
            right: -60,
            child: _GlowOrb(size: 180, color: Color(0x4014B8A6)),
          ),
          const Positioned(
            bottom: -40,
            left: 20,
            child: _GlowOrb(size: 240, color: Color(0x3314B8A6)),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: theme.labelMedium?.copyWith(
                  color: AppTheme.tertiaryFixed,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(title, style: theme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: theme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class GradientFab extends StatelessWidget {
  static const double _bottomNavigationClearance = 112;

  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  const GradientFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final fab = Container(
      width: label == null ? 72 : null,
      height: 72,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x553B82F6),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(36),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 28),
                if (label != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    label!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: _bottomNavigationClearance),
        child: fab,
      ),
    );
  }
}
