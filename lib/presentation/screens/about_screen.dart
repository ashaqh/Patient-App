import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/themes/app_theme.dart';
import '../widgets/common/glass_widgets.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _versionLabel = 'Loading version…';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = '${packageInfo.version} (${packageInfo.buildNumber})';
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientOrbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('About CareVault'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimaryColor,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              borderRadius: AppSpacing.borderRadiusMedium,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      size: 36,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.onSurfaceColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Version $_versionLabel',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'CareVault is a private medication, prescription, follow-up, and health history companion designed for patients and caregivers who need clear daily organization.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceColor,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            _AboutItem(label: 'Support', value: AppConstants.supportEmail),
            _AboutItem(label: 'Privacy', value: AppConstants.privacyPolicyUrl),
            _AboutItem(label: 'Terms', value: AppConstants.termsOfServiceUrl),
            _AboutItem(
              label: 'Health data posture',
              value:
                  'Local-first storage, optional encrypted backups, app lock, audit logging, and user-controlled health imports.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutItem extends StatelessWidget {
  const _AboutItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        borderRadius: AppSpacing.borderRadiusMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
