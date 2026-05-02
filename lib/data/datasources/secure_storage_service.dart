import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/utils/aes_encryption_service.dart';
import '../../core/utils/error_utils.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage;
  final AESEncryptionService _encryptionService;
  
  // Keys for different types of sensitive data
  static const String _userPreferencesKey = 'user_preferences';
  static const String _medicineNotesKey = 'medicine_notes';
  static const String _prescriptionNotesKey = 'prescription_notes';
  static const String _followUpNotesKey = 'follow_up_notes';
  static const String _doctorInfoKey = 'doctor_info';
  static const String _filePathsKey = 'file_paths';

  SecureStorageService()
      : _secureStorage = const FlutterSecureStorage(),
        _encryptionService = AESEncryptionService(const FlutterSecureStorage());

  // User preferences
  Future<void> saveUserPreference(String key, String value) async {
    final encryptedValue = await _encryptionService.encryptText(
      value,
      purpose: _userPreferencesKey,
    );
    await _secureStorage.write(key: '$_userPreferencesKey.$key', value: encryptedValue);
  }

  Future<String?> getUserPreference(String key) async {
    final encryptedValue = await _secureStorage.read(key: '$_userPreferencesKey.$key');
    if (encryptedValue == null) return null;
    
    return await _encryptionService.decryptText(
      encryptedValue,
      purpose: _userPreferencesKey,
    );
  }

  Future<void> deleteUserPreference(String key) async {
    await _secureStorage.delete(key: '$_userPreferencesKey.$key');
  }

  // Medicine notes (sensitive medical information)
  Future<void> saveMedicineNote(String medicineId, String note) async {
    final encryptedNote = await _encryptionService.encryptText(
      note,
      purpose: _medicineNotesKey,
    );
    await _secureStorage.write(key: '$_medicineNotesKey.$medicineId', value: encryptedNote);
  }

  Future<String?> getMedicineNote(String medicineId) async {
    final encryptedNote = await _secureStorage.read(key: '$_medicineNotesKey.$medicineId');
    if (encryptedNote == null) return null;
    
    return await _encryptionService.decryptText(
      encryptedNote,
      purpose: _medicineNotesKey,
    );
  }

  Future<void> deleteMedicineNote(String medicineId) async {
    await _secureStorage.delete(key: '$_medicineNotesKey.$medicineId');
  }

  // Prescription notes
  Future<void> savePrescriptionNote(String prescriptionId, String note) async {
    final encryptedNote = await _encryptionService.encryptText(
      note,
      purpose: _prescriptionNotesKey,
    );
    await _secureStorage.write(key: '$_prescriptionNotesKey.$prescriptionId', value: encryptedNote);
  }

  Future<String?> getPrescriptionNote(String prescriptionId) async {
    final encryptedNote = await _secureStorage.read(key: '$_prescriptionNotesKey.$prescriptionId');
    if (encryptedNote == null) return null;
    
    return await _encryptionService.decryptText(
      encryptedNote,
      purpose: _prescriptionNotesKey,
    );
  }

  Future<void> deletePrescriptionNote(String prescriptionId) async {
    await _secureStorage.delete(key: '$_prescriptionNotesKey.$prescriptionId');
  }

  // Follow-up notes
  Future<void> saveFollowUpNote(String followUpId, String note) async {
    final encryptedNote = await _encryptionService.encryptText(
      note,
      purpose: _followUpNotesKey,
    );
    await _secureStorage.write(key: '$_followUpNotesKey.$followUpId', value: encryptedNote);
  }

  Future<String?> getFollowUpNote(String followUpId) async {
    final encryptedNote = await _secureStorage.read(key: '$_followUpNotesKey.$followUpId');
    if (encryptedNote == null) return null;
    
    return await _encryptionService.decryptText(
      encryptedNote,
      purpose: _followUpNotesKey,
    );
  }

  Future<void> deleteFollowUpNote(String followUpId) async {
    await _secureStorage.delete(key: '$_followUpNotesKey.$followUpId');
  }

  // Doctor information (sensitive contact info)
  Future<void> saveDoctorInfo(String doctorId, Map<String, dynamic> info) async {
    final jsonString = _mapToJson(info);
    final encryptedInfo = await _encryptionService.encryptText(
      jsonString,
      purpose: _doctorInfoKey,
    );
    await _secureStorage.write(key: '$_doctorInfoKey.$doctorId', value: encryptedInfo);
  }

  Future<Map<String, dynamic>?> getDoctorInfo(String doctorId) async {
    final encryptedInfo = await _secureStorage.read(key: '$_doctorInfoKey.$doctorId');
    if (encryptedInfo == null) return null;
    
    final decryptedInfo = await _encryptionService.decryptText(
      encryptedInfo,
      purpose: _doctorInfoKey,
    );
    
    return _jsonToMap(decryptedInfo);
  }

  Future<void> deleteDoctorInfo(String doctorId) async {
    await _secureStorage.delete(key: '$_doctorInfoKey.$doctorId');
  }

  // File paths (encrypted file locations)
  Future<void> saveEncryptedFilePath(String fileId, String filePath) async {
    final encryptedPath = await _encryptionService.encryptFilePath(
      filePath,
      purpose: _filePathsKey,
    );
    await _secureStorage.write(key: '$_filePathsKey.$fileId', value: encryptedPath);
  }

  Future<String?> getEncryptedFilePath(String fileId) async {
    final encryptedPath = await _secureStorage.read(key: '$_filePathsKey.$fileId');
    if (encryptedPath == null) return null;
    
    return await _encryptionService.decryptFilePath(
      encryptedPath,
      purpose: _filePathsKey,
    );
  }

  Future<void> deleteEncryptedFilePath(String fileId) async {
    await _secureStorage.delete(key: '$_filePathsKey.$fileId');
  }

  // Generic secure storage methods
  Future<void> saveSecureData(String category, String key, String value) async {
    final encryptedValue = await _encryptionService.encryptText(
      value,
      purpose: category,
    );
    await _secureStorage.write(key: '$category.$key', value: encryptedValue);
  }

  Future<String?> getSecureData(String category, String key) async {
    final encryptedValue = await _secureStorage.read(key: '$category.$key');
    if (encryptedValue == null) return null;
    
    return await _encryptionService.decryptText(
      encryptedValue,
      purpose: category,
    );
  }

  Future<void> deleteSecureData(String category, String key) async {
    await _secureStorage.delete(key: '$category.$key');
  }

  // Clear all secure data
  Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
    await _encryptionService.clearAllKeys();
  }

  // Check if secure storage is available
  Future<bool> isSecureStorageAvailable() async {
    return await _encryptionService.isEncryptionAvailable();
  }

  // Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final allData = await _secureStorage.readAll();
    final encryptionStatus = await _encryptionService.getEncryptionStatus();
    
    // Count entries by category
    final categories = <String, int>{};
    for (final key in allData.keys) {
      final parts = key.split('.');
      if (parts.length > 1) {
        final category = parts[0];
        categories[category] = (categories[category] ?? 0) + 1;
      }
    }
    
    return {
      'total_entries': allData.length,
      'categories': categories,
      'encryption_status': encryptionStatus,
    };
  }

  // Backup secure data (returns encrypted backup string)
  Future<String> backupSecureData() async {
    final allData = await _secureStorage.readAll();
    final backupData = <String, String>{};
    
    // Create a backup with all data (already encrypted)
    for (final entry in allData.entries) {
      backupData[entry.key] = entry.value;
    }
    
    // Convert to JSON and encrypt the entire backup
    final jsonString = _mapToJson(backupData);
    return await _encryptionService.encryptText(jsonString, purpose: 'backup');
  }

  // Restore secure data from backup
  Future<bool> restoreSecureData(String encryptedBackup) async {
    try {
      // Decrypt the backup
      final decryptedBackup = await _encryptionService.decryptText(
        encryptedBackup,
        purpose: 'backup',
      );
      
      final backupData = _jsonToMap(decryptedBackup) as Map<String, dynamic>;
      
      // Clear existing data
      await _secureStorage.deleteAll();
      
      // Restore all entries
      for (final entry in backupData.entries) {
        if (entry.value is String) {
          await _secureStorage.write(key: entry.key, value: entry.value as String);
        }
      }
      
      return true;
    } catch (e) {
      ErrorUtils.logInfo('Failed to restore secure data: $e');
      return false;
    }
  }

  // Helper methods for JSON conversion
  String _mapToJson(Map<String, dynamic> map) {
    return const JsonEncoder().convert(map);
  }

  Map<String, dynamic> _jsonToMap(String jsonString) {
    final decoded = const JsonDecoder().convert(jsonString);
    return Map<String, dynamic>.from(decoded);
  }

  // Check if data exists for a key
  Future<bool> containsKey(String category, String key) async {
    return await _secureStorage.containsKey(key: '$category.$key');
  }

  // Get all keys for a category
  Future<List<String>> getKeysForCategory(String category) async {
    final allData = await _secureStorage.readAll();
    final keys = <String>[];
    
    for (final key in allData.keys) {
      if (key.startsWith('$category.')) {
        keys.add(key.substring(category.length + 1));
      }
    }
    
    return keys;
  }

  // Get all data for a category
  Future<Map<String, String>> getAllDataForCategory(String category) async {
    final allData = await _secureStorage.readAll();
    final categoryData = <String, String>{};
    
    for (final entry in allData.entries) {
      if (entry.key.startsWith('$category.')) {
        final key = entry.key.substring(category.length + 1);
        
        // Decrypt the value
        final decryptedValue = await _encryptionService.decryptText(
          entry.value,
          purpose: category,
        );
        
        categoryData[key] = decryptedValue;
      }
    }
    
    return categoryData;
  }
}