import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/utils/validation_utils.dart';
import '../../domain/entities/follow_up.dart';
import '../providers/follow_up_provider.dart';

class AddFollowUpScreenNew extends ConsumerStatefulWidget {
  final FollowUp? followUpToEdit;

  const AddFollowUpScreenNew({super.key, this.followUpToEdit});

  @override
  ConsumerState<AddFollowUpScreenNew> createState() => _AddFollowUpScreenNewState();
}

class _AddFollowUpScreenNewState extends ConsumerState<AddFollowUpScreenNew> {
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
      backgroundColor: AppTheme.secondaryColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Follow-up' : 'Add Follow-up',
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
                  label: 'Title',
                  controller: _titleController,
                  hintText: 'Enter follow-up title (e.g., Doctor Appointment)',
                  validator: (value) => ValidationUtils.validateRequired(value, fieldName: 'Title'),
                  icon: Icons.event,
                ),
              ], title: 'Follow-up Details'),
              const SizedBox(height: AppSpacing.l),

              _buildSectionCard([
                _buildDatePicker(
                  label: 'Date',
                  value: _selectedDate,
                  onChanged: (date) => setState(() => _selectedDate = date ?? DateTime.now()),
                ),
                const SizedBox(height: AppSpacing.m),
                _buildTimePicker(
                  label: 'Time',
                  value: _selectedTime,
                  onChanged: (time) => setState(() => _selectedTime = time ?? TimeOfDay.now()),
                ),
              ], title: 'Schedule'),
              const SizedBox(height: AppSpacing.l),

              // Status (only when editing)
              if (isEditing) ...[
                _buildSectionCard([
                  _buildStatusDropdown(),
                ], title: 'Status'),
                const SizedBox(height: AppSpacing.l),
              ],

              _buildSectionCard([
                _buildTextField(
                  label: 'Doctor Name (Optional)',
                  controller: _doctorNameController,
                  hintText: 'Enter doctor\'s name',
                  icon: Icons.person,
                  validator: (_) => null,
                ),
                const SizedBox(height: AppSpacing.m),
                _buildTextField(
                  label: 'Clinic/Hospital (Optional)',
                  controller: _clinicNameController,
                  hintText: 'Enter clinic or hospital name',
                  icon: Icons.local_hospital,
                  validator: (_) => null,
                ),
                const SizedBox(height: AppSpacing.m),
                _buildTextField(
                  label: 'Location (Optional)',
                  controller: _locationController,
                  hintText: 'Enter address or location',
                  icon: Icons.location_on,
                  validator: (_) => null,
                ),
              ], title: 'Location Details'),
              const SizedBox(height: AppSpacing.l),

              _buildSectionCard([
                _buildTextField(
                  label: 'Notes (Optional)',
                  controller: _notesController,
                  hintText: 'Add any additional notes',
                  maxLines: 3,
                  icon: Icons.note,
                  validator: (_) => null,
                ),
              ], title: 'Additional Information'),
              const SizedBox(height: AppSpacing.l),

              _buildSaveButton(context, isEditing),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children, {required String title}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 opacity
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
            prefixIcon: icon != null ? Icon(icon, color: AppTheme.onSurfaceVariant) : null,
            filled: true,
            fillColor: AppTheme.secondaryColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              borderSide: const BorderSide(color: AppTheme.outlineColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              borderSide: const BorderSide(color: AppTheme.outlineColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              borderSide: const BorderSide(width: 2, color: AppTheme.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.m),
          ),
          validator: validator,
          maxLines: maxLines,
          style: Theme.of(context).textTheme.bodyMedium,
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => _showDatePicker(context),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              border: Border.all(color: AppTheme.outlineColor),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.m),
                Text(
                  DateFormat('EEE, MMM d, yyyy').format(value),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => _showTimePicker(context),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              border: Border.all(color: AppTheme.outlineColor),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.m),
                Text(
                  value.format(context),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<FollowUpStatus>(
          initialValue: _selectedStatus,
          decoration: InputDecoration(
            hintText: 'Select status',
            prefixIcon: Icon(
              _getStatusIcon(_selectedStatus),
              color: _getStatusColor(_selectedStatus),
            ),
            filled: true,
            fillColor: AppTheme.secondaryColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              borderSide: const BorderSide(color: AppTheme.outlineColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              borderSide: const BorderSide(color: AppTheme.outlineColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              borderSide: const BorderSide(width: 2, color: AppTheme.primaryColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.m),
          ),
          items: FollowUpStatus.values.map((status) {
            return DropdownMenuItem<FollowUpStatus>(
              value: status,
              child: Row(
                children: [
                  Text(status.emoji),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    status.displayName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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

  Widget _buildSaveButton(BuildContext context, bool isEditing) {
    final followUpListState = ref.watch(followUpListProvider);

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: followUpListState.isLoading ? null : _saveFollowUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
          elevation: 2,
        ),
        child: followUpListState.isLoading
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
                  Icon(isEditing ? Icons.save : Icons.add),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    isEditing ? 'Update Follow-up' : 'Save Follow-up',
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
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.onPrimaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.onSurfaceColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
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
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.onPrimaryColor,
              surface: AppTheme.surfaceColor,
              onSurface: AppTheme.onSurfaceColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
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

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.followUpToEdit != null
                ? 'Follow-up updated successfully'
                : 'Follow-up added successfully',
          ),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}