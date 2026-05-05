import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/error_utils.dart';

class EncryptionService {
  static const String _keyPrefix = 'encryption_key_';
  static const int _keyLength = 32; // 256 bits for AES
  static const String _ivPrefix = 'encryption_iv_';
  static const int _ivLength = 16; // 128 bits for AES IV
  
  final FlutterSecureStorage _secureStorage;

  EncryptionService(this._secureStorage);

  // Generate a random key
  static String _generateRandomKey(int length) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // Get or create encryption key for a specific purpose
  Future<String> _getOrCreateKey(String purpose) async {
    final keyName = '$_keyPrefix$purpose';
    final existingKey = await _secureStorage.read(key: keyName);
    
    if (existingKey != null && existingKey.isNotEmpty) {
      return existingKey;
    }
    
    // Generate new key
    final newKey = _generateRandomKey(_keyLength);
    await _secureStorage.write(key: keyName, value: newKey);
    return newKey;
  }

  // Get or create IV for a specific purpose
  Future<String> _getOrCreateIV(String purpose) async {
    final ivName = '$_ivPrefix$purpose';
    final existingIV = await _secureStorage.read(key: ivName);
    
    if (existingIV != null && existingIV.isNotEmpty) {
      return existingIV;
    }
    
    // Generate new IV
    final newIV = _generateRandomKey(_ivLength);
    await _secureStorage.write(key: ivName, value: newIV);
    return newIV;
  }

  // Simple XOR encryption (for demonstration - in production use proper AES)
  // Note: This is a simplified encryption for demo purposes.
  // In a production app, you should use a proper encryption library like pointycastle
  String _simpleEncrypt(String text, String key) {
    final textBytes = utf8.encode(text);
    final keyBytes = utf8.encode(key);
    final result = List<int>.filled(textBytes.length, 0);
    
    for (int i = 0; i < textBytes.length; i++) {
      result[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    
    return base64Url.encode(result);
  }

  // Simple XOR decryption (for demonstration - in production use proper AES)
  String _simpleDecrypt(String encrypted, String key) {
    try {
      final encryptedBytes = base64Url.decode(encrypted);
      final keyBytes = utf8.encode(key);
      final result = List<int>.filled(encryptedBytes.length, 0);
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        result[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
      }
      
      return utf8.decode(result);
    } catch (e) {
      throw Exception('Decryption failed: $e');
    }
  }

  // Encrypt sensitive text data
  Future<String> encryptText(String text, {String purpose = 'default'}) async {
    if (text.isEmpty) return text;
    
    try {
      final key = await _getOrCreateKey(purpose);
      return _simpleEncrypt(text, key);
    } catch (e) {
      // If encryption fails, return the original text
      // In production, you might want to handle this differently
      ErrorUtils.logInfo('Encryption failed: $e');
      return text;
    }
  }

  // Decrypt sensitive text data
  Future<String> decryptText(String encrypted, {String purpose = 'default'}) async {
    if (encrypted.isEmpty) return encrypted;
    
    try {
      final key = await _getOrCreateKey(purpose);
      return _simpleDecrypt(encrypted, key);
    } catch (e) {
      // If decryption fails, return the encrypted text
      // In production, you might want to handle this differently
      ErrorUtils.logInfo('Decryption failed: $e');
      return encrypted;
    }
  }

  // Encrypt sensitive fields in a map
  Future<Map<String, dynamic>> encryptMap(
    Map<String, dynamic> map, 
    List<String> fieldsToEncrypt,
    {String purpose = 'default'}
  ) async {
    final encryptedMap = Map<String, dynamic>.from(map);
    
    for (final field in fieldsToEncrypt) {
      if (encryptedMap.containsKey(field) && encryptedMap[field] is String) {
        final value = encryptedMap[field] as String;
        if (value.isNotEmpty) {
          encryptedMap[field] = await encryptText(value, purpose: purpose);
        }
      }
    }
    
    return encryptedMap;
  }

  // Decrypt sensitive fields in a map
  Future<Map<String, dynamic>> decryptMap(
    Map<String, dynamic> map, 
    List<String> fieldsToDecrypt,
    {String purpose = 'default'}
  ) async {
    final decryptedMap = Map<String, dynamic>.from(map);
    
    for (final field in fieldsToDecrypt) {
      if (decryptedMap.containsKey(field) && decryptedMap[field] is String) {
        final value = decryptedMap[field] as String;
        if (value.isNotEmpty) {
          decryptedMap[field] = await decryptText(value, purpose: purpose);
        }
      }
    }
    
    return decryptedMap;
  }

  // Check if text appears to be encrypted
  bool isEncrypted(String text) {
    if (text.isEmpty) return false;
    
    try {
      // Try to decode as base64
      base64Url.decode(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Rotate encryption key (generate new key and re-encrypt data)
  Future<bool> rotateKey(String purpose, {required Future<void> Function(String oldKey, String newKey) reencryptCallback}) async {
    try {
      final oldKey = await _getOrCreateKey(purpose);
      final newKey = _generateRandomKey(_keyLength);
      
      // Call the re-encryption callback
      await reencryptCallback(oldKey, newKey);
      
      // Store the new key
      final keyName = '$_keyPrefix$purpose';
      await _secureStorage.write(key: keyName, value: newKey);
      
      return true;
    } catch (e) {
      ErrorUtils.logInfo('Key rotation failed: $e');
      return false;
    }
  }

  // Clear all encryption keys (for testing/reset)
  Future<void> clearAllKeys() async {
    try {
      final allKeys = await _secureStorage.readAll();
      
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix) || key.startsWith(_ivPrefix)) {
          await _secureStorage.delete(key: key);
        }
      }
    } catch (e) {
      ErrorUtils.logInfo('Failed to clear encryption keys: $e');
    }
  }

  // Check if encryption is available
  Future<bool> isEncryptionAvailable() async {
    try {
      // Try to read/write a test value
      const testKey = 'encryption_test_key';
      const testValue = 'test_value';
      
      await _secureStorage.write(key: testKey, value: testValue);
      final readValue = await _secureStorage.read(key: testKey);
      await _secureStorage.delete(key: testKey);
      
      return readValue == testValue;
    } catch (e) {
      ErrorUtils.logInfo('Encryption test failed: $e');
      return false;
    }
  }

  // Get encryption status
  Future<Map<String, dynamic>> getEncryptionStatus() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final encryptionKeys = allKeys.keys.where((k) => k.startsWith(_keyPrefix)).length;
      final ivKeys = allKeys.keys.where((k) => k.startsWith(_ivPrefix)).length;
      final available = await isEncryptionAvailable();
      
      return {
        'available': available,
        'encryption_keys': encryptionKeys,
        'iv_keys': ivKeys,
        'total_keys': allKeys.length,
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }

  // Encrypt file path (for sensitive file locations)
  Future<String> encryptFilePath(String filePath, {String purpose = 'file_paths'}) async {
    return encryptText(filePath, purpose: purpose);
  }

  // Decrypt file path
  Future<String> decryptFilePath(String encryptedPath, {String purpose = 'file_paths'}) async {
    return decryptText(encryptedPath, purpose: purpose);
  }

  // Batch encrypt multiple values
  Future<List<String>> batchEncrypt(List<String> values, {String purpose = 'default'}) async {
    final results = <String>[];
    
    for (final value in values) {
      final encrypted = await encryptText(value, purpose: purpose);
      results.add(encrypted);
    }
    
    return results;
  }

  // Batch decrypt multiple values
  Future<List<String>> batchDecrypt(List<String> encryptedValues, {String purpose = 'default'}) async {
    final results = <String>[];
    
    for (final encrypted in encryptedValues) {
      final decrypted = await decryptText(encrypted, purpose: purpose);
      results.add(decrypted);
    }
    
    return results;
  }
}
