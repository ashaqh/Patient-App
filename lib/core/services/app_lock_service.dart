import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/aes_encryption_service.dart';
import '../utils/error_utils.dart';
import 'local_auth_service.dart';

class AppLockService {
  static const String _pinKey = 'app_lock_pin';
  static const String _passwordKey = 'app_lock_password';
  static const String _lockEnabledKey = 'app_lock_enabled';
  static const String _lockTypeKey = 'app_lock_type';
  static const String _biometricEnabledKey = 'app_lock_biometric_enabled';
  static const String _lockTimeoutKey = 'app_lock_timeout';
  static const String _lastUnlockTimeKey = 'app_last_unlock_time';

  final FlutterSecureStorage _secureStorage;
  final AESEncryptionService _encryptionService;
  final LocalAuthService _localAuthService;

  // Lock types
  static const String lockTypeNone = 'none';
  static const String lockTypePIN = 'pin';
  static const String lockTypePassword = 'password';
  static const String lockTypeBiometric = 'biometric';

  // Timeout options (in minutes)
  static const Map<String, int> timeoutOptions = {
    'immediate': 0,
    '30_seconds': 30,
    '1_minute': 1,
    '5_minutes': 5,
    '10_minutes': 10,
    '30_minutes': 30,
    '1_hour': 60,
    'never': -1,
  };

  AppLockService()
      : _secureStorage = const FlutterSecureStorage(),
        _encryptionService = AESEncryptionService(const FlutterSecureStorage()),
        _localAuthService = LocalAuthService();
  
  // Check if app lock is enabled
  Future<bool> isLockEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _lockEnabledKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      return enabled == 'true';
    } catch (e) {
      ErrorUtils.logError('Error checking lock enabled', error: e, tag: 'AppLock');
      // Return false on error to allow app to proceed
      return false;
    }
  }
  
  // Get current lock type
  Future<String> getLockType() async {
    try {
      final type = await _secureStorage.read(key: _lockTypeKey);
      return type ?? lockTypeNone;
    } catch (e) {
      ErrorUtils.logError('Error getting lock type', error: e, tag: 'AppLock');
      return lockTypeNone;
    }
  }
  
  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      ErrorUtils.logError('Error checking biometric enabled', error: e, tag: 'AppLock');
      return false;
    }
  }
  
  // Get lock timeout (in minutes)
  Future<int> getLockTimeout() async {
    try {
      final timeout = await _secureStorage.read(key: _lockTimeoutKey);
      return int.tryParse(timeout ?? '0') ?? 0;
    } catch (e) {
      ErrorUtils.logError('Error getting lock timeout', error: e, tag: 'AppLock');
      return 0;
    }
  }
  
  // Set PIN lock
  Future<bool> setPIN(String pin) async {
    try {
      if (pin.length < 4) {
        throw Exception('PIN must be at least 4 digits');
      }
      
      // Encrypt and store PIN
      final encryptedPIN = await _encryptionService.encryptText(
        pin,
        purpose: _pinKey,
      );
      
      await _secureStorage.write(key: _pinKey, value: encryptedPIN);
      await _secureStorage.write(key: _lockTypeKey, value: lockTypePIN);
      await _secureStorage.write(key: _lockEnabledKey, value: 'true');
      
      return true;
    } catch (e) {
      ErrorUtils.logInfo('Error setting PIN: $e');
      return false;
    }
  }
  
  // Set password lock
  Future<bool> setPassword(String password) async {
    try {
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      
      // Encrypt and store password
      final encryptedPassword = await _encryptionService.encryptText(
        password,
        purpose: _passwordKey,
      );
      
      await _secureStorage.write(key: _passwordKey, value: encryptedPassword);
      await _secureStorage.write(key: _lockTypeKey, value: lockTypePassword);
      await _secureStorage.write(key: _lockEnabledKey, value: 'true');
      
      return true;
    } catch (e) {
      ErrorUtils.logInfo('Error setting password: $e');
      return false;
    }
  }
  
  // Enable biometric lock
  Future<bool> enableBiometricLock() async {
    try {
      // Check if biometric is available
      final hasBiometric = await _localAuthService.hasBiometricAuthentication();
      if (!hasBiometric) {
        throw Exception('Biometric authentication not available');
      }
      
      await _secureStorage.write(key: _lockTypeKey, value: lockTypeBiometric);
      await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
      await _secureStorage.write(key: _lockEnabledKey, value: 'true');
      
      return true;
    } catch (e) {
      ErrorUtils.logInfo('Error enabling biometric lock: $e');
      return false;
    }
  }
  
  // Disable app lock
  Future<bool> disableLock() async {
    try {
      await _secureStorage.write(key: _lockEnabledKey, value: 'false');
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.delete(key: _passwordKey);
      await _secureStorage.write(key: _biometricEnabledKey, value: 'false');
      
      return true;
    } catch (e) {
      ErrorUtils.logInfo('Error disabling lock: $e');
      return false;
    }
  }
  
  // Verify PIN
  Future<bool> verifyPIN(String pin) async {
    try {
      final encryptedPIN = await _secureStorage.read(key: _pinKey);
      if (encryptedPIN == null) return false;
      
      final decryptedPIN = await _encryptionService.decryptText(
        encryptedPIN,
        purpose: _pinKey,
      );
      
      if (decryptedPIN == pin) {
        await _updateLastUnlockTime();
        return true;
      }
      
      return false;
    } catch (e) {
      ErrorUtils.logInfo('Error verifying PIN: $e');
      return false;
    }
  }
  
  // Verify password
  Future<bool> verifyPassword(String password) async {
    try {
      final encryptedPassword = await _secureStorage.read(key: _passwordKey);
      if (encryptedPassword == null) return false;
      
      final decryptedPassword = await _encryptionService.decryptText(
        encryptedPassword,
        purpose: _passwordKey,
      );
      
      if (decryptedPassword == password) {
        await _updateLastUnlockTime();
        return true;
      }
      
      return false;
    } catch (e) {
      ErrorUtils.logInfo('Error verifying password: $e');
      return false;
    }
  }
  
  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final hasBiometric = await _localAuthService.hasBiometricAuthentication();
      if (!hasBiometric) {
        throw Exception('Biometric authentication not available');
      }
      
      final authenticated = await _localAuthService.authenticateWithBiometrics(
        localizedReason: 'Authenticate to unlock CareVault',
      );
      
      if (authenticated) {
        await _updateLastUnlockTime();
      }
      
      return authenticated;
    } catch (e) {
      ErrorUtils.logInfo('Error with biometric authentication: $e');
      return false;
    }
  }
  
  // Check if app is locked (based on timeout)
  Future<bool> isAppLocked() async {
    try {
      final enabled = await isLockEnabled();
      if (!enabled) return false;
      
      final timeout = await getLockTimeout();
      if (timeout == -1) {
        // Never lock after unlock
        return false;
      }
      
      final lastUnlockTime = await _getLastUnlockTime();
      if (lastUnlockTime == null) {
        // Never unlocked since lock was enabled
        return true;
      }
      
      final now = DateTime.now();
      final difference = now.difference(lastUnlockTime);
      
      // Convert timeout minutes to Duration
      final timeoutDuration = Duration(minutes: timeout);
      
      return difference > timeoutDuration;
    } catch (e) {
      ErrorUtils.logInfo('Error checking if app is locked: $e');
      // Return false on error to allow app to proceed
      return false;
    }
  }
  
  // Update last unlock time
  Future<void> _updateLastUnlockTime() async {
    try {
      final now = DateTime.now().toIso8601String();
      await _secureStorage.write(key: _lastUnlockTimeKey, value: now);
    } catch (e) {
      ErrorUtils.logInfo('Error updating last unlock time: $e');
    }
  }
  
  // Get last unlock time
  Future<DateTime?> _getLastUnlockTime() async {
    try {
      final timeString = await _secureStorage.read(key: _lastUnlockTimeKey);
      if (timeString == null) return null;
      
      return DateTime.parse(timeString);
    } catch (e) {
      ErrorUtils.logInfo('Error getting last unlock time: $e');
      return null;
    }
  }
  
  // Set lock timeout
  Future<bool> setLockTimeout(int minutes) async {
    try {
      if (!timeoutOptions.containsValue(minutes) && minutes != -1) {
        throw Exception('Invalid timeout value');
      }
      
      await _secureStorage.write(key: _lockTimeoutKey, value: minutes.toString());
      return true;
    } catch (e) {
      ErrorUtils.logInfo('Error setting lock timeout: $e');
      return false;
    }
  }
  
  // Get lock timeout display name
  String getTimeoutDisplayName(int minutes) {
    if (minutes == -1) return 'Never';
    if (minutes == 0) return 'Immediately';
    if (minutes < 60) return '$minutes minutes';
    
    final hours = minutes ~/ 60;
    return '$hours hour${hours > 1 ? 's' : ''}';
  }
  
  // Get all lock settings
  Future<Map<String, dynamic>> getLockSettings() async {
    try {
      final enabled = await isLockEnabled();
      final type = await getLockType();
      final biometricEnabled = await isBiometricEnabled();
      final timeout = await getLockTimeout();
      final biometricStatus = await _localAuthService.getAuthenticationStatus();
      
      return {
        'enabled': enabled,
        'type': type,
        'biometric_enabled': biometricEnabled,
        'timeout': timeout,
        'timeout_display': getTimeoutDisplayName(timeout),
        'biometric_status': biometricStatus,
        'has_pin': await _secureStorage.containsKey(key: _pinKey),
        'has_password': await _secureStorage.containsKey(key: _passwordKey),
      };
    } catch (e) {
      return {
        'enabled': false,
        'type': lockTypeNone,
        'biometric_enabled': false,
        'timeout': 0,
        'timeout_display': 'Immediately',
        'error': e.toString(),
      };
    }
  }
  
  // Change PIN
  Future<bool> changePIN(String oldPIN, String newPIN) async {
    try {
      final verified = await verifyPIN(oldPIN);
      if (!verified) {
        throw Exception('Old PIN is incorrect');
      }
      
      return await setPIN(newPIN);
    } catch (e) {
      ErrorUtils.logInfo('Error changing PIN: $e');
      return false;
    }
  }
  
  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      final verified = await verifyPassword(oldPassword);
      if (!verified) {
        throw Exception('Old password is incorrect');
      }
      
      return await setPassword(newPassword);
    } catch (e) {
      ErrorUtils.logInfo('Error changing password: $e');
      return false;
    }
  }
  
  // Reset all lock settings
  Future<void> resetAllSettings() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await _secureStorage.delete(key: _passwordKey);
      await _secureStorage.delete(key: _lockEnabledKey);
      await _secureStorage.delete(key: _lockTypeKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
      await _secureStorage.delete(key: _lockTimeoutKey);
      await _secureStorage.delete(key: _lastUnlockTimeKey);
    } catch (e) {
      ErrorUtils.logInfo('Error resetting lock settings: $e');
    }
  }
  
  // Check if PIN is set
  Future<bool> hasPIN() async {
    try {
      return await _secureStorage.containsKey(key: _pinKey);
    } catch (e) {
      ErrorUtils.logInfo('Error checking if PIN exists: $e');
      return false;
    }
  }
  
  // Check if password is set
  Future<bool> hasPassword() async {
    try {
      return await _secureStorage.containsKey(key: _passwordKey);
    } catch (e) {
      ErrorUtils.logInfo('Error checking if password exists: $e');
      return false;
    }
  }
  
  // Validate PIN format
  bool isValidPIN(String pin) {
    return pin.length >= 4 && RegExp(r'^\d+$').hasMatch(pin);
  }
  
  // Validate password format
  bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  // Get timeout options for display
  Map<String, String> getTimeoutOptionsForDisplay() {
    final options = <String, String>{};
    
    timeoutOptions.forEach((key, value) {
      options[key] = getTimeoutDisplayName(value);
    });
    
    return options;
  }
  
  // Get lock type display name
  String getLockTypeDisplayName(String type) {
    switch (type) {
      case lockTypePIN:
        return 'PIN';
      case lockTypePassword:
        return 'Password';
      case lockTypeBiometric:
        return 'Biometric';
      default:
        return 'None';
    }
  }
}
