import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/spacing_constants.dart';
import '../../core/themes/app_theme.dart';
import '../../core/services/profile_service.dart';
import '../providers/profile_provider.dart';
import '../widgets/common/glass_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _genderController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _notesController;
  final List<_CustomFieldDraft> _customFields = [];
  bool _didHydrateControllers = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _bloodGroupController = TextEditingController();
    _genderController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _notesController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bloodGroupController.dispose();
    _genderController.dispose();
    _emergencyContactController.dispose();
    _notesController.dispose();
    for (final field in _customFields) {
      field.dispose();
    }
    super.dispose();
  }

  void _hydrate(ProfileData profile) {
    if (_didHydrateControllers) return;
    _fullNameController.text = profile.fullName;
    _ageController.text = profile.age;
    _heightController.text = profile.heightCm;
    _weightController.text = profile.weightKg;
    _bloodGroupController.text = profile.bloodGroup;
    _genderController.text = profile.gender;
    _emergencyContactController.text = profile.emergencyContact;
    _notesController.text = profile.notes;
    _customFields.clear();
    for (final field in profile.customFields) {
      _customFields.add(
        _CustomFieldDraft(label: field.label, value: field.value),
      );
    }
    _didHydrateControllers = true;
  }

  List<ProfileCustomField> _collectCustomFields() {
    return _customFields
        .map(
          (field) => ProfileCustomField(
            label: field.labelController.text.trim(),
            value: field.valueController.text.trim(),
          ),
        )
        .where((field) => field.label.isNotEmpty || field.value.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final notifier = ref.read(profileProvider.notifier);
    final success = await notifier.saveProfile(
      ProfileData(
        fullName: _fullNameController.text.trim(),
        age: _ageController.text.trim(),
        heightCm: _heightController.text.trim(),
        weightKg: _weightController.text.trim(),
        bloodGroup: _bloodGroupController.text.trim(),
        gender: _genderController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        notes: _notesController.text.trim(),
        customFields: _collectCustomFields(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile saved successfully' : 'Failed to save profile'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    _hydrate(state.profile);

    return GradientOrbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimaryColor,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: state.isSaving ? null : _save,
              icon: state.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                children: [
                  if (state.error != null) ...[
                    _errorBanner(state.error!),
                    const SizedBox(height: AppSpacing.l),
                  ],
                  _sectionCard(
                    title: 'Personal information',
                    children: [
                      _field(_fullNameController, 'Full name'),
                      _field(_ageController, 'Age', keyboard: TextInputType.number),
                      _field(_genderController, 'Gender'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _sectionCard(
                    title: 'Health details',
                    children: [
                      _field(
                        _heightController,
                        'Height (cm)',
                        keyboard: TextInputType.number,
                      ),
                      _field(
                        _weightController,
                        'Weight (kg)',
                        keyboard: TextInputType.number,
                      ),
                      _field(_bloodGroupController, 'Blood group'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _sectionCard(
                    title: 'Additional details',
                    children: [
                      _field(_emergencyContactController, 'Emergency contact'),
                      _field(_notesController, 'Notes', maxLines: 4),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _sectionCard(
                    title: 'Custom fields',
                    trailing: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _customFields.add(_CustomFieldDraft());
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add field'),
                    ),
                    children: [
                      for (int i = 0; i < _customFields.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.m),
                          child: _CustomFieldRow(
                            field: _customFields[i],
                            onRemove: () {
                              setState(() {
                                _customFields[i].dispose();
                                _customFields.removeAt(i);
                              });
                            },
                          ),
                        ),
                      if (_customFields.isEmpty)
                        Text(
                          'Add extra profile fields for future preferences and medical context.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        border: Border.all(color: AppTheme.errorColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.errorColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      borderRadius: AppSpacing.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboard,
            decoration: InputDecoration(
              hintText: 'Enter $label',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CustomFieldDraft {
  _CustomFieldDraft({String label = '', String value = ''})
    : labelController = TextEditingController(text: label),
      valueController = TextEditingController(text: value);

  final TextEditingController labelController;
  final TextEditingController valueController;

  void dispose() {
    labelController.dispose();
    valueController.dispose();
  }
}

class _CustomFieldRow extends StatelessWidget {
  const _CustomFieldRow({required this.field, required this.onRemove});

  final _CustomFieldDraft field;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Field label',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: field.labelController,
                    decoration: const InputDecoration(hintText: 'e.g., Allergies'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
              tooltip: 'Remove field',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Value',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: field.valueController,
              decoration: const InputDecoration(hintText: 'Enter value'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
