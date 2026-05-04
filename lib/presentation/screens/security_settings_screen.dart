import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_lock_provider.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../../core/services/app_lock_service.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';

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
      backgroundColor: AppTheme.secondaryColor,
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Loading state
                if (appLockState.isLoading)
                  const Center(child: CircularProgressIndicator()),
                
                // Error message
                if (appLockState.error != null)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: AppSpacing.l),
                    decoration: BoxDecoration(
                      color: AppTheme.errorContainer,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppTheme.errorColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.errorColor),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Text(
                            appLockState.error!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppTheme.errorColor),
                          onPressed: () => notifier.clearError(),
                        ),
                      ],
                    ),
                  ),
                
                // App Lock Section
                _buildAppLockSection(appLockState, notifier),
                
                const SizedBox(height: AppSpacing.l),
                
                // Encryption Status Section
                _buildEncryptionSection(appLockState),
                
                const SizedBox(height: AppSpacing.l),
                
                // Timeout Settings Section
                _buildTimeoutSection(appLockState, notifier),
                
                const SizedBox(height: AppSpacing.l),
                
                // Biometric Settings Section
                _buildBiometricSection(appLockState, notifier),
                
                const SizedBox(height: AppSpacing.l),
                
                // Reset Section
                _buildResetSection(notifier),
                
                const SizedBox(height: AppSpacing.l),
                
                // Security Tips
                _buildSecurityTips(),
                
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppLockSection(AppLockState state, AppLockNotifier notifier) {
    final isLockEnabled = state.settings?['enabled'] == true;
    final lockType = state.settings?['type'] ?? 'none';
    final hasPIN = state.settings?['has_pin'] == true;
    final hasPassword = state.settings?['has_password'] == true;
    
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
            Row(
              children: [
                Icon(
                  Icons.lock,
                  size: AppSpacing.iconSizeMedium,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  'App Lock',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
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
                  activeThumbColor: AppTheme.primaryColor,
                  activeTrackColor: AppTheme.primaryColor.withAlpha((0.5 * 255).round()),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.m),
            
            if (isLockEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: AppSpacing.iconSizeSmall,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Text(
                          'Current lock type: ${_getLockTypeDisplayName(lockType)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.l),
                  
                  if (lockType == AppLockService.lockTypePIN && hasPIN)
                    _buildChangePINSection(notifier),
                  
                  if (lockType == AppLockService.lockTypePassword && hasPassword)
                    _buildChangePasswordSection(notifier),
                  
                  if (lockType == AppLockService.lockTypeBiometric)
                    _buildBiometricInfoSection(state),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: AppSpacing.iconSizeSmall,
                      color: AppTheme.neutralColor,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'App lock is disabled. Enable it to secure your medical data.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.neutralColor,
                        ),
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
  
  Widget _buildEncryptionSection(AppLockState state) {
    final encryptionStatus = state.settings?['biometric_status']?['available'] ?? false;
    final algorithm = state.settings?['algorithm'] ?? 'AES-256-CBC';
    
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
            Row(
              children: [
                Icon(
                  Icons.enhanced_encryption,
                  size: AppSpacing.iconSizeMedium,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  'Encryption',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.m),
            
            Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    leading: Icon(
                      encryptionStatus ? Icons.check_circle : Icons.error_outline,
                      color: encryptionStatus ? AppTheme.primaryColor : AppTheme.errorColor,
                      size: AppSpacing.iconSizeMedium,
                    ),
                    title: Text(
                      'Data Encryption',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    subtitle: Text(
                      encryptionStatus 
                        ? 'Your data is encrypted using $algorithm'
                        : 'Encryption may not be fully available on this device',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutralColor,
                      ),
                    ),
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
                      Icons.storage,
                      color: AppTheme.primaryColor,
                      size: AppSpacing.iconSizeMedium,
                    ),
                    title: Text(
                      'Secure Storage',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    subtitle: Text(
                      'Sensitive data is stored in encrypted format',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutralColor,
                      ),
                    ),
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
                      Icons.vpn_key,
                      color: AppTheme.primaryColor,
                      size: AppSpacing.iconSizeMedium,
                    ),
                    title: Text(
                      'Encryption Keys',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    subtitle: Text(
                      'Keys are securely stored in device keychain',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutralColor,
                      ),
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
  
  Widget _buildTimeoutSection(AppLockState state, AppLockNotifier notifier) {
    final currentTimeout = state.settings?['timeout'] ?? 0;
    final timeoutOptions = AppLockService.timeoutOptions;
    
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
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: AppSpacing.iconSizeMedium,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  'Auto-Lock Timeout',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.m),
            
            Text(
              'Set how long the app stays unlocked after you close it:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutralColor,
              ),
            ),
            
            const SizedBox(height: AppSpacing.l),
            
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _getTimeoutKeyFromValue(currentTimeout),
                    decoration: InputDecoration(
                      labelText: 'Lock after',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        borderSide: const BorderSide(width: 2, color: AppTheme.outlineColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        borderSide: const BorderSide(width: 2, color: AppTheme.outlineColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        borderSide: const BorderSide(width: 2, color: AppTheme.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.l,
                      ),
                      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.neutralColor,
                      ),
                    ),
                    items: timeoutOptions.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(
                          notifier.getTimeoutDisplayName(entry.value),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceColor,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        notifier.setTimeout(timeoutOptions[value]!);
                      }
                    },
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceColor,
                    ),
                  ),
                  
                  const SizedBox(height: AppSpacing.m),
                  
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: AppSpacing.iconSizeSmall,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Text(
                            'Current setting: ${notifier.getTimeoutDisplayName(currentTimeout)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
  
  Widget _buildBiometricSection(AppLockState state, AppLockNotifier notifier) {
    final biometricStatus = state.settings?['biometric_status'] ?? {};
    final hasBiometric = biometricStatus['has_biometric'] == true;
    final biometricEnabled = state.settings?['biometric_enabled'] == true;
    final availableBiometrics = biometricStatus['available_biometrics'] ?? [];
    
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
            Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  size: AppSpacing.iconSizeMedium,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  'Biometric Authentication',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.m),
            
            if (!hasBiometric)
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                  border: Border.all(width: 1, color: AppTheme.errorColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: AppSpacing.iconSizeMedium,
                      color: AppTheme.errorColor,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biometric Not Available',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.errorColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Your device does not support biometric authentication',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutralColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.s,
                          ),
                          leading: Icon(
                            biometricEnabled ? Icons.check_circle : Icons.circle_outlined,
                            color: biometricEnabled ? AppTheme.primaryColor : AppTheme.neutralColor,
                            size: AppSpacing.iconSizeMedium,
                          ),
                          title: Text(
                            'Enable Biometric Authentication',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.onSurfaceColor,
                            ),
                          ),
                          subtitle: Text(
                            availableBiometrics.isNotEmpty
                              ? 'Available: ${availableBiometrics.join(', ')}'
                              : 'No biometric methods available',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.neutralColor,
                            ),
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
                            activeThumbColor: AppTheme.primaryColor,
activeTrackColor: AppTheme.primaryColor.withAlpha((0.5 * 255).round()),
                          ),
                        ),
                        
                        if (biometricEnabled)
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.m),
decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                    ),
                                  child: Text(
                                    'Biometric authentication will be used as the primary unlock method.',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.m),
                                ElderlyFriendlyButton(
                                  onPressed: () => _testBiometric(notifier),
                                  text: 'Test Biometric Authentication',
                                  icon: Icons.fingerprint,
                                  backgroundColor: AppTheme.primaryColor,
                                  textColor: AppTheme.onPrimaryColor,
                                ),
                              ],
                            ),
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
        const SizedBox(height: AppSpacing.m),
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            border: Border.all(width: 1, color: AppTheme.primaryColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: AppSpacing.iconSizeSmall,
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Text(
                    'Biometric authentication is enabled.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (availableBiometrics.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  'Available methods: ${availableBiometrics.join(', ')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutralColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildChangePINSection(AppLockNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.l),
        Text(
          'Change PIN',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _oldPinController,
                obscureText: !_showOldPin,
                decoration: InputDecoration(
                  labelText: 'Current PIN',
                  prefixIcon: Icon(Icons.pin, color: AppTheme.neutralColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showOldPin ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.neutralColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showOldPin = !_showOldPin;
                      });
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
              
              const SizedBox(height: AppSpacing.m),
              
              TextFormField(
                controller: _pinController,
                obscureText: !_showPin,
                decoration: InputDecoration(
                  labelText: 'New PIN (4-6 digits)',
                  prefixIcon: Icon(Icons.pin_outlined, color: AppTheme.neutralColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
              
              const SizedBox(height: AppSpacing.m),
              
              TextFormField(
                controller: _confirmPinController,
                obscureText: !_showConfirmPin,
                decoration: InputDecoration(
                  labelText: 'Confirm New PIN',
                  prefixIcon: Icon(Icons.pin, color: AppTheme.neutralColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPin ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.neutralColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPin = !_showConfirmPin;
                      });
                    },
                  ),
                ),
                keyboardType: TextInputType.number,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.l),
        
        ElderlyFriendlyButton(
          onPressed: () => _changePIN(notifier),
          text: 'Change PIN',
          icon: Icons.lock_reset,
          backgroundColor: AppTheme.primaryColor,
          textColor: AppTheme.onPrimaryColor,
        ),
      ],
    );
  }
  
  Widget _buildChangePasswordSection(AppLockNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.l),
        Text(
          'Change Password',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        
        Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          ),
          child: Column(
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: !_showOldPassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.password, color: AppTheme.neutralColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showOldPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.neutralColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showOldPassword = !_showOldPassword;
                      });
                    },
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
              
              const SizedBox(height: AppSpacing.m),
              
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'New Password (min. 6 characters)',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.neutralColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
              
              const SizedBox(height: AppSpacing.m),
              
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock, color: AppTheme.neutralColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.neutralColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppSpacing.l),
        
        ElderlyFriendlyButton(
          onPressed: () => _changePassword(notifier),
          text: 'Change Password',
          icon: Icons.lock_reset,
          backgroundColor: AppTheme.primaryColor,
          textColor: AppTheme.onPrimaryColor,
        ),
      ],
    );
  }
  
  Widget _buildResetSection(AppLockNotifier notifier) {
    return Card(
      elevation: 2,
      color: AppTheme.errorContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        side: const BorderSide(width: 2, color: AppTheme.errorColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  size: AppSpacing.iconSizeMedium,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  'Reset Security Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.m),
            
            Text(
              'Warning: This will remove all security settings including PIN, password, and biometric settings.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            
            const SizedBox(height: AppSpacing.l),
            
            ElderlyFriendlyButton(
              onPressed: () => _showResetConfirmationDialog(notifier),
              text: 'Reset All Security Settings',
              icon: Icons.restart_alt,
              backgroundColor: AppTheme.errorColor,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecurityTips() {
    return Card(
      elevation: 2,
      color: AppTheme.secondaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        side: const BorderSide(width: 2, color: AppTheme.primaryColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  size: AppSpacing.iconSizeMedium,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  'Security Tips',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppSpacing.m),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                    leading: Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: AppSpacing.iconSizeSmall,
                    ),
                    title: Text(
                      'Use a strong, unique PIN or password',
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
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: AppSpacing.iconSizeSmall,
                    ),
                    title: Text(
                      'Enable biometric authentication if available',
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
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: AppSpacing.iconSizeSmall,
                    ),
                    title: Text(
                      'Set auto-lock timeout for added security',
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
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: AppSpacing.iconSizeSmall,
                    ),
                    title: Text(
                      'Keep your device operating system updated',
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
                      Icons.check_circle,
                      color: AppTheme.primaryColor,
                      size: AppSpacing.iconSizeSmall,
                    ),
                    title: Text(
                      'Don\'t share your PIN or password with others',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                      ),
                    ),
                    dense: true,
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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
        ),
        title: Text(
          'Select Lock Type',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                side: const BorderSide(width: 1, color: AppTheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.pin,
                  color: AppTheme.primaryColor,
                  size: AppSpacing.iconSizeMedium,
                ),
                title: Text(
                  'PIN',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                subtitle: Text(
                  '4-6 digit numeric code',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutralColor,
                  ),
                ),
                onTap: () => Navigator.pop(context, AppLockService.lockTypePIN),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                side: const BorderSide(width: 1, color: AppTheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.password,
                  color: AppTheme.primaryColor,
                  size: AppSpacing.iconSizeMedium,
                ),
                title: Text(
                  'Password',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                subtitle: Text(
                  'At least 6 characters',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutralColor,
                  ),
                ),
                onTap: () => Navigator.pop(context, AppLockService.lockTypePassword),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                side: const BorderSide(width: 1, color: AppTheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.fingerprint,
                  color: AppTheme.primaryColor,
                  size: AppSpacing.iconSizeMedium,
                ),
                title: Text(
                  'Biometric',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                subtitle: Text(
                  'Fingerprint or Face ID',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.neutralColor,
                  ),
                ),
                onTap: () => Navigator.pop(context, AppLockService.lockTypeBiometric),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.m,
                  vertical: AppSpacing.s,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutralColor,
                fontWeight: FontWeight.w600,
              ),
            ),
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
            ),
            title: Text(
              'Set PIN',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.onSurfaceColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: pinController,
                  obscureText: !showPin,
                  decoration: InputDecoration(
                    labelText: 'Enter PIN (4-6 digits)',
                    prefixIcon: Icon(Icons.pin, color: AppTheme.neutralColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPin ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.neutralColor,
                      ),
                      onPressed: () {
                        setState(() {
                          showPin = !showPin;
                        });
                      },
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: confirmPinController,
                  obscureText: !showConfirmPin,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    prefixIcon: Icon(Icons.pin_outlined, color: AppTheme.neutralColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPin ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.neutralColor,
                      ),
                      onPressed: () {
                        setState(() {
                          showConfirmPin = !showConfirmPin;
                        });
                      },
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutralColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.onPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: AppSpacing.m,
                  ),
                ),
                onPressed: () async {
                  if (pinController.text.length < 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PIN must be at least 4 digits',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        ),
                      ),
                    );
                    return;
                  }
                  
                  if (pinController.text != confirmPinController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PINs do not match',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        ),
                      ),
                    );
                    return;
                  }
                  
                  final success = await notifier.enablePIN(pinController.text);
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'PIN set successfully',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  'Set PIN',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
            ),
            title: Text(
              'Set Password',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.onSurfaceColor,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: 'Enter Password (min. 6 characters)',
                    prefixIcon: Icon(Icons.lock_outline, color: AppTheme.neutralColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.neutralColor,
                      ),
                      onPressed: () {
                        setState(() {
                          showPassword = !showPassword;
                        });
                      },
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.neutralColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.neutralColor,
                      ),
                      onPressed: () {
                        setState(() {
                          showConfirmPassword = !showConfirmPassword;
                        });
                      },
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.neutralColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.onPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: AppSpacing.m,
                  ),
                ),
                onPressed: () async {
                  if (passwordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password must be at least 6 characters',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        ),
                      ),
                    );
                    return;
                  }
                  
                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Passwords do not match',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppTheme.errorColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        ),
                      ),
                    );
                    return;
                  }
                  
                  final success = await notifier.enablePassword(passwordController.text);
                  if (success) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Password set successfully',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: AppTheme.primaryColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  'Set Password',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
        ),
        title: Text(
          'Disable App Lock',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.errorColor,
          ),
        ),
        content: Text(
          'Are you sure you want to disable app lock? This will remove all security settings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutralColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              ),
            ),
            child: Text(
              'Disable',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await notifier.disableLock();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'App lock disabled',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _showResetConfirmationDialog(AppLockNotifier notifier) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
        ),
        title: Text(
          'Reset Security Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.errorColor,
          ),
        ),
        content: Text(
          'This will remove all security settings including PIN, password, and biometric settings. Are you sure?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutralColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              ),
            ),
            child: Text(
              'Reset',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reset functionality to be implemented',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
    }
  }
  
  // Action methods
  Future<void> _enableBiometric(AppLockNotifier notifier) async {
    final success = await notifier.enableBiometric();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Biometric authentication enabled',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
    }
  }
  
  Future<void> _disableBiometric(AppLockNotifier notifier) async {
    final success = await notifier.disableLock();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Biometric authentication disabled',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
    }
  }
  
  Future<void> _testBiometric(AppLockNotifier notifier) async {
    final success = await notifier.authenticateWithBiometrics();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Biometric authentication successful',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Biometric authentication failed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
    }
  }
  
  Future<void> _changePIN(AppLockNotifier notifier) async {
    if (_oldPinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter current PIN',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
      return;
    }
    
    if (_pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New PIN must be at least 4 digits',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
      return;
    }
    
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PINs do not match',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
      return;
    }
    
    final success = await notifier.changePIN(_oldPinController.text, _pinController.text);
    if (success) {
      _oldPinController.clear();
      _pinController.clear();
      _confirmPinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PIN changed successfully',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
    }
  }
  
  Future<void> _changePassword(AppLockNotifier notifier) async {
    if (_oldPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter current password',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
      return;
    }
    
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New password must be at least 6 characters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
      return;
    }
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Passwords do not match',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
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
        SnackBar(
          content: Text(
            'Password changed successfully',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
        ),
      );
    }
  }
}