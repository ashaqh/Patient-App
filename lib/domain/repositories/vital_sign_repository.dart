import '../entities/vital_sign.dart';

abstract class VitalSignRepository {
  // Create a new vital sign entry
  Future<String> createVitalSign(VitalSign vitalSign);
  
  // Get vital sign by ID
  Future<VitalSign?> getVitalSignById(String id);
  
  // Get all vital signs
  Future<List<VitalSign>> getAllVitalSigns();
  
  // Get vital signs by type
  Future<List<VitalSign>> getVitalSignsByType(VitalSignType type);
  
  // Get vital signs by date range
  Future<List<VitalSign>> getVitalSignsByDateRange(DateTime startDate, DateTime endDate);
  
  // Get vital signs by type and date range
  Future<List<VitalSign>> getVitalSignsByTypeAndDateRange(
    VitalSignType type, 
    DateTime startDate, 
    DateTime endDate
  );
  
  // Get latest vital sign by type
  Future<VitalSign?> getLatestVitalSignByType(VitalSignType type);
  
  // Get vital signs for today
  Future<List<VitalSign>> getTodaysVitalSigns();
  
  // Get vital signs for last 7 days
  Future<List<VitalSign>> getLast7DaysVitalSigns();
  
  // Get vital signs for last 30 days
  Future<List<VitalSign>> getLast30DaysVitalSigns();
  
  // Update vital sign
  Future<int> updateVitalSign(VitalSign vitalSign);
  
  // Delete vital sign by ID
  Future<int> deleteVitalSignById(String id);
  
  // Delete all vital signs
  Future<int> deleteAllVitalSigns();
  
  // Delete vital signs by type
  Future<int> deleteVitalSignsByType(VitalSignType type);
  
  // Get vital sign count
  Future<int> getVitalSignCount({VitalSignType? type});
  
  // Get statistics for a specific type
  Future<Map<String, dynamic>> getVitalSignStatistics(
    VitalSignType type,
    DateTime startDate,
    DateTime endDate
  );
  
  // Get trends for a specific type
  Future<List<Map<String, dynamic>>> getVitalSignTrends(
    VitalSignType type,
    int days
  );
  
  // Check if vital sign is abnormal
  Future<bool> isAbnormalVitalSign(VitalSign vitalSign);
  
  // Get abnormal vital signs
  Future<List<VitalSign>> getAbnormalVitalSigns(DateTime startDate, DateTime endDate);
  
  // Batch insert vital signs
  Future<void> batchInsertVitalSigns(List<VitalSign> vitalSigns);
  
  // Update multiple vital signs
  Future<void> batchUpdateVitalSigns(List<VitalSign> vitalSigns);
}
