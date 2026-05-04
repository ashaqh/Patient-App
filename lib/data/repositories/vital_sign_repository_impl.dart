import '../../domain/entities/vital_sign.dart';
import '../../domain/repositories/vital_sign_repository.dart';
import '../datasources/vital_sign_data_source.dart';
import '../datasources/database_helper.dart';

class VitalSignRepositoryImpl implements VitalSignRepository {
  final VitalSignDataSource _vitalSignDataSource;

  VitalSignRepositoryImpl(DatabaseHelper databaseHelper)
      : _vitalSignDataSource = VitalSignDataSource(databaseHelper);

  @override
  Future<String> createVitalSign(VitalSign vitalSign) {
    return _vitalSignDataSource.createVitalSign(vitalSign);
  }

  @override
  Future<VitalSign?> getVitalSignById(String id) {
    return _vitalSignDataSource.getVitalSignById(id);
  }

  @override
  Future<List<VitalSign>> getAllVitalSigns() {
    return _vitalSignDataSource.getAllVitalSigns();
  }

  @override
  Future<List<VitalSign>> getVitalSignsByType(VitalSignType type) {
    return _vitalSignDataSource.getVitalSignsByType(type);
  }

  @override
  Future<List<VitalSign>> getVitalSignsByDateRange(DateTime startDate, DateTime endDate) {
    return _vitalSignDataSource.getVitalSignsByDateRange(startDate, endDate);
  }

  @override
  Future<List<VitalSign>> getVitalSignsByTypeAndDateRange(
    VitalSignType type, 
    DateTime startDate, 
    DateTime endDate
  ) {
    return _vitalSignDataSource.getVitalSignsByTypeAndDateRange(type, startDate, endDate);
  }

  @override
  Future<VitalSign?> getLatestVitalSignByType(VitalSignType type) {
    return _vitalSignDataSource.getLatestVitalSignByType(type);
  }

  @override
  Future<List<VitalSign>> getTodaysVitalSigns() {
    return _vitalSignDataSource.getTodaysVitalSigns();
  }

  @override
  Future<List<VitalSign>> getLast7DaysVitalSigns() {
    return _vitalSignDataSource.getLast7DaysVitalSigns();
  }

  @override
  Future<List<VitalSign>> getLast30DaysVitalSigns() {
    return _vitalSignDataSource.getLast30DaysVitalSigns();
  }

  @override
  Future<int> updateVitalSign(VitalSign vitalSign) {
    return _vitalSignDataSource.updateVitalSign(vitalSign);
  }

  @override
  Future<int> deleteVitalSignById(String id) {
    return _vitalSignDataSource.deleteVitalSignById(id);
  }

  @override
  Future<int> deleteAllVitalSigns() {
    return _vitalSignDataSource.deleteAllVitalSigns();
  }

  @override
  Future<int> deleteVitalSignsByType(VitalSignType type) {
    return _vitalSignDataSource.deleteVitalSignsByType(type);
  }

  @override
  Future<int> getVitalSignCount({VitalSignType? type}) {
    return _vitalSignDataSource.getVitalSignCount(type: type);
  }

  @override
  Future<Map<String, dynamic>> getVitalSignStatistics(
    VitalSignType type,
    DateTime startDate,
    DateTime endDate
  ) {
    return _vitalSignDataSource.getVitalSignStatistics(type, startDate, endDate);
  }

  @override
  Future<List<Map<String, dynamic>>> getVitalSignTrends(
    VitalSignType type,
    int days
  ) {
    return _vitalSignDataSource.getVitalSignTrends(type, days);
  }

  @override
  Future<bool> isAbnormalVitalSign(VitalSign vitalSign) {
    return _vitalSignDataSource.isAbnormalVitalSign(vitalSign);
  }

  @override
  Future<List<VitalSign>> getAbnormalVitalSigns(DateTime startDate, DateTime endDate) {
    return _vitalSignDataSource.getAbnormalVitalSigns(startDate, endDate);
  }

  @override
  Future<void> batchInsertVitalSigns(List<VitalSign> vitalSigns) {
    return _vitalSignDataSource.batchInsertVitalSigns(vitalSigns);
  }

  @override
  Future<void> batchUpdateVitalSigns(List<VitalSign> vitalSigns) {
    return _vitalSignDataSource.batchUpdateVitalSigns(vitalSigns);
  }
}