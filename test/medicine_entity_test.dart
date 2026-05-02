import 'package:flutter_test/flutter_test.dart';
import 'package:carevault/domain/entities/medicine.dart';

void main() {
  group('Medicine Entity', () {
    test('creates medicine with default values', () {
      final medicine = Medicine(
        name: 'Test Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      expect(medicine.name, 'Test Medicine');
      expect(medicine.dosage, '1 tablet');
      expect(medicine.frequency, 'Once daily');
      expect(medicine.times, ['08:00']);
      expect(medicine.startDate, DateTime(2024, 1, 1));
      expect(medicine.isActive, true);
      expect(medicine.id, isNotEmpty);
      expect(medicine.createdAt, isNotNull);
      expect(medicine.updatedAt, isNotNull);
    });

    test('creates medicine with custom id', () {
      final medicine = Medicine(
        id: 'custom-id-123',
        name: 'Test Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      expect(medicine.id, 'custom-id-123');
    });

    test('creates medicine with optional parameters', () {
      final endDate = DateTime(2024, 12, 31);
      final medicine = Medicine(
        name: 'Test Medicine',
        dosage: '1 tablet',
        frequency: 'Twice daily',
        times: ['08:00', '20:00'],
        startDate: DateTime(2024, 1, 1),
        endDate: endDate,
        notes: 'Take with food',
        instructions: 'Swallow whole with water',
        isActive: false,
      );

      expect(medicine.endDate, endDate);
      expect(medicine.notes, 'Take with food');
      expect(medicine.instructions, 'Swallow whole with water');
      expect(medicine.isActive, false);
    });

    test('copyWith creates modified copy', () {
      final original = Medicine(
        name: 'Original Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(
        name: 'Modified Medicine',
        dosage: '2 tablets',
        isActive: false,
      );

      expect(modified.name, 'Modified Medicine');
      expect(modified.dosage, '2 tablets');
      expect(modified.frequency, 'Once daily'); // unchanged
      expect(modified.times, ['08:00']); // unchanged
      expect(modified.startDate, DateTime(2024, 1, 1)); // unchanged
      expect(modified.isActive, false);
      expect(modified.id, original.id); // same id
    });

    test('toMap converts to map correctly', () {
      final medicine = Medicine(
        id: 'test-id',
        name: 'Test Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00', '20:00'],
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        notes: 'Take with food',
        instructions: 'Swallow whole',
        isActive: true,
      );

      final map = medicine.toMap();

      expect(map['id'], 'test-id');
      expect(map['name'], 'Test Medicine');
      expect(map['dosage'], '1 tablet');
      expect(map['frequency'], 'Once daily');
      expect(map['times'], '08:00,20:00');
      // Date format might vary, just check it contains the date
      expect(map['start_date'].toString(), contains('2024-01-01'));
      expect(map['end_date'].toString(), contains('2024-12-31'));
      expect(map['notes'], 'Take with food');
      expect(map['instructions'], 'Swallow whole');
      expect(map['is_active'], 1);
      expect(map['created_at'], isNotNull);
      expect(map['updated_at'], isNotNull);
    });

    test('fromMap creates from map correctly', () {
      final map = {
        'id': 'test-id',
        'name': 'Test Medicine',
        'dosage': '1 tablet',
        'frequency': 'Once daily',
        'times': '08:00,20:00',
        'start_date': '2024-01-01',
        'end_date': '2024-12-31',
        'notes': 'Take with food',
        'instructions': 'Swallow whole',
        'is_active': 1,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final medicine = Medicine.fromMap(map);

      expect(medicine.id, 'test-id');
      expect(medicine.name, 'Test Medicine');
      expect(medicine.dosage, '1 tablet');
      expect(medicine.frequency, 'Once daily');
      expect(medicine.times, ['08:00', '20:00']);
      expect(medicine.startDate, DateTime(2024, 1, 1));
      expect(medicine.endDate, DateTime(2024, 12, 31));
      expect(medicine.notes, 'Take with food');
      expect(medicine.instructions, 'Swallow whole');
      expect(medicine.isActive, true);
    });

    test('equality operator works correctly', () {
      final medicine1 = Medicine(
        id: 'same-id',
        name: 'Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      final medicine2 = Medicine(
        id: 'same-id',
        name: 'Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      final medicine3 = Medicine(
        id: 'different-id',
        name: 'Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      expect(medicine1 == medicine2, true);
      expect(medicine1 == medicine3, false);
    });

    test('hashCode is consistent with equality', () {
      final medicine1 = Medicine(
        id: 'same-id',
        name: 'Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      final medicine2 = Medicine(
        id: 'same-id',
        name: 'Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      // If two objects are equal, their hashcodes should be equal
      expect(medicine1 == medicine2, true);
      expect(medicine1.hashCode == medicine2.hashCode, true);
    });

    test('toString returns readable representation', () {
      final medicine = Medicine(
        name: 'Test Medicine',
        dosage: '1 tablet',
        frequency: 'Once daily',
        times: ['08:00'],
        startDate: DateTime(2024, 1, 1),
      );

      expect(medicine.toString(), contains('Test Medicine'));
      expect(medicine.toString(), contains('1 tablet'));
      expect(medicine.toString(), contains('Once daily'));
    });
  });
}