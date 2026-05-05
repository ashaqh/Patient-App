import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/validation_utils.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../providers/medicine_provider.dart';
import '../../domain/entities/medicine.dart';

class AddMedicineScreen extends ConsumerStatefulWidget {
  final Medicine? medicine;
  
  const AddMedicineScreen({super.key, this.medicine});

  @override
  ConsumerState<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends ConsumerState<AddMedicineScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Medicine' : 'Add Medicine'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Medicine name
              _buildTextField(
                label: 'Medicine Name',
                controller: _nameController,
                hintText: 'Enter medicine name',
                validator: (value) => ValidationUtils.validateRequired(value, fieldName: 'Medicine name'),
                icon: Icons.medication,
              ),
              const SizedBox(height: 16),

              // Dosage
              _buildTextField(
                label: 'Dosage',
                controller: _dosageController,
                hintText: 'e.g., 1 tablet, 5ml, 10mg',
                validator: (value) => ValidationUtils.validateRequired(value, fieldName: 'Dosage'),
                icon: Icons.balance,
              ),
              const SizedBox(height: 16),

              // Frequency
              _buildFrequencyDropdown(),
              const SizedBox(height: 16),

              // Times
              _buildTimesSection(),
              const SizedBox(height: 16),

              // Start date
              _buildDatePicker(
                label: 'Start Date',
                value: _startDate,
                onChanged: (date) => setState(() => _startDate = date ?? DateTime.now()),
              ),
              const SizedBox(height: 16),

              // End date (optional)
              _buildDatePicker(
                label: 'End Date (Optional)',
                value: _endDate,
                onChanged: (date) => setState(() => _endDate = date),
                isOptional: true,
              ),
              const SizedBox(height: 16),

              // Notes
              _buildTextField(
                label: 'Notes (Optional)',
                controller: _notesController,
                hintText: 'Any additional notes',
                maxLines: 3,
                icon: Icons.note,
                validator: (_) => null, // Optional field
              ),
              const SizedBox(height: 16),

              // Instructions
              _buildTextField(
                label: 'Instructions (Optional)',
                controller: _instructionsController,
                hintText: 'Special instructions',
                maxLines: 3,
                icon: Icons.info,
                validator: (_) => null, // Optional field
              ),
              const SizedBox(height: 16),

              // Active status
              _buildActiveSwitch(),
              const SizedBox(height: 24),

              // Add button
              _buildAddButton(context),
            ],
          ),
        ),
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
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: icon != null ? Icon(icon) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyLarge,
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
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _frequencyController.text.isEmpty ? null : _frequencyController.text,
          decoration: InputDecoration(
            hintText: 'Select frequency',
            prefixIcon: const Icon(Icons.schedule),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: _frequencyOptions.map((frequency) {
            return DropdownMenuItem(
              value: frequency,
              child: Text(frequency),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _frequencyController.text = value ?? '';
            });
          },
          validator: (value) => ValidationUtils.validateRequired(value, fieldName: 'Frequency'),
          style: Theme.of(context).textTheme.bodyLarge,
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addTime,
              tooltip: 'Add time',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedTimes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No times added. Tap + to add a time.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTimes.map((time) {
              return Chip(
                label: Text(_formatTimeForDisplay(time)),
                onDeleted: () => _removeTime(time),
                deleteIcon: const Icon(Icons.close, size: 16),
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
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (selectedDate != null) {
              onChanged(selectedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  value != null
                      ? DateFormat('yyyy-MM-dd').format(value)
                      : isOptional
                          ? 'Select date (optional)'
                          : 'Select date',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        if (!isOptional && value == null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Please select a date',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.red),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Row(
      children: [
        const Icon(Icons.toggle_on),
        const SizedBox(width: 12),
        Text(
          'Active',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        Switch(
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final medicineListState = ref.watch(medicineListProvider);
    final isEditing = widget.medicine != null;
    final isLoadingText = isEditing ? 'Updating...' : 'Adding...';
    final buttonText = isEditing ? 'Update Medicine' : 'Add Medicine';
    final buttonIcon = isEditing ? Icons.save : Icons.add;

    return ElderlyFriendlyButton(
      onPressed: _addMedicine,
      text: medicineListState.isLoading ? isLoadingText : buttonText,
      icon: medicineListState.isLoading ? null : buttonIcon,
      width: double.infinity,
      isLoading: medicineListState.isLoading,
    );
  }

  Future<void> _addTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
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
          const SnackBar(
            content: Text('Please add at least one time'),
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
            backgroundColor: Colors.green,
          ),
        );

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${widget.medicine != null ? 'updating' : 'adding'} medicine: $e'),
            backgroundColor: Colors.red,
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
