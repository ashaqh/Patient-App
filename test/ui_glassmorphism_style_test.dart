import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  String read(String path) =>
      File(path).readAsStringSync().replaceAll('\r\n', '\n');

  String methodSection(
    String source,
    String methodName,
    String nextMethodName,
  ) {
    final start = source.indexOf(methodName);
    final end = source.indexOf(nextMethodName, start + methodName.length);
    expect(start, isNonNegative);
    return source.substring(start, end == -1 ? source.length : end);
  }

  test('settings cards use glassmorphism on the themed background', () {
    final source = read('lib/presentation/screens/settings_screen.dart');

    expect(source, contains("import '../widgets/common/glass_widgets.dart';"));
    expect(source, contains('return GradientOrbBackground('));
    expect(source, contains('return GlassCard('));
    expect(source, isNot(contains('backgroundColor: AppTheme.secondaryColor')));
    expect(source, isNot(contains('backgroundColor: AppTheme.primaryColor')));
  });

  test('vault, follow-up, and timeline list cards use GlassCard', () {
    final prescriptionSource = read(
      'lib/presentation/screens/prescription_list_screen_new.dart',
    );
    final followUpSource = read(
      'lib/presentation/screens/follow_up_list_screen_new.dart',
    );
    final timelineSource = read(
      'lib/presentation/screens/timeline_screen.dart',
    );

    expect(prescriptionSource, contains('Widget _buildPrescriptionCard'));
    expect(
      prescriptionSource,
      contains(
        'return GlassCard(\n      margin: const EdgeInsets.symmetric(vertical: 1),',
      ),
    );
    expect(
      followUpSource,
      contains(
        'return GlassCard(\n      margin: const EdgeInsets.only(bottom: AppSpacing.m),',
      ),
    );
    expect(
      timelineSource,
      contains(
        'return GlassCard(\n      margin: const EdgeInsets.only(bottom: AppSpacing.m),',
      ),
    );
  });

  test('target screens do not use opaque light card surfaces', () {
    final prescriptionSource = read(
      'lib/presentation/screens/prescription_list_screen_new.dart',
    );
    final followUpSource = read(
      'lib/presentation/screens/follow_up_list_screen_new.dart',
    );
    final timelineSource = read(
      'lib/presentation/screens/timeline_screen.dart',
    );
    final settingsSource = read(
      'lib/presentation/screens/settings_screen.dart',
    );

    final targetSources = [
      methodSection(
        prescriptionSource,
        'Widget _buildPrescriptionCard',
        'void _showPrescriptionDetails',
      ),
      methodSection(
        followUpSource,
        'Widget _buildFollowUpCard',
        'Widget _buildCardDetailRow',
      ),
      methodSection(
        timelineSource,
        'Widget _buildTimelineItem',
        'Color _getTypeColor',
      ),
      settingsSource,
    ].join('\n');

    expect(targetSources, isNot(contains('color: AppTheme.surfaceColor')));
    expect(
      targetSources,
      isNot(contains('backgroundColor: AppTheme.surfaceColor')),
    );
  });

  test(
    'prescription vault visible sections use glass cards and theme buttons',
    () {
      final source = read(
        'lib/presentation/screens/prescription_list_screen_new.dart',
      );

      expect(
        methodSection(
          source,
          'Widget _buildStatCard',
          'Widget _buildRecentPrescriptionsSection',
        ),
        contains('return GlassCard('),
      );
      expect(
        methodSection(
          source,
          'Widget _buildRecentPrescriptionsSection',
          'Widget _buildAllPrescriptionsSection',
        ),
        contains('return GlassCard('),
      );
      expect(
        methodSection(
          source,
          'Widget _buildAllPrescriptionsSection',
          'Widget _buildPrescriptionCard',
        ),
        contains('return GlassCard('),
      );
      expect(
        methodSection(
          source,
          'Widget _buildAllPrescriptionsSection',
          'Widget _buildPrescriptionCard',
        ),
        isNot(contains('ElevatedButton.styleFrom(')),
      );
    },
  );

  test('follow-up screen action buttons use app theme styles', () {
    final source = read(
      'lib/presentation/screens/follow_up_list_screen_new.dart',
    );

    expect(
      methodSection(
        source,
        'Widget _buildEmptyState',
        'Future<void> _showSearchDialog',
      ),
      isNot(contains('ElevatedButton.styleFrom(')),
    );
    expect(
      methodSection(
        source,
        'Future<void> _showSearchDialog',
        'void _showSearchResults',
      ),
      isNot(contains('OutlinedButton.styleFrom(')),
    );
    expect(
      methodSection(
        source,
        'Future<void> _showSearchDialog',
        'void _showSearchResults',
      ),
      isNot(contains('ElevatedButton.styleFrom(')),
    );
  });

  test('follow-up quick filter buttons use glassmorphism theme styling', () {
    final source = read(
      'lib/presentation/screens/follow_up_list_screen_new.dart',
    );
    final filterChipSection = methodSection(
      source,
      'Widget _buildFilterChip',
      'Widget _buildFollowUpsList',
    );

    expect(filterChipSection, contains('GlassCard('));
    expect(filterChipSection, isNot(contains('return FilterChip(')));
    expect(filterChipSection, isNot(contains('AppTheme.surfaceColor')));
    expect(filterChipSection, contains('AppTheme.primaryGradient'));
    expect(filterChipSection, contains('AppTheme.glassSurfaceStrong'));
  });

  test('timeline content status and date cards use glass surfaces', () {
    final source = read('lib/presentation/screens/timeline_screen.dart');

    expect(
      methodSection(
        source,
        'Widget _buildTimelineContent',
        'Widget _buildDateGroup',
      ),
      contains('GlassCard('),
    );
    expect(
      methodSection(
        source,
        'Widget _buildDateGroup',
        'Widget _buildTimelineItem',
      ),
      contains('GlassCard('),
    );
    expect(
      methodSection(
        source,
        'Widget _buildTimelineContent',
        'Widget _buildDateGroup',
      ),
      isNot(contains('color: AppTheme.surfaceColor')),
    );
  });

  test('follow-up action buttons use app theme colors', () {
    final source = read(
      'lib/presentation/screens/follow_up_list_screen_new.dart',
    );

    expect(
      source,
      isNot(
        contains('ElevatedButton.styleFrom(backgroundColor: Colors.green)'),
      ),
    );
    expect(
      source,
      isNot(
        contains('ElevatedButton.styleFrom(backgroundColor: Colors.orange)'),
      ),
    );
    expect(
      source,
      isNot(contains('ElevatedButton.styleFrom(backgroundColor: Colors.red)')),
    );
    expect(source, contains('AppTheme.secondaryButtonStyle'));
  });

  test(
    'gradient floating action buttons clear the custom bottom navigation',
    () {
      final source = read('lib/presentation/widgets/common/glass_widgets.dart');
      final gradientFabSection = methodSection(
        source,
        'class GradientFab',
        'class',
      );

      expect(gradientFabSection, contains('_bottomNavigationClearance'));
      expect(gradientFabSection, contains('Padding('));
      expect(
        gradientFabSection,
        contains('bottom: _bottomNavigationClearance'),
      );
    },
  );

  test(
    'custom bottom navigation is compact and does not double safe-area padding',
    () {
      final appSource = read('lib/presentation/screens/app.dart');
      final bottomNavSection = methodSection(
        appSource,
        'Widget _buildBottomNavigationBar',
        '@override',
      );
      final glassWidgetSource = read(
        'lib/presentation/widgets/common/glass_widgets.dart',
      );

      expect(appSource, contains('const double _navCapsuleHeight = 68;'));
      expect(bottomNavSection, isNot(contains('SafeArea(')));
      expect(
        glassWidgetSource,
        contains('static const double _bottomNavigationClearance = 112;'),
      );
    },
  );
}
