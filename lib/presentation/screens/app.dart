import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_handler.dart';
import '../../core/themes/app_theme.dart';
import '../../core/utils/error_utils.dart';
import '../providers/reminder_provider.dart';
import '../providers/app_lock_provider.dart';
import 'dashboard_screen.dart';
import 'medicine_list_screen.dart';
import 'prescription_list_screen.dart';
import 'follow_up_list_screen.dart';
import 'timeline_screen.dart';
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
    const DashboardScreen(),
    const MedicineListScreen(),
    const PrescriptionListScreen(),
    const FollowUpListScreen(),
    const TimelineScreen(),
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
        height: 96,
        color: Colors.white,
        child: Row(
          children: [
            // Home button - selected
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(0),
                child: Container(
                  color: _selectedIndex == 0 ? AppTheme.primaryColor : Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home,
                        color: _selectedIndex == 0 ? Colors.white : AppTheme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Home',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: _selectedIndex == 0 ? Colors.white : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Medicines button
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(1),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication,
                        color: _selectedIndex == 1 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Meds',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: _selectedIndex == 1 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Prescriptions button
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(2),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description,
                        color: _selectedIndex == 2 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vault',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: _selectedIndex == 2 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Follow-ups button
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(3),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: _selectedIndex == 3 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Follow-ups',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: _selectedIndex == 3 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Timeline button
            Expanded(
              child: InkWell(
                onTap: () => _onItemTapped(4),
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        color: _selectedIndex == 4 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Timeline',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: _selectedIndex == 4 ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
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