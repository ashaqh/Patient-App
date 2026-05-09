class ChartAxisRange {
  final double minY;
  final double maxY;
  final double horizontalInterval;

  const ChartAxisRange({
    required this.minY,
    required this.maxY,
    required this.horizontalInterval,
  });
}

class ChartAxisUtils {
  static const int _defaultSections = 4;

  static ChartAxisRange paddedRange({
    required double minValue,
    required double maxValue,
    required double absoluteMin,
    required double absoluteMax,
  }) {
    final fullRange = absoluteMax - absoluteMin;
    final fallbackPadding = fullRange > 0 ? fullRange * 0.05 : 1.0;
    final valueRange = maxValue - minValue;
    final padding = valueRange > 0 ? valueRange * 0.1 : fallbackPadding;

    var minY = minValue - padding;
    var maxY = maxValue + padding;

    if (minY < absoluteMin) minY = absoluteMin;
    if (maxY > absoluteMax) maxY = absoluteMax;

    if (maxY <= minY) {
      if (minY <= absoluteMin && absoluteMax > absoluteMin) {
        maxY = absoluteMax < minY + fallbackPadding
            ? absoluteMax
            : minY + fallbackPadding;
      } else {
        minY -= fallbackPadding;
      }
    }

    final interval = (maxY - minY) / _defaultSections;

    return ChartAxisRange(
      minY: minY,
      maxY: maxY,
      horizontalInterval: interval > 0 ? interval : 1.0,
    );
  }
}
