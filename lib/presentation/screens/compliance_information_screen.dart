import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/themes/app_theme.dart';
import '../widgets/common/glass_widgets.dart';

class ComplianceInformationScreen extends StatelessWidget {
  const ComplianceInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <_ComplianceSection>[
      const _ComplianceSection(
        title: 'What CareVault stores',
        icon: Icons.folder_outlined,
        bullets: [
          'Medication names, dosage schedules, and reminder logs.',
          'Prescription files, test reports, and follow-up appointments.',
          'Vital sign readings, user-entered profile details, and optional notes.',
        ],
      ),
      const _ComplianceSection(
        title: 'Where data is stored',
        icon: Icons.storage_outlined,
        bullets: [
          'Primary app data is stored on-device using a local database.',
          'Sensitive settings such as passphrases and security state use secure device storage where available.',
          'Cloud backup is user-initiated or user-enabled and is not required to use the app.',
        ],
      ),
      const _ComplianceSection(
        title: 'Security controls',
        icon: Icons.lock_outline,
        bullets: [
          'App lock supports PIN, password, and biometric access control.',
          'Backups are encrypted and protected with a user-controlled passphrase before restore.',
          'Access and export events are tracked through internal audit logging services.',
        ],
      ),
      const _ComplianceSection(
        title: 'Health integrations',
        icon: Icons.monitor_heart_outlined,
        bullets: [
          'HealthKit / Google Fit access is optional and controlled by system permissions.',
          'Imported health data is displayed to the user before it is saved into CareVault.',
          'Users can disable health permissions at the OS level at any time.',
        ],
      ),
      const _ComplianceSection(
        title: 'Data sharing and user control',
        icon: Icons.verified_user_outlined,
        bullets: [
          'CareVault does not sell health data or use advertising SDKs.',
          'Users can review privacy and terms documents from Settings at any time.',
          'Users can delete app data, manage backups, and request support via the contact details below.',
        ],
      ),
      const _ComplianceSection(
        title: 'Important notice',
        icon: Icons.warning_amber_outlined,
        bullets: [
          'CareVault is an organizational tool and not a substitute for emergency or diagnostic medical care.',
          'If you believe there is a medical emergency, contact local emergency services immediately.',
          'Do not represent the app as formally HIPAA compliant unless legal and security review has approved that claim end-to-end.',
        ],
      ),
    ];

    return GradientOrbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Compliance & Data Protection'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimaryColor,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            _InfoCard(
              title: 'For users and App Review',
              body:
                  'This page explains how CareVault handles personal health-related data, what security controls exist in the product today, and where to find related legal information.',
              trailing: Text(
                'Contact: ${AppConstants.complianceEmail}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ...sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.l),
                child: _SectionCard(section: section),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplianceSection {
  const _ComplianceSection({
    required this.title,
    required this.icon,
    required this.bullets,
  });

  final String title;
  final IconData icon;
  final List<String> bullets;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body, required this.trailing});

  final String title;
  final String body;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      borderRadius: AppSpacing.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.s),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
          ),
          const SizedBox(height: AppSpacing.m),
          trailing,
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});

  final _ComplianceSection section;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      borderRadius: AppSpacing.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: AppTheme.primaryColor),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ...section.bullets.map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 8, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceColor,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
