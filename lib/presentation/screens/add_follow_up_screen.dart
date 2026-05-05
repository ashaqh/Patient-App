import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/utils/validation_utils.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../../domain/entities/follow_up.dart';
import '../providers/follow_up_provider.dart';

class AddFollowUpScreen extends ConsumerStatefulWidget {
  final FollowUp? followUpToEdit;

  const AddFollowUpScreen({super.key, this.followUpToEdit});

  @override
  ConsumerState<AddFollowUpScreen> createState() => _AddFollowUpScreenState();
}

class _AddFollowUpScreenState extends ConsumerState<AddFollowUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  FollowUpStatus _selectedStatus = FollowUpStatus.scheduled;

  @override
  void initState() {
    super.initState();
    if (widget.followUpToEdit != null) {
      _loadFollowUpData(widget.followUpToEdit!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadFollowUpData(FollowUp followUp) {
    _titleController.text = followUp.title;
    _selectedDate = followUp.date;
    _selectedTime = TimeOfDay.fromDateTime(followUp.date);
    _selectedStatus = followUp.status;
    _doctorNameController.text = followUp.doctorName ?? '';
    _clinicNameController.text = followUp.clinicName ?? '';
    _locationController.text = followUp.location ?? '';
    _notesController.text = followUp.notes ?? '';
  }

  DateTime _combineDateAndTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.followUpToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Follow-up' : 'Add Follow-up'),
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
              // Title
              _buildTextField(
                label: 'Title',
                controller: _titleController,
                hintText: 'Enter follow-up title (e.g., Doctor Appointment)',
                validator: (value) => ValidationUtils.validateRequired(value, fieldName: 'Title'),
                icon: Icons.event,
              ),
              const SizedBox(height: 16),

              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      label: 'Date',
                      value: _selectedDate,
                      onChanged: (date) => setState(() => _selectedDate = date ?? DateTime.now()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      label: 'Time',
                      value: _selectedTime,
                      onChanged: (time) => setState(() => _selectedTime = time ?? TimeOfDay.now()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status (only when editing)
              if (isEditing) ...[
                _buildStatusDropdown(),
                const SizedBox(height: 16),
              ],

              // Doctor Name
              _buildTextField(
                label: 'Doctor Name (Optional)',
                controller: _doctorNameController,
                hintText: 'Enter doctor\'s name',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              // Clinic Name
              _buildTextField(
                label: 'Clinic/Hospital (Optional)',
                controller: _clinicNameController,
                hintText: 'Enter clinic or hospital name',
                icon: Icons.local_hospital,
              ),
              const SizedBox(height: 16),

              // Location
              _buildTextField(
                label: 'Location (Optional)',
                controller: _locationController,
                hintText: 'Enter address or location',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),

              // Notes
              _buildTextField(
                label: 'Notes (Optional)',
                controller: _notesController,
                hintText: 'Add any additional notes',
                maxLines: 3,
                icon: Icons.note,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElderlyFriendlyButton(
                onPressed: _saveFollowUp,
                text: isEditing ? 'Update Follow-up' : 'Save Follow-up',
                icon: Icons.save,
              ),
              const SizedBox(height: 16),

              // Cancel Button
              if (isEditing)
                ElderlyFriendlyButton(
                  onPressed: () => Navigator.pop(context),
                  text: 'Cancel',
                  icon: Icons.cancel,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  textColor: Theme.of(context).colorScheme.onError,
                ),
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
    required IconData icon,
    FormFieldValidator<String>? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          validator: validator,
          maxLines: maxLines,
          minLines: maxLines > 1 ? 3 : 1,
          textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime value,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showDatePicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(value),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay value,
    required Function(TimeOfDay?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showTimePicker(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  value.format(context),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<FollowUpStatus>(
          value: _selectedStatus,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(
              _getStatusIcon(_selectedStatus),
              color: _getStatusColor(_selectedStatus),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          items: FollowUpStatus.values.map((status) {
            return DropdownMenuItem<FollowUpStatus>(
              value: status,
              child: Row(
                children: [
                  Text(status.emoji),
                  const SizedBox(width: 8),
                  Text(status.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedStatus = value);
            }
          },
        ),
      ],
    );
  }

  Color _getStatusColor(FollowUpStatus status) {
    switch (status) {
      case FollowUpStatus.scheduled:
        return Colors.blue;
      case FollowUpStatus.completed:
        return Colors.green;
      case FollowUpStatus.cancelled:
        return Colors.red;
      case FollowUpStatus.rescheduled:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(FollowUpStatus status) {
    switch (status) {
      case FollowUpStatus.scheduled:
        return Icons.schedule;
      case FollowUpStatus.completed:
        return Icons.check_circle;
      case FollowUpStatus.cancelled:
        return Icons.cancel;
      case FollowUpStatus.rescheduled:
        return Icons.update;
    }
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveFollowUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final dateTime = _combineDateAndTime();
      final followUp = createNewFollowUp(
        id: widget.followUpToEdit?.id,
        title: _titleController.text.trim(),
        date: dateTime,
        doctorName: _doctorNameController.text.trim().isNotEmpty
            ? _doctorNameController.text.trim()
            : null,
        clinicName: _clinicNameController.text.trim().isNotEmpty
            ? _clinicNameController.text.trim()
            : null,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        status: _selectedStatus,
        completedAt: _selectedStatus == FollowUpStatus.completed
            ? (widget.followUpToEdit?.completedAt ?? DateTime.now())
            : null,
      );

      if (widget.followUpToEdit != null) {
        await ref.read(followUpListProvider.notifier).updateFollowUp(followUp);
      } else {
        await ref.read(followUpListProvider.notifier).addFollowUp(followUp);
      }

      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.followUpToEdit != null
                ? 'Follow-up updated successfully'
                : 'Follow-up added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
