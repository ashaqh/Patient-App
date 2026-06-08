import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Splash screen featuring the Apprise Apps logo with a scale + fade animation,
/// and "Apprise Apps" text at the bottom.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _fadeOutDuration = Duration(milliseconds: 500);

  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  bool _showLogo = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _pulseController.repeat(reverse: true);

    _controller.forward().whenCompleteOrCancel(() {
      if (mounted) {
        setState(() => _showLogo = false);
        Future.delayed(_fadeOutDuration, widget.onComplete);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2B4C),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: _showLogo
                  ? FadeTransition(
                      opacity: _opacityAnim,
                      child: ScaleTransition(
                        scale: _scaleAnim,
                        child: const _LogoWidget(),
                      ),
                    )
                  : const SizedBox(
                      width: 120,
                      height: 120,
                    ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.40, 1.0, curve: Curves.easeIn),
                  ),
                  child: const Text(
                    'Apprise Apps',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE6F0FA),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The logo widget — a circle badge containing the app icon.
class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  static const double _size = 120;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
