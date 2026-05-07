import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/error_utils.dart';

class AESEncryptionService {
  static const String _keyPrefix = 'aes_encryption_key_';
  static const String _ivPrefix = 'aes_encryption_iv_';
  static const int _keyLength = 32; // 256 bits for AES-256
  static const int _ivLength = 16; // 128 bits for AES IV

  final FlutterSecureStorage _secureStorage;

  AESEncryptionService(FlutterSecureStorage secureStorage)
      : _secureStorage = secureStorage;

  // Generate a random key for AES-256
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

  // Convert base64 key to Uint8List
  Uint8List _keyToBytes(String base64Key) {
    return base64Url.decode(base64Key);
  }

  // Convert base64 IV to Uint8List
  Uint8List _ivToBytes(String base64IV) {
    return base64Url.decode(base64IV);
  }

  // AES-256 CBC encryption
  String _aesEncrypt(String plaintext, String base64Key, String base64IV) {
    try {
      final key = _keyToBytes(base64Key);
      final iv = _ivToBytes(base64IV);
      
      // Create cipher
      final cipher = CBCBlockCipher(AESEngine())
        ..init(true, ParametersWithIV(KeyParameter(key), iv));
      
      // Prepare input
      final plaintextBytes = utf8.encode(plaintext);
      
      // Add PKCS7 padding
      final paddedPlaintext = _addPKCS7Padding(plaintextBytes, cipher.blockSize);
      
      // Encrypt
      final cipherText = Uint8List(paddedPlaintext.length);
      var offset = 0;
      while (offset < paddedPlaintext.length) {
        offset += cipher.processBlock(paddedPlaintext, offset, cipherText, offset);
      }
      
      return base64Url.encode(cipherText);
    } catch (e) {
      throw Exception('AES encryption failed: $e');
    }
  }

  // AES-256 CBC decryption
  String _aesDecrypt(String encrypted, String base64Key, String base64IV) {
    try {
      final key = _keyToBytes(base64Key);
      final iv = _ivToBytes(base64IV);
      final cipherText = base64Url.decode(encrypted);
      
      // Create cipher
      final cipher = CBCBlockCipher(AESEngine())
        ..init(false, ParametersWithIV(KeyParameter(key), iv));
      
      // Decrypt
      final plaintext = Uint8List(cipherText.length);
      var offset = 0;
      while (offset < cipherText.length) {
        offset += cipher.processBlock(cipherText, offset, plaintext, offset);
      }
      
      // Remove PKCS7 padding
      final unpaddedPlaintext = _removePKCS7Padding(plaintext);
      
      return utf8.decode(unpaddedPlaintext);
    } catch (e) {
      throw Exception('AES decryption failed: $e');
    }
  }

  // Add PKCS7 padding
  Uint8List _addPKCS7Padding(List<int> data, int blockSize) {
    final paddingLength = blockSize - (data.length % blockSize);
    final paddedData = Uint8List(data.length + paddingLength);
    paddedData.setAll(0, data);
    for (var i = data.length; i < paddedData.length; i++) {
      paddedData[i] = paddingLength;
    }
    return paddedData;
  }

  // Remove PKCS7 padding
  Uint8List _removePKCS7Padding(Uint8List paddedData) {
    final paddingLength = paddedData[paddedData.length - 1];
    
    // Validate padding
    if (paddingLength <= 0 || paddingLength > paddedData.length) {
      throw Exception('Invalid PKCS7 padding');
    }
    
    for (var i = paddedData.length - paddingLength; i < paddedData.length; i++) {
      if (paddedData[i] != paddingLength) {
        throw Exception('Invalid PKCS7 padding');
      }
    }
    
    return Uint8List.sublistView(paddedData, 0, paddedData.length - paddingLength);
  }

  // Encrypt sensitive text data with AES-256
  Future<String> encryptText(String text, {String purpose = 'default'}) async {
    if (text.isEmpty) return text;
    
    try {
      final key = await _getOrCreateKey(purpose);
      final iv = await _getOrCreateIV(purpose);
      return _aesEncrypt(text, key, iv);
    } catch (e) {
      // If encryption fails, throw error (don't return plaintext)
      throw Exception('Failed to encrypt text: $e');
    }
  }

  // Decrypt sensitive text data with AES-256
  Future<String> decryptText(String encrypted, {String purpose = 'default'}) async {
    if (encrypted.isEmpty) return encrypted;
    
    try {
      final key = await _getOrCreateKey(purpose);
      final iv = await _getOrCreateIV(purpose);
      return _aesDecrypt(encrypted, key, iv);
    } catch (e) {
      throw Exception('Failed to decrypt text: $e');
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

  // Check if text appears to be encrypted (base64)
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
  Future<bool> rotateKey(String purpose, {required Future<void> Function(String oldKey, String newKey, String oldIV, String newIV) reencryptCallback}) async {
    try {
      final oldKey = await _getOrCreateKey(purpose);
      final oldIV = await _getOrCreateIV(purpose);
      final newKey = _generateRandomKey(_keyLength);
      final newIV = _generateRandomKey(_ivLength);
      
      // Call the re-encryption callback
      await reencryptCallback(oldKey, newKey, oldIV, newIV);
      
      // Store the new key and IV
      final keyName = '$_keyPrefix$purpose';
      final ivName = '$_ivPrefix$purpose';
      await _secureStorage.write(key: keyName, value: newKey);
      await _secureStorage.write(key: ivName, value: newIV);
      
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
      // Try to encrypt and decrypt a test value
      const testValue = 'encryption_test_value_123';
      final encrypted = await encryptText(testValue, purpose: 'test');
      final decrypted = await decryptText(encrypted, purpose: 'test');
      
      // Clean up test key
      final testKeyName = '${_keyPrefix}test';
      final testIVName = '${_ivPrefix}test';
      await _secureStorage.delete(key: testKeyName);
      await _secureStorage.delete(key: testIVName);
      
      return decrypted == testValue;
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
        'algorithm': 'AES-256-CBC',
        'key_size': '256 bits',
        'iv_size': '128 bits',
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
        'algorithm': 'AES-256-CBC',
      };
    }
  }

  // Derive key from password using PBKDF2
  Future<String> deriveKeyFromPassword(String password, String salt, {int iterations = 10000}) async {
    try {
      final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
      final params = Pbkdf2Parameters(utf8.encode(salt), iterations, _keyLength);
      pbkdf2.init(params);
      
      final key = pbkdf2.process(utf8.encode(password));
      return base64Url.encode(key);
    } catch (e) {
      throw Exception('Failed to derive key from password: $e');
    }
  }

  // Generate salt for password-based key derivation
  String generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // Encrypt with password-based key derivation
  Future<String> encryptWithPassword(String plaintext, String password) async {
    try {
      final salt = generateSalt();
      final derivedKey = await deriveKeyFromPassword(password, salt);
      final iv = _generateRandomKey(_ivLength);
      
      // Store salt and IV with encrypted data
      final ciphertext = _aesEncrypt(plaintext, derivedKey, iv);
      final combined = {
        'ciphertext': ciphertext,
        'salt': salt,
        'iv': iv,
        'algorithm': 'AES-256-CBC-PBKDF2',
      };
      
      return base64Url.encode(utf8.encode(json.encode(combined)));
    } catch (e) {
      throw Exception('Password-based encryption failed: $e');
    }
  }

  // Decrypt with password-based key derivation
  Future<String> decryptWithPassword(String encryptedData, String password) async {
    try {
      final decoded = utf8.decode(base64Url.decode(encryptedData));
      final data = json.decode(decoded) as Map<String, dynamic>;
      
      final ciphertext = data['ciphertext'] as String;
      final salt = data['salt'] as String;
      final iv = data['iv'] as String;
      
      final derivedKey = await deriveKeyFromPassword(password, salt);
      return _aesDecrypt(ciphertext, derivedKey, iv);
    } catch (e) {
      throw Exception('Password-based decryption failed: $e');
    }
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

  // Encrypt file path (for sensitive file locations)
  Future<String> encryptFilePath(String filePath, {String purpose = 'file_paths'}) async {
    return encryptText(filePath, purpose: purpose);
  }

  // Decrypt file path
  Future<String> decryptFilePath(String encryptedPath, {String purpose = 'file_paths'}) async {
    return decryptText(encryptedPath, purpose: purpose);
  }
}
