import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_lock_provider.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../../core/services/app_lock_service.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _showPin = false;
  bool _showPassword = false;
  bool _isLoading = false;
  String _error = '';
  int _failedAttempts = 0;
  
  @override
  void initState() {
    super.initState();
    _checkBiometricOnStart();
  }
  
  Future<void> _checkBiometricOnStart() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final appLockState = ref.read(appLockNotifierProvider);
    final lockType = appLockState.settings?['type'] ?? 'none';
    final biometricEnabled = appLockState.settings?['biometric_enabled'] == true;
    
    if (lockType == AppLockService.lockTypeBiometric && biometricEnabled) {
      _authenticateWithBiometrics();
    }
  }
  
  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final appLockState = ref.watch(appLockNotifierProvider);
    final lockType = appLockState.settings?['type'] ?? 'none';
    final biometricEnabled = appLockState.settings?['biometric_enabled'] == true;
    
    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      body: SafeArea(
        child: Center(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Icon and Title
                      Container(
                        width: AppSpacing.iconSizeLarge * 2,
                        height: AppSpacing.iconSizeLarge * 2,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
                        ),
                        child: Icon(
                          Icons.lock,
                          size: AppSpacing.iconSizeLarge,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      Text(
                        'CareVault is Locked',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.onSurfaceColor,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.s),
                      
                      Text(
                        _getLockTypeDescription(lockType, biometricEnabled),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.neutralColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Error message
                      if (_error.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          margin: const EdgeInsets.only(bottom: AppSpacing.l),
                          decoration: BoxDecoration(
                            color: AppTheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                            border: Border.all(color: AppTheme.errorColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: AppTheme.errorColor),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Failed attempts warning
                      if (_failedAttempts >= 3)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          margin: const EdgeInsets.only(bottom: AppSpacing.l),
                          decoration: BoxDecoration(
                            color: AppTheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                            border: Border.all(color: AppTheme.errorColor),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: AppTheme.errorColor),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: Text(
                                  'Multiple failed attempts. Please try again carefully.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // PIN Input (if lock type is PIN)
                      if (lockType == AppLockService.lockTypePIN)
                        _buildPINInput(),
                      
                      // Password Input (if lock type is Password)
                      if (lockType == AppLockService.lockTypePassword)
                        _buildPasswordInput(),
                      
                      // Biometric Authentication Button
                      if (biometricEnabled && lockType != AppLockService.lockTypeBiometric)
                        _buildBiometricButton(),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Unlock Button
                      if (!_isLoading && (lockType == AppLockService.lockTypePIN || lockType == AppLockService.lockTypePassword))
                        ElderlyFriendlyButton(
                          onPressed: _unlockApp,
                          text: 'Unlock',
                          icon: Icons.lock_open,
                          backgroundColor: AppTheme.primaryColor,
                          textColor: AppTheme.onPrimaryColor,
                        ),
                      
                      // Loading indicator
                      if (_isLoading)
                        const CircularProgressIndicator(),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Help/Information Section
                      _buildHelpSection(lockType),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPINInput() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            border: Border.all(width: 2, color: AppTheme.outlineColor),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _pinController,
                obscureText: !_showPin,
                decoration: InputDecoration(
                  labelText: 'Enter PIN',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.pin, color: AppTheme.neutralColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPin ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.neutralColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPin = !_showPin;
                      });
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  letterSpacing: 8.0,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.m),
        
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Enter the 4-6 digit PIN you set in security settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Text(
            'Forgot PIN?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPasswordInput() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            border: Border.all(width: 2, color: AppTheme.outlineColor),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Enter Password',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.password, color: AppTheme.neutralColor),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.neutralColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                  ),
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.m),
        
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Enter the password you set in security settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppTheme.primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBiometricButton() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.l),
        
        ElderlyFriendlyButton(
          onPressed: _authenticateWithBiometrics,
          text: 'Unlock with Biometrics',
          icon: Icons.fingerprint,
          backgroundColor: AppTheme.primaryColor,
          textColor: AppTheme.onPrimaryColor,
        ),
        
        const SizedBox(height: AppSpacing.m),
        
        TextButton(
          onPressed: () {
            _showAlternativeOptions();
          },
          child: Text(
            'Use PIN/Password instead',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHelpSection(String lockType) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        side: const BorderSide(width: 1, color: AppTheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Need Help?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
              ),
            ),
            
            const SizedBox(height: AppSpacing.m),
            
            Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
              ),
              child: Column(
                children: [
                  if (lockType == AppLockService.lockTypePIN)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                      leading: Icon(
                        Icons.info,
                        size: AppSpacing.iconSizeSmall,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        'Enter the 4-6 digit PIN you created',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceColor,
                        ),
                      ),
                      dense: true,
                    ),
                  
                  if (lockType == AppLockService.lockTypePIN && lockType == AppLockService.lockTypePassword)
                    Divider(
                      height: 1,
                      color: AppTheme.outlineVariant,
                      thickness: 1,
                    ),
                  
                  if (lockType == AppLockService.lockTypePassword)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                      leading: Icon(
                        Icons.info,
                        size: AppSpacing.iconSizeSmall,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        'Enter the password you created (minimum 6 characters)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceColor,
                        ),
                      ),
                      dense: true,
                    ),
                  
                  if ((lockType == AppLockService.lockTypePIN || lockType == AppLockService.lockTypePassword) && lockType == AppLockService.lockTypeBiometric)
                    Divider(
                      height: 1,
                      color: AppTheme.outlineVariant,
                      thickness: 1,
                    ),
                  
                  if (lockType == AppLockService.lockTypeBiometric)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                      leading: Icon(
                        Icons.info,
                        size: AppSpacing.iconSizeSmall,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        'Use your fingerprint or face to unlock the app',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceColor,
                        ),
                      ),
                      dense: true,
                    ),
                  
                  Divider(
                    height: 1,
                    color: AppTheme.outlineVariant,
                    thickness: 1,
                  ),
                  
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    leading: Icon(
                      Icons.timer,
                      size: AppSpacing.iconSizeSmall,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'App auto-locks based on your security settings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    dense: true,
                  ),
                  
                  Divider(
                    height: 1,
                    color: AppTheme.outlineVariant,
                    thickness: 1,
                  ),
                  
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    leading: Icon(
                      Icons.settings,
                      size: AppSpacing.iconSizeSmall,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(
                      'You can change security settings after unlocking',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    dense: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppSpacing.l),
            
            TextButton(
              onPressed: () {
                _showSecurityHelp();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.help_outline,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    'Learn more about security settings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  String _getLockTypeDescription(String lockType, bool biometricEnabled) {
    switch (lockType) {
      case AppLockService.lockTypePIN:
        return 'Enter your PIN to unlock the app';
      case AppLockService.lockTypePassword:
        return 'Enter your password to unlock the app';
      case AppLockService.lockTypeBiometric:
        if (biometricEnabled) {
          return 'Use biometric authentication to unlock';
        }
        return 'App is locked';
      default:
        return 'App is locked';
    }
  }
  
  // Action methods
  Future<void> _unlockApp() async {
    final notifier = ref.read(appLockNotifierProvider.notifier);
    final lockType = ref.read(appLockNotifierProvider).settings?['type'] ?? 'none';
    
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    bool success = false;
    
    try {
      if (lockType == AppLockService.lockTypePIN) {
        if (_pinController.text.isEmpty) {
          throw Exception('Please enter PIN');
        }
        success = await notifier.verifyPIN(_pinController.text);
      } else if (lockType == AppLockService.lockTypePassword) {
        if (_passwordController.text.isEmpty) {
          throw Exception('Please enter password');
        }
        success = await notifier.verifyPassword(_passwordController.text);
      }
      
      if (success) {
        setState(() {
          _failedAttempts = 0;
          _pinController.clear();
          _passwordController.clear();
        });
        
        // The app will automatically navigate away since isLocked will be false
      } else {
        setState(() {
          _failedAttempts++;
          _error = 'Incorrect ${lockType == AppLockService.lockTypePIN ? 'PIN' : 'password'}. Please try again.';
          
          if (_failedAttempts >= 5) {
            _error = 'Too many failed attempts. Please wait before trying again.';
            // Could implement a timeout here
          }
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _authenticateWithBiometrics() async {
    final notifier = ref.read(appLockNotifierProvider.notifier);
    
    setState(() {
      _isLoading = true;
      _error = '';
    });
    
    try {
      final success = await notifier.authenticateWithBiometrics();
      
      if (success) {
        setState(() {
          _failedAttempts = 0;
        });
        
        // The app will automatically navigate away since isLocked will be false
      } else {
        setState(() {
          _failedAttempts++;
          _error = 'Biometric authentication failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error during biometric authentication: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showAlternativeOptions() async {
    final result = await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.borderRadiusLarge),
          topRight: Radius.circular(AppSpacing.borderRadiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Alternative Unlock Methods',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: AppTheme.neutralColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.pin,
                color: AppTheme.primaryColor,
                size: AppSpacing.iconSizeMedium,
              ),
              title: Text(
                'Use PIN',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context, 'pin');
              },
            ),
            Divider(
              height: 1,
              color: AppTheme.outlineVariant,
              thickness: 1,
            ),
            ListTile(
              leading: Icon(
                Icons.password,
                color: AppTheme.primaryColor,
                size: AppSpacing.iconSizeMedium,
              ),
              title: Text(
                'Use Password',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
              onTap: () {
                Navigator.pop(context, 'password');
              },
            ),
            Divider(
              height: 1,
              color: AppTheme.outlineVariant,
              thickness: 1,
            ),
            ListTile(
              leading: Icon(
                Icons.cancel,
                color: AppTheme.neutralColor,
                size: AppSpacing.iconSizeMedium,
              ),
              title: Text(
                'Cancel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
    
    if (result == 'pin' || result == 'password') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Switch to ${result == 'pin' ? 'PIN' : 'password'} input',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _showSecurityHelp() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
        ),
        title: Text(
          'Security Settings Help',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'App Lock Settings:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                '• PIN: 4-6 digit numeric code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
              Text(
                '• Password: At least 6 characters',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
              Text(
                '• Biometric: Fingerprint or Face ID',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Auto-Lock Timeout:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                '• Sets how long the app stays unlocked',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
              Text(
                '• Options: Immediate to Never',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                'Security Tips:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                '• Use a strong, unique PIN/password',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
              Text(
                '• Enable biometrics for convenience',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
              Text(
                '• Set appropriate auto-lock timeout',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.neutralColor,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}