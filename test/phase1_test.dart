// Simple test to verify Phase 1 implementation
// This tests the core data layer and basic UI structure

import 'package:flutter_test/flutter_test.dart';
import 'package:carevault/main.dart' as app;
import 'package:carevault/data/datasources/database_constants.dart';
import 'package:carevault/domain/entities/medicine.dart';
import 'package:carevault/data/datasources/database_helper.dart';

void main() {
  test('Phase 1: Core Data Layer Implementation', () {
    // Test that the app can be instantiated
    expect(() => app.main(), returnsNormally);
  });

  test('Phase 1: Database Constants Exist', () {
    expect(DatabaseConstants.databaseName, equals('carevault.db'));
    expect(DatabaseConstants.databaseVersion, equals(1));
    expect(DatabaseConstants.tableMedicines, equals('medicines'));
    expect(DatabaseConstants.tablePrescriptions, equals('prescriptions'));
    expect(DatabaseConstants.tableReminderLogs, equals('reminder_logs'));
    expect(DatabaseConstants.tableFollowUps, equals('follow_ups'));
  });

  test('Phase 1: Medicine Entity Structure', () {
    final medicine = Medicine(
      name: 'Test Medicine',
      dosage: '1 tablet',
      frequency: 'Once daily',
      times: ['08:00'],
      startDate: DateTime.now(),
    );
    
    expect(medicine.name, equals('Test Medicine'));
    expect(medicine.dosage, equals('1 tablet'));
    expect(medicine.frequency, equals('Once daily'));
    expect(medicine.times, equals(['08:00']));
    expect(medicine.isActive, equals(true));
    expect(medicine.id, isNotEmpty);
  });

  test('Phase 1: Database Helper Initialization', () {
    final dbHelper = DatabaseHelper();
    expect(dbHelper, isNotNull);
  });
}
