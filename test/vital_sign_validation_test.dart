import 'package:carevault/core/utils/vital_sign_validation.dart';
import 'package:carevault/domain/entities/vital_sign.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VitalSignValidation', () {
    test('allows very high blood sugar as a valid input', () {
      expect(
        VitalSignValidation.validateVitalSignValue(
          '700',
          VitalSignType.bloodSugar,
        ),
        isNull,
      );
    });

    test('keeps the high blood sugar warning available', () {
      expect(
        VitalSignValidation.getVitalSignWarning(
          '700',
          VitalSignType.bloodSugar,
        ),
        'Warning: Very high blood sugar. Consider medical attention.',
      );
    });

    test('allows very high blood pressure values as valid input', () {
      expect(
        VitalSignValidation.validateVitalSignValue(
          '350',
          VitalSignType.bloodPressure,
        ),
        isNull,
      );
      expect(
        VitalSignValidation.validateVitalSignValue(
          '140',
          VitalSignType.bloodPressure,
          isFirstValue: false,
        ),
        isNull,
      );
      expect(
        VitalSignValidation.validateBloodPressure('350', '140'),
        isNull,
      );
    });

    test('keeps the high blood pressure warning available', () {
      expect(
        VitalSignValidation.getBloodPressureWarning('190', '125'),
        'Dangerously high blood pressure. Seek emergency care.',
      );
    });
  });
}
