import 'package:carevault/core/utils/chart_axis_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartAxisUtils', () {
    test('creates a nonzero interval when all chart values are equal', () {
      final axis = ChartAxisUtils.paddedRange(
        minValue: 120,
        maxValue: 120,
        absoluteMin: 0,
        absoluteMax: 600,
      );

      expect(axis.minY, lessThan(120));
      expect(axis.maxY, greaterThan(120));
      expect(axis.horizontalInterval, greaterThan(0));
    });

    test('keeps interval nonzero when values are at the absolute minimum', () {
      final axis = ChartAxisUtils.paddedRange(
        minValue: 0,
        maxValue: 0,
        absoluteMin: 0,
        absoluteMax: 600,
      );

      expect(axis.minY, 0);
      expect(axis.maxY, greaterThan(0));
      expect(axis.horizontalInterval, greaterThan(0));
    });
  });
}
