import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_lock_provider.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../../core/services/app_lock_service.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  
  bool _showPin = false;
  bool _showPassword = false;
  bool _showConfirmPin = false;
  bool _showConfirmPassword = false;
  bool _showOldPin = false;
  bool _showOldPassword = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final notifier = ref.read(appLockNotifierProvider.notifier);
    await notifier.loadSettings();
  }
  
  @override
  void dispose() {
    _pinController.dispose();
    _passwordController.dispose();
    _confirmPinController.dispose();
    _confirmPasswordController.dispose();
    _oldPinController.dispose();
    _oldPasswordController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final appLockState = ref.watch(appLockNotifierProvider);
    final notifier = ref.read(appLockNotifierProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loading state
            if (appLockState.isLoading)
              const Center(child: CircularProgressIndicator()),
            
            // Error message
            if (appLockState.error != null)
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
                        appLockState.error!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: Colors.red,
                      onPressed: () => notifier.clearError(),
                    ),
                  ],
                ),
              ),
            
            // App Lock Section
            _buildAppLockSection(appLockState, notifier),
            
            const SizedBox(height: 24.0),
            
            // Encryption Status Section
            _buildEncryptionSection(appLockState),
            
            const SizedBox(height: 24.0),
            
            // Timeout Settings Section
            _buildTimeoutSection(appLockState, notifier),
            
            const SizedBox(height: 24.0),
            
            // Biometric Settings Section
            _buildBiometricSection(appLockState, notifier),
            
            const SizedBox(height: 24.0),
            
            // Reset Section
            _buildResetSection(notifier),
            
            const SizedBox(height: 32.0),
            
            // Security Tips
            _buildSecurityTips(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppLockSection(AppLockState state, AppLockNotifier notifier) {
    final isLockEnabled = state.settings?['enabled'] == true;
    final lockType = state.settings?['type'] ?? 'none';
    final hasPIN = state.settings?['has_pin'] == true;
    final hasPassword = state.settings?['has_password'] == true;
    
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, size: 24.0),
                const SizedBox(width: 12.0),
                const Text(
                  'App Lock',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: isLockEnabled,
                  onChanged: (value) {
                    if (value) {
                      _showLockTypeDialog(notifier);
                    } else {
                      _showDisableLockDialog(notifier);
                    }
                  },
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            if (isLockEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current lock type: ${_getLockTypeDisplayName(lockType)}',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  if (lockType == AppLockService.lockTypePIN && hasPIN)
                    _buildChangePINSection(notifier),
                  
                  if (lockType == AppLockService.lockTypePassword && hasPassword)
                    _buildChangePasswordSection(notifier),
                  
                  if (lockType == AppLockService.lockTypeBiometric)
                    _buildBiometricInfoSection(state),
                ],
              )
            else
              const Text(
                'App lock is disabled. Enable it to secure your medical data.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEncryptionSection(AppLockState state) {
    final encryptionStatus = state.settings?['biometric_status']?['available'] ?? false;
    final algorithm = state.settings?['algorithm'] ?? 'AES-256-CBC';
    
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.enhanced_encryption, size: 24.0),
                const SizedBox(width: 12.0),
                const Text(
                  'Encryption',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            ListTile(
              leading: Icon(
                encryptionStatus ? Icons.check_circle : Icons.error,
                color: encryptionStatus ? Colors.green : Colors.orange,
              ),
              title: const Text('Data Encryption'),
              subtitle: Text(
                encryptionStatus 
                  ? 'Your data is encrypted using $algorithm'
                  : 'Encryption may not be fully available on this device',
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Secure Storage'),
              subtitle: const Text('Sensitive data is stored in encrypted format'),
            ),
            
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('Encryption Keys'),
              subtitle: const Text('Keys are securely stored in device keychain'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeoutSection(AppLockState state, AppLockNotifier notifier) {
    final currentTimeout = state.settings?['timeout'] ?? 0;
    final timeoutOptions = AppLockService.timeoutOptions;
    
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, size: 24.0),
                const SizedBox(width: 12.0),
                const Text(
                  'Auto-Lock Timeout',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            const Text(
              'Set how long the app stays unlocked after you close it:',
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 16.0),
            
            DropdownButtonFormField<String>(
              value: _getTimeoutKeyFromValue(currentTimeout),
              decoration: const InputDecoration(
                labelText: 'Lock after',
                border: OutlineInputBorder(),
              ),
              items: timeoutOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(notifier.getTimeoutDisplayName(entry.value)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  notifier.setTimeout(timeoutOptions[value]!);
                }
              },
            ),
            
            const SizedBox(height: 8.0),
            
            Text(
              'Current setting: ${notifier.getTimeoutDisplayName(currentTimeout)}',
              style: TextStyle(
                fontSize: 14.0,
                color: Theme.of(context).colorScheme.secondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBiometricSection(AppLockState state, AppLockNotifier notifier) {
    final biometricStatus = state.settings?['biometric_status'] ?? {};
    final hasBiometric = biometricStatus['has_biometric'] == true;
    final biometricEnabled = state.settings?['biometric_enabled'] == true;
    final availableBiometrics = biometricStatus['available_biometrics'] ?? [];
    
    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fingerprint, size: 24.0),
                const SizedBox(width: 12.0),
                const Text(
                  'Biometric Authentication',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            if (!hasBiometric)
              const ListTile(
                leading: Icon(Icons.error_outline, color: Colors.orange),
                title: Text('Biometric Not Available'),
                subtitle: Text('Your device does not support biometric authentication'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Icon(
                      biometricEnabled ? Icons.check_circle : Icons.circle_outlined,
                      color: biometricEnabled ? Colors.green : Colors.grey,
                    ),
                    title: const Text('Enable Biometric Authentication'),
                    subtitle: Text(
                      availableBiometrics.isNotEmpty
                        ? 'Available: ${availableBiometrics.join(', ')}'
                        : 'No biometric methods available',
                    ),
                    trailing: Switch(
                      value: biometricEnabled,
                      onChanged: (value) {
                        if (value) {
                          _enableBiometric(notifier);
                        } else {
                          _disableBiometric(notifier);
                        }
                      },
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  
                  if (biometricEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8.0),
                          const Text(
                            'Biometric authentication will be used as the primary unlock method.',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey),
                          ),
                          const SizedBox(height: 8.0),
                          ElderlyFriendlyButton(
                            onPressed: () => _testBiometric(notifier),
                            text: 'Test Biometric Authentication',
                            icon: Icons.fingerprint,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBiometricInfoSection(AppLockState state) {
    final biometricStatus = state.settings?['biometric_status'] ?? {};
    final availableBiometrics = biometricStatus['available_biometrics'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8.0),
        Text(
          'Biometric authentication is enabled.',
          style: TextStyle(color: Colors.green.shade700),
        ),
        if (availableBiometrics.isNotEmpty)
          Text(
            'Available methods: ${availableBiometrics.join(', ')}',
            style: const TextStyle(fontSize: 14.0, color: Colors.grey),
          ),
      ],
    );
  }
  
  Widget _buildChangePINSection(AppLockNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        const Text(
          'Change PIN',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8.0),
        
        TextFormField(
          controller: _oldPinController,
          obscureText: !_showOldPin,
          decoration: InputDecoration(
            labelText: 'Current PIN',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_showOldPin ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showOldPin = !_showOldPin;
                });
              },
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 12.0),
        
        TextFormField(
          controller: _pinController,
          obscureText: !_showPin,
          decoration: InputDecoration(
            labelText: 'New PIN (4-6 digits)',
            border: const OutlineInputBorder(),
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
        ),
        
        const SizedBox(height: 12.0),
        
        TextFormField(
          controller: _confirmPinController,
          obscureText: !_showConfirmPin,
          decoration: InputDecoration(
            labelText: 'Confirm New PIN',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_showConfirmPin ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showConfirmPin = !_showConfirmPin;
                });
              },
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 16.0),
        
        ElderlyFriendlyButton(
          onPressed: () => _changePIN(notifier),
          text: 'Change PIN',
          icon: Icons.lock_reset,
        ),
      ],
    );
  }
  
  Widget _buildChangePasswordSection(AppLockNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        const Text(
          'Change Password',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8.0),
        
        TextFormField(
          controller: _oldPasswordController,
          obscureText: !_showOldPassword,
          decoration: InputDecoration(
            labelText: 'Current Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_showOldPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showOldPassword = !_showOldPassword;
                });
              },
            ),
          ),
        ),
        
        const SizedBox(height: 12.0),
        
        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'New Password (min. 6 characters)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
            ),
          ),
        ),
        
        const SizedBox(height: 12.0),
        
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                setState(() {
                  _showConfirmPassword = !_showConfirmPassword;
                });
              },
            ),
          ),
        ),
        
        const SizedBox(height: 16.0),
        
        ElderlyFriendlyButton(
          onPressed: () => _changePassword(notifier),
          text: 'Change Password',
          icon: Icons.lock_reset,
        ),
      ],
    );
  }
  
  Widget _buildResetSection(AppLockNotifier notifier) {
    return Card(
      elevation: 4.0,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, size: 24.0, color: Colors.red),
                const SizedBox(width: 12.0),
                const Text(
                  'Reset Security Settings',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            const Text(
              'Warning: This will remove all security settings including PIN, password, and biometric settings.',
              style: TextStyle(color: Colors.red),
            ),
            
            const SizedBox(height: 16.0),
            
            ElderlyFriendlyButton(
              onPressed: () => _showResetConfirmationDialog(notifier),
              text: 'Reset All Security Settings',
              icon: Icons.restart_alt,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecurityTips() {
    return Card(
      elevation: 4.0,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security, size: 24.0, color: Colors.blue),
                const SizedBox(width: 12.0),
                const Text(
                  'Security Tips',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12.0),
            
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green, size: 20.0),
              title: Text('Use a strong, unique PIN or password'),
              dense: true,
            ),
            
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green, size: 20.0),
              title: Text('Enable biometric authentication if available'),
              dense: true,
            ),
            
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green, size: 20.0),
              title: Text('Set auto-lock timeout for added security'),
              dense: true,
            ),
            
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green, size: 20.0),
              title: Text('Keep your device operating system updated'),
              dense: true,
            ),
            
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green, size: 20.0),
              title: Text('Don\'t share your PIN or password with others'),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  String _getLockTypeDisplayName(String type) {
    switch (type) {
      case AppLockService.lockTypePIN:
        return 'PIN';
      case AppLockService.lockTypePassword:
        return 'Password';
      case AppLockService.lockTypeBiometric:
        return 'Biometric';
      default:
        return 'None';
    }
  }
  
  String _getTimeoutKeyFromValue(int value) {
    for (final entry in AppLockService.timeoutOptions.entries) {
      if (entry.value == value) {
        return entry.key;
      }
    }
    return 'immediate';
  }
  
  // Dialog methods
  Future<void> _showLockTypeDialog(AppLockNotifier notifier) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Lock Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pin),
              title: const Text('PIN'),
              subtitle: const Text('4-6 digit numeric code'),
              onTap: () => Navigator.pop(context, AppLockService.lockTypePIN),
            ),
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Password'),
              subtitle: const Text('At least 6 characters'),
              onTap: () => Navigator.pop(context, AppLockService.lockTypePassword),
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint),
              title: const Text('Biometric'),
              subtitle: const Text('Fingerprint or Face ID'),
              onTap: () => Navigator.pop(context, AppLockService.lockTypeBiometric),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      if (result == AppLockService.lockTypePIN) {
        _showSetPINDialog(notifier);
      } else if (result == AppLockService.lockTypePassword) {
        _showSetPasswordDialog(notifier);
      } else if (result == AppLockService.lockTypeBiometric) {
        _enableBiometric(notifier);
      }
    }
  }
  
  Future<void> _showSetPINDialog(AppLockNotifier notifier) async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    bool showPin = false;
    bool showConfirmPin = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set PIN'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: pinController,
                  obscureText: !showPin,
                  decoration: InputDecoration(
                    labelText: 'Enter PIN (4-6 digits)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showPin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          showPin = !showPin;
                        });
                      },
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: confirmPinController,
                  obscureText: !showConfirmPin,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirmPin ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          showConfirmPin = !showConfirmPin;
                        });
                      },
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (pinController.text.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN must be at least 4 digits')),
                    );
                    return;
                  }
                  
                  if (pinController.text != confirmPinController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PINs do not match')),
                    );
                    return;
                  }
                  
                  final success = await notifier.enablePIN(pinController.text);
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN set successfully')),
                    );
                  }
                },
                child: const Text('Set PIN'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _showSetPasswordDialog(AppLockNotifier notifier) async {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showPassword = false;
    bool showConfirmPassword = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Enter Password (min. 6 characters)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          showConfirmPassword = !showConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (passwordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password must be at least 6 characters')),
                    );
                    return;
                  }
                  
                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Passwords do not match')),
                    );
                    return;
                  }
                  
                  final success = await notifier.enablePassword(passwordController.text);
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password set successfully')),
                    );
                  }
                },
                child: const Text('Set Password'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _showDisableLockDialog(AppLockNotifier notifier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable App Lock'),
        content: const Text('Are you sure you want to disable app lock? This will remove all security settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await notifier.disableLock();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App lock disabled')),
        );
      }
    }
  }
  
  Future<void> _showResetConfirmationDialog(AppLockNotifier notifier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Security Settings'),
        content: const Text('This will remove all security settings including PIN, password, and biometric settings. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      // This would require implementing a reset method in AppLockService
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset functionality to be implemented')),
      );
    }
  }
  
  // Action methods
  Future<void> _enableBiometric(AppLockNotifier notifier) async {
    final success = await notifier.enableBiometric();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication enabled')),
      );
    }
  }
  
  Future<void> _disableBiometric(AppLockNotifier notifier) async {
    // For now, just disable the entire lock
    final success = await notifier.disableLock();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication disabled')),
      );
    }
  }
  
  Future<void> _testBiometric(AppLockNotifier notifier) async {
    final success = await notifier.authenticateWithBiometrics();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication successful')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric authentication failed')),
      );
    }
  }
  
  Future<void> _changePIN(AppLockNotifier notifier) async {
    if (_oldPinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter current PIN')),
      );
      return;
    }
    
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN must be at least 4 digits')),
      );
      return;
    }
    
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }
    
    final success = await notifier.changePIN(_oldPinController.text, _pinController.text);
    if (success) {
      _oldPinController.clear();
      _pinController.clear();
      _confirmPinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN changed successfully')),
      );
    }
  }
  
  Future<void> _changePassword(AppLockNotifier notifier) async {
    if (_oldPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter current password')),
      );
      return;
    }
    
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters')),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    
    final success = await notifier.changePassword(
      _oldPasswordController.text,
      _passwordController.text,
    );
    
    if (success) {
      _oldPasswordController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    }
  }
}