import '../entities/medicine.dart';

abstract class MedicineRepository {
  // Create a new medicine
  Future<String> createMedicine(Medicine medicine);
  
  // Get medicine by ID
  Future<Medicine?> getMedicineById(String id);
  
  // Get all medicines
  Future<List<Medicine>> getAllMedicines({bool activeOnly = false});
  
  // Get active medicines
  Future<List<Medicine>> getActiveMedicines();
  
  // Get medicines for today
  Future<List<Medicine>> getMedicinesForToday();
  
  // Get medicines by date range
  Future<List<Medicine>> getMedicinesByDateRange(DateTime startDate, DateTime endDate);
  
  // Update medicine
  Future<int> updateMedicine(Medicine medicine);
  
  // Delete medicine by ID
  Future<int> deleteMedicineById(String id);
  
  // Delete all medicines
  Future<int> deleteAllMedicines();
  
  // Search medicines by name
  Future<List<Medicine>> searchMedicines(String query);
  
  // Get medicine count
  Future<int> getMedicineCount({bool activeOnly = false});
  
  // Toggle medicine active status
  Future<int> toggleMedicineStatus(String id, bool isActive);
  
  // Get medicines that need reminders today
  Future<List<Medicine>> getMedicinesNeedingRemindersToday();
  
  // Batch insert medicines
  Future<void> batchInsertMedicines(List<Medicine> medicines);
  
  // Update multiple medicines
  Future<void> batchUpdateMedicines(List<Medicine> medicines);
}
