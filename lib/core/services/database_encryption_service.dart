import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/aes_encryption_service.dart';
import '../utils/error_utils.dart';

class DatabaseEncryptionService {
  final AESEncryptionService _encryptionService;
  
  // Categories for different types of sensitive data
  static const String _medicineNotesCategory = 'medicine_notes';
  static const String _medicineInstructionsCategory = 'medicine_instructions';
  static const String _prescriptionNotesCategory = 'prescription_notes';
  static const String _prescriptionDoctorInfoCategory = 'prescription_doctor_info';
  static const String _prescriptionClinicInfoCategory = 'prescription_clinic_info';
  static const String _followUpNotesCategory = 'follow_up_notes';
  static const String _followUpDoctorInfoCategory = 'follow_up_doctor_info';
  static const String _followUpClinicInfoCategory = 'follow_up_clinic_info';
  static const String _followUpLocationCategory = 'follow_up_location';
  static const String _reminderLogNotesCategory = 'reminder_log_notes';
  
  DatabaseEncryptionService()
      : _encryptionService = AESEncryptionService(const FlutterSecureStorage());
  
  // Encrypt medicine sensitive fields
  Future<Map<String, dynamic>> encryptMedicine(Map<String, dynamic> medicineMap) async {
    final encryptedMap = Map<String, dynamic>.from(medicineMap);
    
    // Encrypt notes if present
    if (encryptedMap['notes'] != null && encryptedMap['notes'] is String) {
      final notes = encryptedMap['notes'] as String;
      if (notes.isNotEmpty) {
        encryptedMap['notes'] = await _encryptionService.encryptText(
          notes,
          purpose: _medicineNotesCategory,
        );
      }
    }
    
    // Encrypt instructions if present
    if (encryptedMap['instructions'] != null && encryptedMap['instructions'] is String) {
      final instructions = encryptedMap['instructions'] as String;
      if (instructions.isNotEmpty) {
        encryptedMap['instructions'] = await _encryptionService.encryptText(
          instructions,
          purpose: _medicineInstructionsCategory,
        );
      }
    }
    
    return encryptedMap;
  }
  
  // Decrypt medicine sensitive fields
  Future<Map<String, dynamic>> decryptMedicine(Map<String, dynamic> medicineMap) async {
    final decryptedMap = Map<String, dynamic>.from(medicineMap);
    
    // Decrypt notes if present and appears encrypted
    if (decryptedMap['notes'] != null && decryptedMap['notes'] is String) {
      final notes = decryptedMap['notes'] as String;
      if (notes.isNotEmpty && _encryptionService.isEncrypted(notes)) {
        try {
          decryptedMap['notes'] = await _encryptionService.decryptText(
            notes,
            purpose: _medicineNotesCategory,
          );
        } catch (e) {
          // If decryption fails, leave as is (might be plaintext from before encryption)
          ErrorUtils.logInfo('Failed to decrypt medicine notes: $e');
        }
      }
    }
    
    // Decrypt instructions if present and appears encrypted
    if (decryptedMap['instructions'] != null && decryptedMap['instructions'] is String) {
      final instructions = decryptedMap['instructions'] as String;
      if (instructions.isNotEmpty && _encryptionService.isEncrypted(instructions)) {
        try {
          decryptedMap['instructions'] = await _encryptionService.decryptText(
            instructions,
            purpose: _medicineInstructionsCategory,
          );
        } catch (e) {
          // If decryption fails, leave as is (might be plaintext from before encryption)
          ErrorUtils.logInfo('Failed to decrypt medicine instructions: $e');
        }
      }
    }
    
    return decryptedMap;
  }
  
  // Encrypt prescription sensitive fields
  Future<Map<String, dynamic>> encryptPrescription(Map<String, dynamic> prescriptionMap) async {
    final encryptedMap = Map<String, dynamic>.from(prescriptionMap);
    
    // Encrypt notes if present
    if (encryptedMap['notes'] != null && encryptedMap['notes'] is String) {
      final notes = encryptedMap['notes'] as String;
      if (notes.isNotEmpty) {
        encryptedMap['notes'] = await _encryptionService.encryptText(
          notes,
          purpose: _prescriptionNotesCategory,
        );
      }
    }
    
    // Encrypt doctor name if present
    if (encryptedMap['doctor_name'] != null && encryptedMap['doctor_name'] is String) {
      final doctorName = encryptedMap['doctor_name'] as String;
      if (doctorName.isNotEmpty) {
        encryptedMap['doctor_name'] = await _encryptionService.encryptText(
          doctorName,
          purpose: _prescriptionDoctorInfoCategory,
        );
      }
    }
    
    // Encrypt clinic name if present
    if (encryptedMap['clinic_name'] != null && encryptedMap['clinic_name'] is String) {
      final clinicName = encryptedMap['clinic_name'] as String;
      if (clinicName.isNotEmpty) {
        encryptedMap['clinic_name'] = await _encryptionService.encryptText(
          clinicName,
          purpose: _prescriptionClinicInfoCategory,
        );
      }
    }
    
    return encryptedMap;
  }
  
  // Decrypt prescription sensitive fields
  Future<Map<String, dynamic>> decryptPrescription(Map<String, dynamic> prescriptionMap) async {
    final decryptedMap = Map<String, dynamic>.from(prescriptionMap);
    
    // Decrypt notes if present and appears encrypted
    if (decryptedMap['notes'] != null && decryptedMap['notes'] is String) {
      final notes = decryptedMap['notes'] as String;
      if (notes.isNotEmpty && _encryptionService.isEncrypted(notes)) {
        try {
          decryptedMap['notes'] = await _encryptionService.decryptText(
            notes,
            purpose: _prescriptionNotesCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt prescription notes: $e');
        }
      }
    }
    
    // Decrypt doctor name if present and appears encrypted
    if (decryptedMap['doctor_name'] != null && decryptedMap['doctor_name'] is String) {
      final doctorName = decryptedMap['doctor_name'] as String;
      if (doctorName.isNotEmpty && _encryptionService.isEncrypted(doctorName)) {
        try {
          decryptedMap['doctor_name'] = await _encryptionService.decryptText(
            doctorName,
            purpose: _prescriptionDoctorInfoCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt prescription doctor name: $e');
        }
      }
    }
    
    // Decrypt clinic name if present and appears encrypted
    if (decryptedMap['clinic_name'] != null && decryptedMap['clinic_name'] is String) {
      final clinicName = decryptedMap['clinic_name'] as String;
      if (clinicName.isNotEmpty && _encryptionService.isEncrypted(clinicName)) {
        try {
          decryptedMap['clinic_name'] = await _encryptionService.decryptText(
            clinicName,
            purpose: _prescriptionClinicInfoCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt prescription clinic name: $e');
        }
      }
    }
    
    return decryptedMap;
  }
  
  // Encrypt follow-up sensitive fields
  Future<Map<String, dynamic>> encryptFollowUp(Map<String, dynamic> followUpMap) async {
    final encryptedMap = Map<String, dynamic>.from(followUpMap);
    
    // Encrypt notes if present
    if (encryptedMap['notes'] != null && encryptedMap['notes'] is String) {
      final notes = encryptedMap['notes'] as String;
      if (notes.isNotEmpty) {
        encryptedMap['notes'] = await _encryptionService.encryptText(
          notes,
          purpose: _followUpNotesCategory,
        );
      }
    }
    
    // Encrypt doctor name if present
    if (encryptedMap['doctor_name'] != null && encryptedMap['doctor_name'] is String) {
      final doctorName = encryptedMap['doctor_name'] as String;
      if (doctorName.isNotEmpty) {
        encryptedMap['doctor_name'] = await _encryptionService.encryptText(
          doctorName,
          purpose: _followUpDoctorInfoCategory,
        );
      }
    }
    
    // Encrypt clinic name if present
    if (encryptedMap['clinic_name'] != null && encryptedMap['clinic_name'] is String) {
      final clinicName = encryptedMap['clinic_name'] as String;
      if (clinicName.isNotEmpty) {
        encryptedMap['clinic_name'] = await _encryptionService.encryptText(
          clinicName,
          purpose: _followUpClinicInfoCategory,
        );
      }
    }
    
    // Encrypt location if present
    if (encryptedMap['location'] != null && encryptedMap['location'] is String) {
      final location = encryptedMap['location'] as String;
      if (location.isNotEmpty) {
        encryptedMap['location'] = await _encryptionService.encryptText(
          location,
          purpose: _followUpLocationCategory,
        );
      }
    }
    
    return encryptedMap;
  }
  
  // Decrypt follow-up sensitive fields
  Future<Map<String, dynamic>> decryptFollowUp(Map<String, dynamic> followUpMap) async {
    final decryptedMap = Map<String, dynamic>.from(followUpMap);
    
    // Decrypt notes if present and appears encrypted
    if (decryptedMap['notes'] != null && decryptedMap['notes'] is String) {
      final notes = decryptedMap['notes'] as String;
      if (notes.isNotEmpty && _encryptionService.isEncrypted(notes)) {
        try {
          decryptedMap['notes'] = await _encryptionService.decryptText(
            notes,
            purpose: _followUpNotesCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt follow-up notes: $e');
        }
      }
    }
    
    // Decrypt doctor name if present and appears encrypted
    if (decryptedMap['doctor_name'] != null && decryptedMap['doctor_name'] is String) {
      final doctorName = decryptedMap['doctor_name'] as String;
      if (doctorName.isNotEmpty && _encryptionService.isEncrypted(doctorName)) {
        try {
          decryptedMap['doctor_name'] = await _encryptionService.decryptText(
            doctorName,
            purpose: _followUpDoctorInfoCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt follow-up doctor name: $e');
        }
      }
    }
    
    // Decrypt clinic name if present and appears encrypted
    if (decryptedMap['clinic_name'] != null && decryptedMap['clinic_name'] is String) {
      final clinicName = decryptedMap['clinic_name'] as String;
      if (clinicName.isNotEmpty && _encryptionService.isEncrypted(clinicName)) {
        try {
          decryptedMap['clinic_name'] = await _encryptionService.decryptText(
            clinicName,
            purpose: _followUpClinicInfoCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt follow-up clinic name: $e');
        }
      }
    }
    
    // Decrypt location if present and appears encrypted
    if (decryptedMap['location'] != null && decryptedMap['location'] is String) {
      final location = decryptedMap['location'] as String;
      if (location.isNotEmpty && _encryptionService.isEncrypted(location)) {
        try {
          decryptedMap['location'] = await _encryptionService.decryptText(
            location,
            purpose: _followUpLocationCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt follow-up location: $e');
        }
      }
    }
    
    return decryptedMap;
  }
  
  // Encrypt reminder log sensitive fields
  Future<Map<String, dynamic>> encryptReminderLog(Map<String, dynamic> reminderLogMap) async {
    final encryptedMap = Map<String, dynamic>.from(reminderLogMap);
    
    // Encrypt notes if present
    if (encryptedMap['notes'] != null && encryptedMap['notes'] is String) {
      final notes = encryptedMap['notes'] as String;
      if (notes.isNotEmpty) {
        encryptedMap['notes'] = await _encryptionService.encryptText(
          notes,
          purpose: _reminderLogNotesCategory,
        );
      }
    }
    
    return encryptedMap;
  }
  
  // Decrypt reminder log sensitive fields
  Future<Map<String, dynamic>> decryptReminderLog(Map<String, dynamic> reminderLogMap) async {
    final decryptedMap = Map<String, dynamic>.from(reminderLogMap);
    
    // Decrypt notes if present and appears encrypted
    if (decryptedMap['notes'] != null && decryptedMap['notes'] is String) {
      final notes = decryptedMap['notes'] as String;
      if (notes.isNotEmpty && _encryptionService.isEncrypted(notes)) {
        try {
          decryptedMap['notes'] = await _encryptionService.decryptText(
            notes,
            purpose: _reminderLogNotesCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt reminder log notes: $e');
        }
      }
    }
    
    return decryptedMap;
  }
  
  // Batch encrypt medicines
  Future<List<Map<String, dynamic>>> batchEncryptMedicines(List<Map<String, dynamic>> medicineMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final medicineMap in medicineMaps) {
      final encrypted = await encryptMedicine(medicineMap);
      results.add(encrypted);
    }
    
    return results;
  }
  
  // Batch decrypt medicines
  Future<List<Map<String, dynamic>>> batchDecryptMedicines(List<Map<String, dynamic>> medicineMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final medicineMap in medicineMaps) {
      final decrypted = await decryptMedicine(medicineMap);
      results.add(decrypted);
    }
    
    return results;
  }
  
  // Batch encrypt prescriptions
  Future<List<Map<String, dynamic>>> batchEncryptPrescriptions(List<Map<String, dynamic>> prescriptionMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final prescriptionMap in prescriptionMaps) {
      final encrypted = await encryptPrescription(prescriptionMap);
      results.add(encrypted);
    }
    
    return results;
  }
  
  // Batch decrypt prescriptions
  Future<List<Map<String, dynamic>>> batchDecryptPrescriptions(List<Map<String, dynamic>> prescriptionMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final prescriptionMap in prescriptionMaps) {
      final decrypted = await decryptPrescription(prescriptionMap);
      results.add(decrypted);
    }
    
    return results;
  }
  
  // Batch encrypt follow-ups
  Future<List<Map<String, dynamic>>> batchEncryptFollowUps(List<Map<String, dynamic>> followUpMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final followUpMap in followUpMaps) {
      final encrypted = await encryptFollowUp(followUpMap);
      results.add(encrypted);
    }
    
    return results;
  }
  
  // Batch decrypt follow-ups
  Future<List<Map<String, dynamic>>> batchDecryptFollowUps(List<Map<String, dynamic>> followUpMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final followUpMap in followUpMaps) {
      final decrypted = await decryptFollowUp(followUpMap);
      results.add(decrypted);
    }
    
    return results;
  }
  
  // Batch encrypt reminder logs
  Future<List<Map<String, dynamic>>> batchEncryptReminderLogs(List<Map<String, dynamic>> reminderLogMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final reminderLogMap in reminderLogMaps) {
      final encrypted = await encryptReminderLog(reminderLogMap);
      results.add(encrypted);
    }
    
    return results;
  }
  
  // Batch decrypt reminder logs
  Future<List<Map<String, dynamic>>> batchDecryptReminderLogs(List<Map<String, dynamic>> reminderLogMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final reminderLogMap in reminderLogMaps) {
      final decrypted = await decryptReminderLog(reminderLogMap);
      results.add(decrypted);
    }
    
    return results;
  }
  
  // Check if encryption is available
  Future<bool> isEncryptionAvailable() async {
    return await _encryptionService.isEncryptionAvailable();
  }
  
  // Get encryption status
  Future<Map<String, dynamic>> getEncryptionStatus() async {
    return await _encryptionService.getEncryptionStatus();
  }
  
  // Clear all encryption keys (for testing/reset)
  Future<void> clearAllKeys() async {
    await _encryptionService.clearAllKeys();
  }
  
  // Check if data is encrypted
  bool isFieldEncrypted(String? value) {
    if (value == null || value.isEmpty) return false;
    return _encryptionService.isEncrypted(value);
  }
  
  // Get list of encrypted fields for each entity type
  Map<String, List<String>> getEncryptedFieldsByEntity() {
    return {
      'medicine': ['notes', 'instructions'],
      'prescription': ['notes', 'doctor_name', 'clinic_name'],
      'follow_up': ['notes', 'doctor_name', 'clinic_name', 'location'],
      'reminder_log': ['notes'],
    };
  }
}