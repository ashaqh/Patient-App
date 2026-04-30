import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../datasources/medicine_data_source.dart';
import '../datasources/database_helper.dart';

class MedicineRepositoryImpl implements MedicineRepository {
  final MedicineDataSource _medicineDataSource;

  MedicineRepositoryImpl(DatabaseHelper databaseHelper)
      : _medicineDataSource = MedicineDataSource(databaseHelper);

  @override
  Future<String> createMedicine(Medicine medicine) {
    return _medicineDataSource.createMedicine(medicine);
  }

  @override
  Future<Medicine?> getMedicineById(String id) {
    return _medicineDataSource.getMedicineById(id);
  }

  @override
  Future<List<Medicine>> getAllMedicines({bool activeOnly = false}) {
    return _medicineDataSource.getAllMedicines(activeOnly: activeOnly);
  }

  @override
  Future<List<Medicine>> getActiveMedicines() {
    return _medicineDataSource.getActiveMedicines();
  }

  @override
  Future<List<Medicine>> getMedicinesForToday() {
    return _medicineDataSource.getMedicinesForToday();
  }

  @override
  Future<List<Medicine>> getMedicinesByDateRange(DateTime startDate, DateTime endDate) {
    return _medicineDataSource.getMedicinesByDateRange(startDate, endDate);
  }

  @override
  Future<int> updateMedicine(Medicine medicine) {
    return _medicineDataSource.updateMedicine(medicine);
  }

  @override
  Future<int> deleteMedicineById(String id) {
    return _medicineDataSource.deleteMedicineById(id);
  }

  @override
  Future<int> deleteAllMedicines() {
    return _medicineDataSource.deleteAllMedicines();
  }

  @override
  Future<List<Medicine>> searchMedicines(String query) {
    return _medicineDataSource.searchMedicines(query);
  }

  @override
  Future<int> getMedicineCount({bool activeOnly = false}) {
    return _medicineDataSource.getMedicineCount(activeOnly: activeOnly);
  }

  @override
  Future<int> toggleMedicineStatus(String id, bool isActive) {
    return _medicineDataSource.toggleMedicineStatus(id, isActive);
  }

  @override
  Future<List<Medicine>> getMedicinesNeedingRemindersToday() {
    return _medicineDataSource.getMedicinesNeedingRemindersToday();
  }

  @override
  Future<void> batchInsertMedicines(List<Medicine> medicines) {
    return _medicineDataSource.batchInsertMedicines(medicines);
  }

  @override
  Future<void> batchUpdateMedicines(List<Medicine> medicines) {
    return _medicineDataSource.batchUpdateMedicines(medicines);
  }
}