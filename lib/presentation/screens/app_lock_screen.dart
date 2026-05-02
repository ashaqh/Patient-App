import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_lock_provider.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../../core/services/app_lock_service.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Icon and Title
                Icon(
                  Icons.lock,
                  size: 80.0,
                  color: Theme.of(context).colorScheme.primary,
                ),
                
                const SizedBox(height: 24.0),
                
                Text(
                  'CareVault is Locked',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8.0),
                
                Text(
                  _getLockTypeDescription(lockType, biometricEnabled),
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32.0),
                
                // Error message
                if (_error.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            _error,
                            style: TextStyle(color: Colors.red.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Failed attempts warning
                if (_failedAttempts >= 3)
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            'Multiple failed attempts. Please try again carefully.',
                            style: TextStyle(color: Colors.orange.shade800),
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
                
                const SizedBox(height: 24.0),
                
                // Unlock Button
                if (!_isLoading && (lockType == AppLockService.lockTypePIN || lockType == AppLockService.lockTypePassword))
                  ElderlyFriendlyButton(
                    onPressed: _unlockApp,
                    text: 'Unlock',
                    icon: Icons.lock_open,
                  ),
                
                // Loading indicator
                if (_isLoading)
                  const CircularProgressIndicator(),
                
                const SizedBox(height: 32.0),
                
                // Help/Information Section
                _buildHelpSection(lockType),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPINInput() {
    return Column(
      children: [
        TextFormField(
          controller: _pinController,
          obscureText: !_showPin,
          decoration: InputDecoration(
            labelText: 'Enter PIN',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.pin),
            suffixIcon: IconButton(
              icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showPin = !_showPin;
                });
              },
            ),
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20.0, letterSpacing: 8.0),
        ),
        
        const SizedBox(height: 8.0),
        
        TextButton(
          onPressed: () {
            // Show hint or help for PIN
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enter the 4-6 digit PIN you set in security settings'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Forgot PIN?'),
        ),
      ],
    );
  }
  
  Widget _buildPasswordInput() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Enter Password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.password),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18.0),
        ),
        
        const SizedBox(height: 8.0),
        
        TextButton(
          onPressed: () {
            // Show hint or help for password
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enter the password you set in security settings'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Forgot Password?'),
        ),
      ],
    );
  }
  
  Widget _buildBiometricButton() {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        
        ElderlyFriendlyButton(
          onPressed: _authenticateWithBiometrics,
          text: 'Unlock with Biometrics',
          icon: Icons.fingerprint,
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
        
        const SizedBox(height: 8.0),
        
        TextButton(
          onPressed: () {
            // Show alternative unlock options
            _showAlternativeOptions();
          },
          child: const Text('Use PIN/Password instead'),
        ),
      ],
    );
  }
  
  Widget _buildHelpSection(String lockType) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12.0),
            
            if (lockType == AppLockService.lockTypePIN)
              const ListTile(
                leading: Icon(Icons.info, size: 20.0),
                title: Text('Enter the 4-6 digit PIN you created'),
                dense: true,
              ),
            
            if (lockType == AppLockService.lockTypePassword)
              const ListTile(
                leading: Icon(Icons.info, size: 20.0),
                title: Text('Enter the password you created (minimum 6 characters)'),
                dense: true,
              ),
            
            if (lockType == AppLockService.lockTypeBiometric)
              const ListTile(
                leading: Icon(Icons.info, size: 20.0),
                title: Text('Use your fingerprint or face to unlock the app'),
                dense: true,
              ),
            
            const ListTile(
              leading: Icon(Icons.timer, size: 20.0),
              title: Text('App auto-locks based on your security settings'),
              dense: true,
            ),
            
            const ListTile(
              leading: Icon(Icons.settings, size: 20.0),
              title: Text('You can change security settings after unlocking'),
              dense: true,
            ),
            
            const SizedBox(height: 16.0),
            
            TextButton(
              onPressed: () {
                // Navigate to security settings help
                _showSecurityHelp();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.help_outline),
                  SizedBox(width: 8.0),
                  Text('Learn more about security settings'),
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('Use PIN'),
              onTap: () {
                Navigator.pop(context, 'pin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Use Password'),
              onTap: () {
                Navigator.pop(context, 'password');
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    
    if (result == 'pin' || result == 'password') {
      // In a real implementation, you would switch the input type
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switch to ${result == 'pin' ? 'PIN' : 'password'} input'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _showSecurityHelp() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'App Lock Settings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text('• PIN: 4-6 digit numeric code'),
              Text('• Password: At least 6 characters'),
              Text('• Biometric: Fingerprint or Face ID'),
              SizedBox(height: 16.0),
              Text(
                'Auto-Lock Timeout:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text('• Sets how long the app stays unlocked'),
              Text('• Options: Immediate to Never'),
              SizedBox(height: 16.0),
              Text(
                'Security Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text('• Use a strong, unique PIN/password'),
              Text('• Enable biometrics for convenience'),
              Text('• Set appropriate auto-lock timeout'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}