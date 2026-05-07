import '../entities/prescription.dart';

abstract class PrescriptionRepository {
  // Create a new prescription
  Future<String> createPrescription(Prescription prescription);
  
  // Get prescription by ID
  Future<Prescription?> getPrescriptionById(String id);
  
  // Get all prescriptions
  Future<List<Prescription>> getAllPrescriptions({String? orderBy});
  
  // Get prescriptions by date range
  Future<List<Prescription>> getPrescriptionsByDateRange(DateTime startDate, DateTime endDate);
  
  // Get prescriptions by doctor name
  Future<List<Prescription>> getPrescriptionsByDoctor(String doctorName);
  
  // Get recent prescriptions
  Future<List<Prescription>> getRecentPrescriptions({int limit = 10});
  
  // Update prescription
  Future<int> updatePrescription(Prescription prescription);
  
  // Delete prescription by ID
  Future<int> deletePrescriptionById(String id);
  
  // Delete all prescriptions
  Future<int> deleteAllPrescriptions();
  
  // Search prescriptions
  Future<List<Prescription>> searchPrescriptions(String query);
  
// Get prescription count
  Future<int> getPrescriptionCount();

  // Get prescriptions by document type (prescription or test_report)
  Future<List<Prescription>> getPrescriptionsByDocumentType(String documentType);

  // Get prescriptions by file type
  Future<List<Prescription>> getPrescriptionsByFileType(String fileType);
  
  // Get image prescriptions
  Future<List<Prescription>> getImagePrescriptions();
  
  // Get PDF prescriptions
  Future<List<Prescription>> getPdfPrescriptions();
  
  // Get document prescriptions
  Future<List<Prescription>> getDocumentPrescriptions();
  
  // Get prescriptions for a specific month
  Future<List<Prescription>> getPrescriptionsForMonth(int year, int month);
  
  // Get prescriptions for current month
  Future<List<Prescription>> getPrescriptionsForCurrentMonth();
  
  // Batch insert prescriptions
  Future<void> batchInsertPrescriptions(List<Prescription> prescriptions);
  
  // Update multiple prescriptions
  Future<void> batchUpdatePrescriptions(List<Prescription> prescriptions);
  
  // Get prescriptions grouped by month
  Future<Map<String, List<Prescription>>> getPrescriptionsGroupedByMonth();
  
  // Get prescriptions grouped by doctor
  Future<Map<String, List<Prescription>>> getPrescriptionsGroupedByDoctor();
}
