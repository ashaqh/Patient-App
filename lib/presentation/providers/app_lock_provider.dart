import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/app_lock_service.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService();
});

final appLockSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(appLockServiceProvider);
  return await service.getLockSettings();
});

final appLockEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(appLockServiceProvider);
  return await service.isLockEnabled();
});

final appLockTypeProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(appLockServiceProvider);
  return await service.getLockType();
});

final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(appLockServiceProvider);
  return await service.isBiometricEnabled();
});

final appLockTimeoutProvider = FutureProvider<int>((ref) async {
  final service = ref.watch(appLockServiceProvider);
  return await service.getLockTimeout();
});

final appLockStatusProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(appLockServiceProvider);
  return await service.isAppLocked();
});

class AppLockNotifier extends StateNotifier<AppLockState> {
  final AppLockService _service;
  
  AppLockNotifier(this._service, Ref ref) : super(AppLockState.initial());
  
  // Load lock settings
  Future<void> loadSettings() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final settings = await _service.getLockSettings();
      final isLocked = await _service.isAppLocked();
      
      state = state.copyWith(
        isLoading: false,
        settings: settings,
        isLocked: isLocked,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load settings: $e',
      );
    }
  }
  
  // Enable PIN lock
  Future<bool> enablePIN(String pin) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.setPIN(pin);
      if (success) {
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to enable PIN lock',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to enable PIN: $e',
      );
      return false;
    }
  }
  
  // Enable password lock
  Future<bool> enablePassword(String password) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.setPassword(password);
      if (success) {
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to enable password lock',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to enable password: $e',
      );
      return false;
    }
  }
  
  // Enable biometric lock
  Future<bool> enableBiometric() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.enableBiometricLock();
      if (success) {
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to enable biometric lock',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to enable biometric: $e',
      );
      return false;
    }
  }
  
  // Disable app lock
  Future<bool> disableLock() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.disableLock();
      if (success) {
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to disable lock',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to disable lock: $e',
      );
      return false;
    }
  }
  
  // Verify PIN
  Future<bool> verifyPIN(String pin) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.verifyPIN(pin);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          isLocked: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Incorrect PIN',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to verify PIN: $e',
      );
      return false;
    }
  }
  
  // Verify password
  Future<bool> verifyPassword(String password) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.verifyPassword(password);
      if (success) {
        state = state.copyWith(
          isLoading: false,
          isLocked: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Incorrect password',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to verify password: $e',
      );
      return false;
    }
  }
  
  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.authenticateWithBiometrics();
      if (success) {
        state = state.copyWith(
          isLoading: false,
          isLocked: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Biometric authentication failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to authenticate: $e',
      );
      return false;
    }
  }
  
  // Set lock timeout
  Future<bool> setTimeout(int minutes) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.setLockTimeout(minutes);
      if (success) {
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to set timeout',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to set timeout: $e',
      );
      return false;
    }
  }
  
  // Change PIN
  Future<bool> changePIN(String oldPIN, String newPIN) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.changePIN(oldPIN, newPIN);
      if (success) {
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to change PIN',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to change PIN: $e',
      );
      return false;
    }
  }
  
  // Change password
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final success = await _service.changePassword(oldPassword, newPassword);
      if (success) {
        await loadSettings();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to change password',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to change password: $e',
      );
      return false;
    }
  }
  
  // Reset all security settings
  Future<bool> resetSettings() async {
    try {
      state = state.copyWith(isLoading: true);

      await _service.resetAllSettings();
      await loadSettings();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reset settings: $e',
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  // Set locked state (for testing/manual control)
  void setLocked(bool locked) {
    state = state.copyWith(isLocked: locked);
  }
  
  // Check lock status
  Future<void> checkLockStatus() async {
    try {
      final isLocked = await _service.isAppLocked();
      state = state.copyWith(isLocked: isLocked);
    } catch (e) {
      state = state.copyWith(error: 'Failed to check lock status: $e');
    }
  }
  
  // Get timeout display name (wrapper for service method)
  String getTimeoutDisplayName(int minutes) {
    return _service.getTimeoutDisplayName(minutes);
  }
}

class AppLockState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? settings;
  final bool isLocked;
  
  AppLockState({
    required this.isLoading,
    this.error,
    this.settings,
    required this.isLocked,
  });
  
  factory AppLockState.initial() {
    return AppLockState(
      isLoading: false,
      isLocked: false,
    );
  }
  
  AppLockState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? settings,
    bool? isLocked,
  }) {
    return AppLockState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      settings: settings ?? this.settings,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

final appLockNotifierProvider = StateNotifierProvider<AppLockNotifier, AppLockState>((ref) {
  final service = ref.watch(appLockServiceProvider);
  return AppLockNotifier(service, ref);
});
