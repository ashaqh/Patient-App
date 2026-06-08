import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_handler.dart';
import '../../core/themes/app_theme.dart';
import '../providers/reminder_provider.dart';
import '../providers/app_lock_provider.dart';
import '../widgets/common/glass_widgets.dart';
import 'dashboard_screen_new.dart';
import 'medicine_list_screen_new.dart';
import 'prescription_list_screen_new.dart';
import 'follow_up_list_screen_new.dart';
import 'timeline_screen.dart';
import 'vital_sign_list_screen.dart';
import 'app_lock_screen.dart';
import 'splash_screen.dart';

class App extends ConsumerWidget {
  final NotificationHandler? notificationHandler;

  const App({super.key, this.notificationHandler});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(reminderSchedulerInitializerProvider);
    if (notificationHandler != null) {
      NotificationHandler.onReminderChanged = () {
        ref.invalidate(todaysRemindersProvider);
        ref.invalidate(reminderStatisticsProvider);
      };
    }

    return MaterialApp(
      title: 'CareVault',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

const _icons = <IconData>[
  Icons.home_rounded,
  Icons.medication_rounded,
  Icons.document_scanner_outlined,
  Icons.event_rounded,
  Icons.timeline_rounded,
  Icons.monitor_heart_outlined,
];

const _labels = <String>[
  'Home',
  'Meds',
  'Vault',
  'Follow-ups',
  'Timeline',
  'Vitals',
];

const int tabCount = 6;
const double _navHorizontalInset = 16;
const double _navCapsuleHeight = 68;

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isLocked = false;
  bool _isCheckingLock = true;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Kick off the lock check after splash animation begins
      Future.delayed(const Duration(milliseconds: 500), _checkAppLock);
      // Dismiss splash after the animated duration (2.5 s total)
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) setState(() => _showSplash = false);
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todaysRemindersProvider);
      ref.invalidate(reminderStatisticsProvider);
    }
  }

  Future<void> _checkAppLock() async {
    try {
      final notifier = ref.read(appLockNotifierProvider.notifier);

      final result = await Future.any([
        Future(() async {
          await notifier.loadSettings();
          await notifier.checkLockStatus();
          return true;
        }),
        Future<dynamic>.delayed(const Duration(seconds: 3), () => false),
      ]);

      if (!result) {
        if (mounted) setState(() => _isCheckingLock = false);
        return;
      }

      if (mounted) {
        setState(() {
          _isCheckingLock = false;
          _isLocked = ref.read(appLockNotifierProvider).isLocked;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingLock = false);
    }
  }

  IconData _iconFor(int index) => _icons[index];

  String _labelFor(int index) => _labels[index];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  static final List<Widget> _widgetOptions = [
    const DashboardScreenNew(),
    const MedicineListScreenNew(),
    const PrescriptionListScreenNew(),
    const FollowUpListScreenNew(),
    const TimelineScreen(),
    const VitalSignListScreen(),
  ];

  Widget _buildNavItem(int index) {
    final active = _selectedIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(26),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  scale: active ? 1.08 : 1,
                  child: Icon(
                    _iconFor(index),
                    color: active
                        ? Colors.white
                        : AppTheme.onSurfaceVariant.withValues(alpha: 0.82),
                    size: active ? 24 : 21,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _labelFor(index),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: active
                        ? Colors.white
                        : AppTheme.onSurfaceVariant.withValues(alpha: 0.88),
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding + 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassSurfaceStrong,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: AppTheme.outlineColor),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final navWidth =
                      constraints.maxWidth - (_navHorizontalInset * 2);
                  final itemWidth = navWidth / tabCount;
                  final activeLeft =
                      _navHorizontalInset + (itemWidth * _selectedIndex);

                  return SizedBox(
                    height: _navCapsuleHeight,
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          left: activeLeft,
                          top: 6,
                          width: itemWidth,
                          height: _navCapsuleHeight - 12,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x553B82F6),
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: _navHorizontalInset,
                          right: _navHorizontalInset,
                          top: 0,
                          bottom: 0,
                          child: Row(
                            children: List.generate(tabCount, _buildNavItem),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLockState = ref.watch(appLockNotifierProvider);

    if (!_isCheckingLock && _isLocked != appLockState.isLocked) {
      setState(() => _isLocked = appLockState.isLocked);
    }

    if (_showSplash) return SplashScreen(onComplete: () {});

    if (!_isCheckingLock && _isLocked) return const AppLockScreen();

    if (_isCheckingLock) {
      return DecoratedBox(
        decoration: AppTheme.appBackgroundDecoration,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Checking security...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _showExitConfirmationDialog(context);
        if (shouldExit == true) {
          await SystemNavigator.pop();
        }
      },
      child: GradientOrbBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
          bottomNavigationBar: _buildBottomNavigationBar(context),
        ),
      ),
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          content: GlassCard(
            padding: const EdgeInsets.all(24),
            borderRadius: 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.exit_to_app_rounded,
                    color: AppTheme.errorColor,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Exit Application',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to exit CareVault?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppTheme.outlineColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Exit',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
