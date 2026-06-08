import 'package:flutter/material.dart';

import '../../core/constants/spacing_constants.dart';
import '../../core/services/app_review_service.dart';
import '../../core/themes/app_theme.dart';
import '../widgets/common/glass_widgets.dart';
import 'about_screen.dart';
import 'backup_settings_screen.dart';
import 'compliance_information_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_screen.dart';
import 'security_settings_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviewService = AppReviewService();
    final sections = <SettingsSectionData>[
      SettingsSectionData(
        title: 'Profile',
        items: [
          SettingsItemData(
            icon: Icons.person_outline,
            title: 'Personal details',
            subtitle: 'Name, age, height, and custom fields',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
        ],
      ),
      SettingsSectionData(
        title: 'Privacy',
        items: [
          SettingsItemData(
            icon: Icons.shield_outlined,
            title: 'Compliance & Data Protection',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ComplianceInformationScreen(),
                ),
              );
            },
          ),
          SettingsItemData(
            icon: Icons.lock_outline,
            title: 'Security & App Lock',
            subtitle: 'PIN, password, and biometric settings',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SecuritySettingsScreen(),
                ),
              );
            },
          ),
          SettingsItemData(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          SettingsItemData(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              );
            },
          ),
        ],
      ),
      SettingsSectionData(
        title: 'Data & Backup',
        items: [
          SettingsItemData(
            icon: Icons.cloud_sync_outlined,
            title: 'Backup & Restore',
            subtitle: 'Google Drive backup, restore, passphrase, automation',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
              );
            },
          ),
        ],
      ),
      SettingsSectionData(
        title: 'About & Feedback',
        items: [
          SettingsItemData(
            icon: Icons.info_outline,
            title: 'About CareVault',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
          SettingsItemData(
            icon: Icons.star_outline,
            title: 'Rate this app',
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              final success = await reviewService.requestReview();
              if (!context.mounted) return;
              if (!success) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Store review link is not configured yet.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    ];

    return GradientOrbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimaryColor,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            ...sections.expand(
              (section) => [
                _SettingsSection(section: section),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSectionData {
  const SettingsSectionData({required this.title, required this.items});

  final String title;
  final List<SettingsItemData> items;
}

class SettingsItemData {
  const SettingsItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.section});

  final SettingsSectionData section;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.s,
            ),
            child: Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...section.items.map((item) => _SettingsTile(item: item)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.item});

  final SettingsItemData item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.m,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(
                    AppSpacing.borderRadiusSmall,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x333B82F6),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(item.icon, color: AppTheme.onPrimaryColor),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
