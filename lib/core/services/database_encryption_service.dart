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
  static const String _vitalSignNotesCategory = 'vital_sign_notes';
  static const String _vitalSignContextCategory = 'vital_sign_context';
  
  // Audit log sensitive fields categories
  static const String _auditLogErrorMessageCategory = 'audit_log_error_message';
  static const String _auditLogBeforeStateCategory = 'audit_log_before_state';
  static const String _auditLogAfterStateCategory = 'audit_log_after_state';
  static const String _auditLogDetailsCategory = 'audit_log_details';
  static const String _auditLogIpAddressCategory = 'audit_log_ip_address';
  static const String _auditLogDeviceInfoCategory = 'audit_log_device_info';
  static const String _auditLogLocationCategory = 'audit_log_location';
  
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
  
  // Encrypt vital sign sensitive fields
  Future<Map<String, dynamic>> encryptVitalSign(Map<String, dynamic> vitalSignMap) async {
    final encryptedMap = Map<String, dynamic>.from(vitalSignMap);
    
    // Encrypt notes if present
    if (encryptedMap['notes'] != null && encryptedMap['notes'] is String) {
      final notes = encryptedMap['notes'] as String;
      if (notes.isNotEmpty) {
        encryptedMap['notes'] = await _encryptionService.encryptText(
          notes,
          purpose: _vitalSignNotesCategory,
        );
      }
    }
    
    // Encrypt context if present
    if (encryptedMap['context'] != null && encryptedMap['context'] is String) {
      final context = encryptedMap['context'] as String;
      if (context.isNotEmpty) {
        encryptedMap['context'] = await _encryptionService.encryptText(
          context,
          purpose: _vitalSignContextCategory,
        );
      }
    }
    
    return encryptedMap;
  }
  
  // Decrypt vital sign sensitive fields
  Future<Map<String, dynamic>> decryptVitalSign(Map<String, dynamic> vitalSignMap) async {
    final decryptedMap = Map<String, dynamic>.from(vitalSignMap);
    
    // Decrypt notes if present and appears encrypted
    if (decryptedMap['notes'] != null && decryptedMap['notes'] is String) {
      final notes = decryptedMap['notes'] as String;
      if (notes.isNotEmpty && _encryptionService.isEncrypted(notes)) {
        try {
          decryptedMap['notes'] = await _encryptionService.decryptText(
            notes,
            purpose: _vitalSignNotesCategory,
          );
        } catch (e) {
          // If decryption fails, leave as is (might be plaintext from before encryption)
          ErrorUtils.logInfo('Failed to decrypt vital sign notes: $e');
        }
      }
    }
    
    // Decrypt context if present and appears encrypted
    if (decryptedMap['context'] != null && decryptedMap['context'] is String) {
      final context = decryptedMap['context'] as String;
      if (context.isNotEmpty && _encryptionService.isEncrypted(context)) {
        try {
          decryptedMap['context'] = await _encryptionService.decryptText(
            context,
            purpose: _vitalSignContextCategory,
          );
        } catch (e) {
          // If decryption fails, leave as is (might be plaintext from before encryption)
          ErrorUtils.logInfo('Failed to decrypt vital sign context: $e');
        }
      }
    }
    
    return decryptedMap;
  }
  
  // Batch encrypt vital signs
  Future<List<Map<String, dynamic>>> batchEncryptVitalSigns(List<Map<String, dynamic>> vitalSignMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final vitalSignMap in vitalSignMaps) {
      final encrypted = await encryptVitalSign(vitalSignMap);
      results.add(encrypted);
    }
    
    return results;
  }
  
  // Batch decrypt vital signs
  Future<List<Map<String, dynamic>>> batchDecryptVitalSigns(List<Map<String, dynamic>> vitalSignMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final vitalSignMap in vitalSignMaps) {
      final decrypted = await decryptVitalSign(vitalSignMap);
      results.add(decrypted);
    }
    
    return results;
  }
  
  // Encrypt audit log sensitive fields
  Future<Map<String, dynamic>> encryptAuditLog(Map<String, dynamic> auditLogMap) async {
    final encryptedMap = Map<String, dynamic>.from(auditLogMap);
    
    // Encrypt error message if present
    if (encryptedMap['error_message'] != null && encryptedMap['error_message'] is String) {
      final errorMessage = encryptedMap['error_message'] as String;
      if (errorMessage.isNotEmpty) {
        encryptedMap['error_message'] = await _encryptionService.encryptText(
          errorMessage,
          purpose: _auditLogErrorMessageCategory,
        );
      }
    }
    
    // Encrypt before state if present
    if (encryptedMap['before_state'] != null && encryptedMap['before_state'] is String) {
      final beforeState = encryptedMap['before_state'] as String;
      if (beforeState.isNotEmpty) {
        encryptedMap['before_state'] = await _encryptionService.encryptText(
          beforeState,
          purpose: _auditLogBeforeStateCategory,
        );
      }
    }
    
    // Encrypt after state if present
    if (encryptedMap['after_state'] != null && encryptedMap['after_state'] is String) {
      final afterState = encryptedMap['after_state'] as String;
      if (afterState.isNotEmpty) {
        encryptedMap['after_state'] = await _encryptionService.encryptText(
          afterState,
          purpose: _auditLogAfterStateCategory,
        );
      }
    }
    
    // Encrypt details if present
    if (encryptedMap['details'] != null && encryptedMap['details'] is String) {
      final details = encryptedMap['details'] as String;
      if (details.isNotEmpty) {
        encryptedMap['details'] = await _encryptionService.encryptText(
          details,
          purpose: _auditLogDetailsCategory,
        );
      }
    }
    
    // Encrypt IP address if present
    if (encryptedMap['ip_address'] != null && encryptedMap['ip_address'] is String) {
      final ipAddress = encryptedMap['ip_address'] as String;
      if (ipAddress.isNotEmpty) {
        encryptedMap['ip_address'] = await _encryptionService.encryptText(
          ipAddress,
          purpose: _auditLogIpAddressCategory,
        );
      }
    }
    
    // Encrypt device info (combined device_id and device_name for efficiency)
    final deviceId = encryptedMap['device_id'] as String?;
    final deviceName = encryptedMap['device_name'] as String?;
    if ((deviceId != null && deviceId.isNotEmpty) || (deviceName != null && deviceName.isNotEmpty)) {
      final deviceInfo = '${deviceId ?? ''}|${deviceName ?? ''}';
      if (deviceInfo.isNotEmpty && deviceInfo != '|') {
        final encryptedDeviceInfo = await _encryptionService.encryptText(
          deviceInfo,
          purpose: _auditLogDeviceInfoCategory,
        );
        encryptedMap['device_id'] = deviceId != null && deviceId.isNotEmpty ? encryptedDeviceInfo : null;
        encryptedMap['device_name'] = deviceName != null && deviceName.isNotEmpty ? encryptedDeviceInfo : null;
      }
    }
    
    // Encrypt location if present
    if (encryptedMap['location'] != null && encryptedMap['location'] is String) {
      final location = encryptedMap['location'] as String;
      if (location.isNotEmpty) {
        encryptedMap['location'] = await _encryptionService.encryptText(
          location,
          purpose: _auditLogLocationCategory,
        );
      }
    }
    
    return encryptedMap;
  }
  
  // Decrypt audit log sensitive fields
  Future<Map<String, dynamic>> decryptAuditLog(Map<String, dynamic> auditLogMap) async {
    final decryptedMap = Map<String, dynamic>.from(auditLogMap);
    
    // Decrypt error message if present and appears encrypted
    if (decryptedMap['error_message'] != null && decryptedMap['error_message'] is String) {
      final errorMessage = decryptedMap['error_message'] as String;
      if (errorMessage.isNotEmpty && _encryptionService.isEncrypted(errorMessage)) {
        try {
          decryptedMap['error_message'] = await _encryptionService.decryptText(
            errorMessage,
            purpose: _auditLogErrorMessageCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt audit log error message: $e');
        }
      }
    }
    
    // Decrypt before state if present and appears encrypted
    if (decryptedMap['before_state'] != null && decryptedMap['before_state'] is String) {
      final beforeState = decryptedMap['before_state'] as String;
      if (beforeState.isNotEmpty && _encryptionService.isEncrypted(beforeState)) {
        try {
          decryptedMap['before_state'] = await _encryptionService.decryptText(
            beforeState,
            purpose: _auditLogBeforeStateCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt audit log before state: $e');
        }
      }
    }
    
    // Decrypt after state if present and appears encrypted
    if (decryptedMap['after_state'] != null && decryptedMap['after_state'] is String) {
      final afterState = decryptedMap['after_state'] as String;
      if (afterState.isNotEmpty && _encryptionService.isEncrypted(afterState)) {
        try {
          decryptedMap['after_state'] = await _encryptionService.decryptText(
            afterState,
            purpose: _auditLogAfterStateCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt audit log after state: $e');
        }
      }
    }
    
    // Decrypt details if present and appears encrypted
    if (decryptedMap['details'] != null && decryptedMap['details'] is String) {
      final details = decryptedMap['details'] as String;
      if (details.isNotEmpty && _encryptionService.isEncrypted(details)) {
        try {
          decryptedMap['details'] = await _encryptionService.decryptText(
            details,
            purpose: _auditLogDetailsCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt audit log details: $e');
        }
      }
    }
    
    // Decrypt IP address if present and appears encrypted
    if (decryptedMap['ip_address'] != null && decryptedMap['ip_address'] is String) {
      final ipAddress = decryptedMap['ip_address'] as String;
      if (ipAddress.isNotEmpty && _encryptionService.isEncrypted(ipAddress)) {
        try {
          decryptedMap['ip_address'] = await _encryptionService.decryptText(
            ipAddress,
            purpose: _auditLogIpAddressCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt audit log IP address: $e');
        }
      }
    }
    
    // Decrypt device info
    if (decryptedMap['device_id'] != null && decryptedMap['device_id'] is String) {
      final deviceInfo = decryptedMap['device_id'] as String;
      if (deviceInfo.isNotEmpty && _encryptionService.isEncrypted(deviceInfo)) {
        try {
          final decryptedDeviceInfo = await _encryptionService.decryptText(
            deviceInfo,
            purpose: _auditLogDeviceInfoCategory,
          );
          final parts = decryptedDeviceInfo.split('|');
          if (parts.length >= 2) {
            decryptedMap['device_id'] = parts[0].isNotEmpty ? parts[0] : null;
            decryptedMap['device_name'] = parts[1].isNotEmpty ? parts[1] : null;
          }
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt audit log device info: $e');
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
            purpose: _auditLogLocationCategory,
          );
        } catch (e) {
          ErrorUtils.logInfo('Failed to decrypt audit log location: $e');
        }
      }
    }
    
    return decryptedMap;
  }
  
  // Batch encrypt audit logs
  Future<List<Map<String, dynamic>>> batchEncryptAuditLogs(List<Map<String, dynamic>> auditLogMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final auditLogMap in auditLogMaps) {
      final encrypted = await encryptAuditLog(auditLogMap);
      results.add(encrypted);
    }
    
    return results;
  }
  
  // Batch decrypt audit logs
  Future<List<Map<String, dynamic>>> batchDecryptAuditLogs(List<Map<String, dynamic>> auditLogMaps) async {
    final results = <Map<String, dynamic>>[];
    
    for (final auditLogMap in auditLogMaps) {
      final decrypted = await decryptAuditLog(auditLogMap);
      results.add(decrypted);
    }
    
    return results;
  }
  
  // Get list of encrypted fields for each entity type
  Map<String, List<String>> getEncryptedFieldsByEntity() {
    return {
      'medicine': ['notes', 'instructions'],
      'prescription': ['notes', 'doctor_name', 'clinic_name'],
      'follow_up': ['notes', 'doctor_name', 'clinic_name', 'location'],
      'reminder_log': ['notes'],
      'vital_sign': ['notes', 'context'],
      'audit_log': ['error_message', 'before_state', 'after_state', 'details', 'ip_address', 'device_id', 'device_name', 'location'],
    };
  }
}