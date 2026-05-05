import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_handler.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/utils/error_utils.dart';
import '../providers/reminder_provider.dart';
import '../providers/app_lock_provider.dart';
import 'dashboard_screen_new.dart';
import 'medicine_list_screen_new.dart';
import 'prescription_list_screen_new.dart';
import 'follow_up_list_screen_new.dart';
import 'timeline_screen.dart';
import 'vital_sign_list_screen.dart';
import 'app_lock_screen.dart';

class App extends ConsumerWidget {
  final NotificationHandler? notificationHandler;
  
  const App({super.key, this.notificationHandler});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize reminder scheduler when app starts
    ref.read(reminderSchedulerInitializerProvider);
    
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
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isLocked = false;
  bool _isCheckingLock = true;

  static final List<Widget> _widgetOptions = <Widget>[
    const DashboardScreenNew(),
    const MedicineListScreenNew(),
    const PrescriptionListScreenNew(),
    const FollowUpListScreenNew(),
    const TimelineScreen(),
    const VitalSignListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Use post-frame callback with a small delay to ensure everything is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkAppLock();
      });
    });
  }

  Future<void> _checkAppLock() async {
    try {
      final notifier = ref.read(appLockNotifierProvider.notifier);
      
      // Add timeout to prevent hanging (3 seconds is enough)
      final result = await Future.any([
        Future(() async {
          await notifier.loadSettings();
          await notifier.checkLockStatus();
          return true;
        }),
        Future.delayed(const Duration(seconds: 3), () => false)
      ]);
      
      if (result == false) {
        // Timeout occurred - assume not locked and proceed
        ErrorUtils.logInfo('App lock check timeout - proceeding without lock');
        if (mounted) {
          setState(() {
            _isCheckingLock = false;
            _isLocked = false;
          });
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _isCheckingLock = false;
          _isLocked = ref.read(appLockNotifierProvider).isLocked;
        });
      }
    } catch (e) {
      // If there's an error checking lock, assume not locked and proceed
      ErrorUtils.logInfo('Error checking app lock: $e - proceeding without lock');
      if (mounted) {
        setState(() {
          _isCheckingLock = false;
          _isLocked = false;
        });
      }
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _selectedIndex == index;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          splashColor: AppTheme.primaryColor.withOpacity(0.1),
          highlightColor: AppTheme.primaryColor.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppTheme.primaryColor : AppTheme.neutralColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isActive ? AppTheme.primaryColor : AppTheme.neutralColor,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLockState = ref.watch(appLockNotifierProvider);
    
    // Check if lock status changed
    if (!_isCheckingLock && _isLocked != appLockState.isLocked) {
      setState(() {
        _isLocked = appLockState.isLocked;
      });
    }

    // Show app lock screen if locked
    if (_isLocked) {
      return const AppLockScreen();
    }

    // Show loading while checking lock status
    if (_isCheckingLock) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Checking security...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
bottomNavigationBar: Container(
        height: 80 + MediaQuery.of(context).viewPadding.bottom,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            top: BorderSide(
              width: 1,
              color: AppTheme.outlineVariant,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildNavItem(
              context,
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
            ),
            _buildNavItem(
              context,
              index: 1,
              icon: Icons.medication_outlined,
              activeIcon: Icons.medication,
              label: 'Meds',
            ),
            _buildNavItem(
              context,
              index: 2,
              icon: Icons.description_outlined,
              activeIcon: Icons.description,
              label: 'Vault',
            ),
            _buildNavItem(
              context,
              index: 3,
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              label: 'Follow-ups',
            ),
            _buildNavItem(
              context,
              index: 4,
              icon: Icons.history_outlined,
              activeIcon: Icons.history,
              label: 'Timeline',
            ),
            _buildNavItem(
              context,
              index: 5,
              icon: Icons.monitor_heart_outlined,
              activeIcon: Icons.monitor_heart,
              label: 'Vitals',
            ),
          ],
        ),
      ),
    );
  }
}
