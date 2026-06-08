import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/utils/validation_utils.dart';
import '../providers/medicine_provider.dart';
import '../../domain/entities/medicine.dart';
import '../widgets/common/glass_widgets.dart';

class AddMedicineScreenNew extends ConsumerStatefulWidget {
  final Medicine? medicine;
  
  const AddMedicineScreenNew({super.key, this.medicine});

  @override
  ConsumerState<AddMedicineScreenNew> createState() => _AddMedicineScreenNewState();
}

class _AddMedicineScreenNewState extends ConsumerState<AddMedicineScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();
  final _instructionsController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  final List<String> _selectedTimes = [];
  bool _isActive = true;

  final List<String> _frequencyOptions = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Four times daily',
    'As needed',
    'Weekly',
    'Monthly',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize form fields if editing existing medicine
    final medicine = widget.medicine;
    if (medicine != null) {
      _nameController.text = medicine.name;
      _dosageController.text = medicine.dosage;
      _frequencyController.text = medicine.frequency;
      _selectedTimes.addAll(medicine.times);
      _startDate = medicine.startDate;
      _endDate = medicine.endDate;
      _notesController.text = medicine.notes ?? '';
      _instructionsController.text = medicine.instructions ?? '';
      _isActive = medicine.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicine != null;
    return GradientOrbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimaryColor,
          elevation: 0,
          title: Text(
            isEditing ? 'Edit Medicine' : 'Add Medicine',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.onPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionCard([
                _buildTextField(
                  label: 'Medicine Name',
                  controller: _nameController,
                  hintText: 'Enter medicine name',
                  validator: (value) => ValidationUtils.validateRequired(value, fieldName: 'Medicine name'),
                  icon: Icons.medication,
                ),
                const SizedBox(height: AppSpacing.m),
                _buildTextField(
                  label: 'Dosage',
                  controller: _dosageController,
                  hintText: 'e.g., 1 tablet, 5ml, 10mg',
                  validator: (value) => ValidationUtils.validateRequired(value, fieldName: 'Dosage'),
                  icon: Icons.balance,
                ),
              ], title: 'Medicine Details'),
              const SizedBox(height: AppSpacing.l),

              _buildSectionCard([
                _buildFrequencyDropdown(),
                const SizedBox(height: AppSpacing.m),
                _buildTimesSection(),
              ], title: 'Schedule'),
              const SizedBox(height: AppSpacing.l),

              _buildSectionCard([
                _buildDatePicker(
                  label: 'Start Date',
                  value: _startDate,
                  onChanged: (date) => setState(() => _startDate = date ?? DateTime.now()),
                ),
                const SizedBox(height: AppSpacing.m),
                _buildDatePicker(
                  label: 'End Date (Optional)',
                  value: _endDate,
                  onChanged: (date) => setState(() => _endDate = date),
                  isOptional: true,
                ),
              ], title: 'Duration'),
              const SizedBox(height: AppSpacing.l),

              _buildSectionCard([
                _buildTextField(
                  label: 'Notes (Optional)',
                  controller: _notesController,
                  hintText: 'Any additional notes',
                  maxLines: 3,
                  icon: Icons.note,
                  validator: (_) => null,
                ),
                const SizedBox(height: AppSpacing.m),
                _buildTextField(
                  label: 'Instructions (Optional)',
                  controller: _instructionsController,
                  hintText: 'Special instructions',
                  maxLines: 3,
                  icon: Icons.info,
                  validator: (_) => null,
                ),
              ], title: 'Additional Info'),
              const SizedBox(height: AppSpacing.l),

              _buildActiveSwitch(),
              const SizedBox(height: AppSpacing.xl),
  
              _buildAddButton(context),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildSectionCard(List<Widget> children, {required String title}) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppSpacing.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, AppSpacing.m, AppSpacing.l, AppSpacing.xs),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.l, 0, AppSpacing.l, AppSpacing.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required FormFieldValidator<String> validator,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon) : null,
          ),
          validator: validator,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildFrequencyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: _frequencyController.text.isEmpty ? null : _frequencyController.text,
          decoration: InputDecoration(
            hintText: 'Select frequency',
            prefixIcon: const Icon(Icons.schedule),
          ),
          items: _frequencyOptions.map((frequency) {
            return DropdownMenuItem(
              value: frequency,
              child: Text(frequency, style: Theme.of(context).textTheme.bodyMedium),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _frequencyController.text = value ?? '';
            });
          },
          validator: (value) => ValidationUtils.validateRequired(value, fieldName: 'Frequency'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Times',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
              onPressed: _addTime,
              tooltip: 'Add time',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (_selectedTimes.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              border: Border.all(color: AppTheme.outlineColor),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                'No times added. Tap + to add a time.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: _selectedTimes.map((time) {
              return Chip(
                label: Text(_formatTimeForDisplay(time), style: Theme.of(context).textTheme.bodySmall),
                onDeleted: () => _removeTime(time),
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                side: const BorderSide(color: AppTheme.primaryColor),
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required Function(DateTime?) onChanged,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              builder: AppTheme.datePickerThemeBuilder,
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              border: Border.all(color: AppTheme.outlineColor),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.m),
                Text(
                  value != null
                      ? DateFormat('yyyy-MM-dd').format(value)
                      : isOptional
                          ? 'Select date (optional)'
                          : 'Select date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: value != null ? AppTheme.onSurfaceColor : AppTheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
              ],
            ),
          ),
        ),
        if (!isOptional && value == null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Please select a date',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      borderRadius: AppSpacing.borderRadiusMedium,
      child: Row(
        children: [
          const Icon(Icons.toggle_on, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.m),
          Text(
            'Active',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.onSurfaceColor,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final medicineListState = ref.watch(medicineListProvider);
    final isEditing = widget.medicine != null;
    final buttonText = isEditing ? 'Update Medicine' : 'Add Medicine';
    final buttonIcon = isEditing ? Icons.save : Icons.add;

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: medicineListState.isLoading ? null : _addMedicine,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
          elevation: 2,
        ),
        child: medicineListState.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.onPrimaryColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    buttonText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.onPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _addTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: AppTheme.timePickerThemeBuilder,
    );

    if (selectedTime != null) {
      final timeString = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      if (!_selectedTimes.contains(timeString)) {
        setState(() {
          _selectedTimes.add(timeString);
          _selectedTimes.sort();
        });
      }
    }
  }

  void _removeTime(String time) {
    setState(() {
      _selectedTimes.remove(time);
    });
  }

  Future<void> _addMedicine() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTimes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please add at least one time'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }

      try {
        final medicine = createNewMedicine(
          id: widget.medicine?.id,
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          frequency: _frequencyController.text.trim(),
          times: _selectedTimes,
          startDate: _startDate,
          endDate: _endDate,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          instructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
          isActive: _isActive,
        );

        final isEditing = widget.medicine != null;
        if (isEditing) {
          await ref.read(medicineListProvider.notifier).updateMedicine(medicine);
        } else {
          await ref.read(medicineListProvider.notifier).addMedicine(medicine);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${medicine.name} ${isEditing ? 'updated' : 'added'} successfully'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${widget.medicine != null ? 'updating' : 'adding'} medicine: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatTimeForDisplay(String time24) {
    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minuteStr $period';
    } catch (e) {
      return time24;
    }
  }
}
