import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/vital_sign_validation.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../providers/vital_sign_provider.dart';
import '../widgets/health_data_import_widget.dart';
import '../../domain/entities/vital_sign.dart';

class AddVitalSignScreen extends ConsumerStatefulWidget {
  final VitalSign? vitalSign;
  
  const AddVitalSignScreen({super.key, this.vitalSign});

  @override
  ConsumerState<AddVitalSignScreen> createState() => _AddVitalSignScreenState();
}

class _AddVitalSignScreenState extends ConsumerState<AddVitalSignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _value1Controller = TextEditingController();
  final _value2Controller = TextEditingController();
  final _notesController = TextEditingController();
  final _contextController = TextEditingController();

  VitalSignType _selectedType = VitalSignType.bloodPressure;
  DateTime _readingTime = DateTime.now();
  MealMarker? _selectedMealMarker;
  String? _deviceSource;
  bool _isManualEntry = true;

  final List<String> _deviceSources = [
    'Manual Entry',
    'Apple Watch',
    'Fitbit',
    'Garmin',
    'Withings',
    'Omron',
    'Other Device',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize form fields if editing existing vital sign
    final vitalSign = widget.vitalSign;
    if (vitalSign != null) {
      _selectedType = vitalSign.type;
      _value1Controller.text = vitalSign.value1.toStringAsFixed(
        vitalSign.type == VitalSignType.bloodPressure ? 0 : 1
      );
      if (vitalSign.value2 != null) {
        _value2Controller.text = vitalSign.value2!.toStringAsFixed(0);
      }
      _readingTime = vitalSign.readingTime;
      _selectedMealMarker = vitalSign.mealMarker;
      _contextController.text = vitalSign.context ?? '';
      _notesController.text = vitalSign.notes ?? '';
      _deviceSource = vitalSign.deviceSource;
      _isManualEntry = vitalSign.isManualEntry;
    } else {
      _deviceSource = 'Manual Entry';
    }
  }

  @override
  void dispose() {
    _value1Controller.dispose();
    _value2Controller.dispose();
    _notesController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _readingTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_readingTime),
      );
      
      if (pickedTime != null) {
        setState(() {
          _readingTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vital Sign Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VitalSignType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                    // Clear second value when type changes (except for blood pressure)
                    if (type != VitalSignType.bloodPressure) {
                      _value2Controller.clear();
                    }
                  });
                }
              },
              backgroundColor: isSelected 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          VitalSignValidation.getTargetRangeDescription(_selectedType),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildValueField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required String? Function(String?) validator,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        suffixText: _selectedType.unit,
      ),
      keyboardType: TextInputType.number,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reading Time',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('MMM dd, yyyy - hh:mm a').format(_readingTime),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealMarkerSelector() {
    if (_selectedType != VitalSignType.bloodSugar) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Context',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MealMarker.values.map((marker) {
            final isSelected = _selectedMealMarker == marker;
            return ChoiceChip(
              label: Text(marker.displayName),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedMealMarker = selected ? marker : null;
                });
              },
              backgroundColor: isSelected 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDeviceSourceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device Source',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _deviceSource,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select device source',
          ),
          items: _deviceSources.map((source) {
            return DropdownMenuItem(
              value: source,
              child: Text(source),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _deviceSource = value;
              _isManualEntry = value == 'Manual Entry';
            });
          },
        ),
      ],
    );
  }

  Widget _buildContextField() {
    return TextFormField(
      controller: _contextController,
      decoration: const InputDecoration(
        labelText: 'Context (Optional)',
        hintText: 'e.g., After exercise, Feeling stressed, Morning reading',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Notes (Optional)',
        hintText: 'Add any additional notes...',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
    );
  }

  Future<void> _saveVitalSign() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation for blood pressure
    if (_selectedType == VitalSignType.bloodPressure) {
      final bpError = VitalSignValidation.validateBloodPressure(
        _value1Controller.text,
        _value2Controller.text,
      );
      if (bpError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(bpError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    final warning = _getWarningMessage();

    try {
      final vitalSign = VitalSign(
        type: _selectedType,
        value1: double.parse(_value1Controller.text),
        value2: _value2Controller.text.isNotEmpty 
            ? double.parse(_value2Controller.text) 
            : null,
        readingTime: _readingTime,
        mealMarker: _selectedMealMarker,
        context: _contextController.text.isNotEmpty ? _contextController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        deviceSource: _deviceSource,
        isManualEntry: _isManualEntry,
      );

      final notifier = ref.read(vitalSignListProvider.notifier);
      
      if (widget.vitalSign != null) {
        // Update existing vital sign
        await notifier.updateVitalSign(
          vitalSign.copyWith(id: widget.vitalSign!.id),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(warning ?? 'Vital sign updated successfully')),
        );
      } else {
        // Create new vital sign
        await notifier.createVitalSign(vitalSign);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(warning ?? 'Vital sign recorded successfully')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save vital sign: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String? _getWarningMessage() {
    if (_selectedType == VitalSignType.bloodPressure) {
      return VitalSignValidation.getBloodPressureWarning(
        _value1Controller.text,
        _value2Controller.text,
      );
    }

    return VitalSignValidation.getVitalSignWarning(
      _value1Controller.text,
      _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vitalSign != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Vital Sign' : 'Add Vital Sign'),
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
              // Vital Sign Type Selector
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Health Data Import
              HealthDataImportWidget(
                filterType: _selectedType,
                onVitalSignImported: (vitalSign) {
                  // Auto-fill form with imported data
                  setState(() {
                    _selectedType = vitalSign.type;
                    _value1Controller.text = vitalSign.value1.toStringAsFixed(
                      vitalSign.type == VitalSignType.bloodPressure ? 0 : 1,
                    );
                    if (vitalSign.value2 != null) {
                      _value2Controller.text = vitalSign.value2!.toStringAsFixed(
                        vitalSign.type == VitalSignType.bloodPressure ? 0 : 1,
                      );
                    }
                    _readingTime = vitalSign.readingTime;
                    _deviceSource = vitalSign.deviceSource;
                    _isManualEntry = vitalSign.isManualEntry;
                    
                    if (vitalSign.context != null) {
                      _contextController.text = vitalSign.context!;
                    }
                    
                    if (vitalSign.notes != null) {
                      _notesController.text = vitalSign.notes!;
                    }
                  });
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${vitalSign.type.displayName} data imported successfully'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // Value Fields
              if (_selectedType.hasTwoValues) ...[
                _buildValueField(
                  label: 'Systolic (Upper)',
                  controller: _value1Controller,
                  hintText: 'e.g., 120',
                  validator: (value) => VitalSignValidation.validateVitalSignValue(
                    value, 
                    _selectedType,
                    isFirstValue: true,
                  ),
                ),
                const SizedBox(height: 16),
                _buildValueField(
                  label: 'Diastolic (Lower)',
                  controller: _value2Controller,
                  hintText: 'e.g., 80',
                  validator: (value) => VitalSignValidation.validateVitalSignValue(
                    value, 
                    _selectedType,
                    isFirstValue: false,
                  ),
                ),
              ] else ...[
                _buildValueField(
                  label: 'Value',
                  controller: _value1Controller,
                  hintText: 'Enter ${_selectedType.displayName.toLowerCase()} value',
                  validator: (value) => VitalSignValidation.validateVitalSignValue(
                    value, 
                    _selectedType,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Reading Time
              _buildDateTimePicker(),
              const SizedBox(height: 24),

              // Meal Marker (for blood sugar)
              _buildMealMarkerSelector(),
              if (_selectedType == VitalSignType.bloodSugar) 
                const SizedBox(height: 16),

              // Device Source
              _buildDeviceSourceSelector(),
              const SizedBox(height: 16),

              // Context Field
              _buildContextField(),
              const SizedBox(height: 16),

              // Notes Field
              _buildNotesField(),
              const SizedBox(height: 32),

              // Save Button
              ElderlyFriendlyButton(
                onPressed: _saveVitalSign,
                text: isEditing ? 'Update Vital Sign' : 'Save Vital Sign',
                icon: Icons.save,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
