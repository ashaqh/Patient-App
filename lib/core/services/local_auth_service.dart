import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../utils/error_utils.dart';

class LocalAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  
  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error checking biometric availability: $e');
      return false;
    }
  }
  
  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error getting available biometrics: $e');
      return [];
    }
  }
  
  // Check if device supports biometric authentication
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error checking device support: $e');
      return false;
    }
  }
  
  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics({
    String localizedReason = 'Authenticate to access the app',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error during biometric authentication: $e');
      return false;
    }
  }
  
  // Authenticate with biometrics or device credentials
  Future<bool> authenticate({
    String localizedReason = 'Authenticate to access the app',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool biometricOnly = false,
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error during authentication: $e');
      return false;
    }
  }
  
  // Stop ongoing authentication
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error stopping authentication: $e');
    }
  }
  
  // Check if face ID is available
  Future<bool> isFaceIdAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.face);
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error checking face ID availability: $e');
      return false;
    }
  }
  
  // Check if fingerprint is available
  Future<bool> isFingerprintAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.fingerprint);
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error checking fingerprint availability: $e');
      return false;
    }
  }
  
  // Check if iris scanner is available
  Future<bool> isIrisAvailable() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.contains(BiometricType.iris);
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error checking iris availability: $e');
      return false;
    }
  }
  
  // Get biometric type name for display
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scanner';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      default:
        return 'Biometric';
    }
  }
  
  // Get all available biometric type names
  Future<List<String>> getAvailableBiometricNames() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.map(getBiometricTypeName).toList();
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error getting biometric names: $e');
      return [];
    }
  }
  
  // Check if any biometric authentication is available
  Future<bool> hasBiometricAuthentication() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException catch (e) {
      ErrorUtils.logInfo('Error checking biometric authentication: $e');
      return false;
    }
  }
  
  // Get authentication status summary
  Future<Map<String, dynamic>> getAuthenticationStatus() async {
    try {
      final isSupported = await isDeviceSupported();
      final isAvailable = await isBiometricAvailable();
      final biometrics = await getAvailableBiometrics();
      final hasBiometric = await hasBiometricAuthentication();
      
      return {
        'device_supported': isSupported,
        'biometric_available': isAvailable,
        'has_biometric': hasBiometric,
        'available_biometrics': biometrics.map(getBiometricTypeName).toList(),
        'has_face_id': biometrics.contains(BiometricType.face),
        'has_fingerprint': biometrics.contains(BiometricType.fingerprint),
        'has_iris': biometrics.contains(BiometricType.iris),
      };
    } on PlatformException catch (e) {
      return {
        'device_supported': false,
        'biometric_available': false,
        'has_biometric': false,
        'available_biometrics': [],
        'error': e.toString(),
      };
    }
  }
}
