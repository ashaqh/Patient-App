import '../../domain/entities/prescription.dart';
import '../../domain/repositories/prescription_repository.dart';
import '../datasources/prescription_data_source.dart';
import '../datasources/database_helper.dart';

class PrescriptionRepositoryImpl implements PrescriptionRepository {
  final PrescriptionDataSource _prescriptionDataSource;

  PrescriptionRepositoryImpl(DatabaseHelper databaseHelper)
      : _prescriptionDataSource = PrescriptionDataSource(databaseHelper);

  @override
  Future<String> createPrescription(Prescription prescription) {
    return _prescriptionDataSource.createPrescription(prescription);
  }

  @override
  Future<Prescription?> getPrescriptionById(String id) {
    return _prescriptionDataSource.getPrescriptionById(id);
  }

  @override
  Future<List<Prescription>> getAllPrescriptions({String? orderBy}) {
    return _prescriptionDataSource.getAllPrescriptions(orderBy: orderBy);
  }

  @override
  Future<List<Prescription>> getPrescriptionsByDateRange(DateTime startDate, DateTime endDate) {
    return _prescriptionDataSource.getPrescriptionsByDateRange(startDate, endDate);
  }

  @override
  Future<List<Prescription>> getPrescriptionsByDoctor(String doctorName) {
    return _prescriptionDataSource.getPrescriptionsByDoctor(doctorName);
  }

  @override
  Future<List<Prescription>> getRecentPrescriptions({int limit = 10}) {
    return _prescriptionDataSource.getRecentPrescriptions(limit: limit);
  }

  @override
  Future<int> updatePrescription(Prescription prescription) {
    return _prescriptionDataSource.updatePrescription(prescription);
  }

  @override
  Future<int> deletePrescriptionById(String id) {
    return _prescriptionDataSource.deletePrescriptionById(id);
  }

  @override
  Future<int> deleteAllPrescriptions() {
    return _prescriptionDataSource.deleteAllPrescriptions();
  }

  @override
  Future<List<Prescription>> searchPrescriptions(String query) {
    return _prescriptionDataSource.searchPrescriptions(query);
  }

  @override
  Future<int> getPrescriptionCount() {
    return _prescriptionDataSource.getPrescriptionCount();
  }

  @override
  Future<List<Prescription>> getPrescriptionsByFileType(String fileType) {
    return _prescriptionDataSource.getPrescriptionsByFileType(fileType);
  }

  @override
  Future<List<Prescription>> getImagePrescriptions() {
    return _prescriptionDataSource.getImagePrescriptions();
  }

  @override
  Future<List<Prescription>> getPdfPrescriptions() {
    return _prescriptionDataSource.getPdfPrescriptions();
  }

  @override
  Future<List<Prescription>> getDocumentPrescriptions() {
    return _prescriptionDataSource.getDocumentPrescriptions();
  }

  @override
  Future<List<Prescription>> getPrescriptionsForMonth(int year, int month) {
    return _prescriptionDataSource.getPrescriptionsForMonth(year, month);
  }

  @override
  Future<List<Prescription>> getPrescriptionsForCurrentMonth() {
    return _prescriptionDataSource.getPrescriptionsForCurrentMonth();
  }

  @override
  Future<void> batchInsertPrescriptions(List<Prescription> prescriptions) {
    return _prescriptionDataSource.batchInsertPrescriptions(prescriptions);
  }

  @override
  Future<void> batchUpdatePrescriptions(List<Prescription> prescriptions) {
    return _prescriptionDataSource.batchUpdatePrescriptions(prescriptions);
  }

  @override
  Future<Map<String, List<Prescription>>> getPrescriptionsGroupedByMonth() {
    return _prescriptionDataSource.getPrescriptionsGroupedByMonth();
  }

  @override
  Future<Map<String, List<Prescription>>> getPrescriptionsGroupedByDoctor() {
    return _prescriptionDataSource.getPrescriptionsGroupedByDoctor();
  }
}