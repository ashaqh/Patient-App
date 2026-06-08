import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../../core/widgets/elderly_friendly_button.dart';
import '../../core/utils/file_utils.dart';
import '../providers/prescription_provider.dart';
import '../widgets/common/glass_widgets.dart';

class AddPrescriptionScreen extends ConsumerStatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  ConsumerState<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends ConsumerState<AddPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _doctorNameController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();
  File? _selectedFile;
  String? _fileName;
  String? _fileType;
  double? _fileSize;

  bool _isLoading = false;

  @override
  void dispose() {
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientOrbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimaryColor,
          elevation: 0,
          title: Text(
            'Add Prescription',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.onPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // File upload section
                      _buildSectionCard([
                        _buildFileUploadContent(),
                      ], title: 'Prescription Document'),
                      const SizedBox(height: AppSpacing.l),

                      // Prescription Details
                      _buildSectionCard([
                        _buildDatePicker(),
                        const SizedBox(height: AppSpacing.m),
                        _buildTextField(
                          label: 'Doctor Name (Optional)',
                          controller: _doctorNameController,
                          hintText: 'Enter doctor name',
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
                      ], title: 'Prescription Details'),
                      const SizedBox(height: AppSpacing.l),

                      // Notes
                      _buildSectionCard([
                        _buildTextField(
                          label: 'Notes (Optional)',
                          controller: _notesController,
                          hintText: 'Any additional notes about this prescription',
                          maxLines: 3,
                          icon: Icons.note,
                          validator: (_) => null,
                        ),
                      ], title: 'Additional Notes'),
                      const SizedBox(height: AppSpacing.xl),

                      // Add button
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

  Widget _buildFileUploadContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload a photo or document of your prescription',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        if (_selectedFile != null) ...[
          _buildSelectedFileInfo(),
          const SizedBox(height: AppSpacing.m),
        ],

        Row(
          children: [
            Expanded(
              child: ElderlyFriendlyButton(
                onPressed: () => _pickImageFromGallery(),
                text: 'Gallery',
                icon: Icons.photo_library,
                backgroundColor: const Color(0x14FFFFFF),
                textColor: AppTheme.onSurfaceColor,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: ElderlyFriendlyButton(
                onPressed: () => _takePhotoWithCamera(),
                text: 'Camera',
                icon: Icons.camera_alt,
                backgroundColor: const Color(0x14FFFFFF),
                textColor: AppTheme.onSurfaceColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        ElderlyFriendlyButton(
          onPressed: () => _pickFileFromStorage(),
          text: 'Browse Files',
          icon: Icons.insert_drive_file,
          backgroundColor: const Color(0x14FFFFFF),
          textColor: AppTheme.onSurfaceColor,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSelectedFileInfo() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(),
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? 'Unknown file',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_fileType != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Type: $_fileType',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (_fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${_fileSize!.toStringAsFixed(1)} KB',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.errorColor),
            onPressed: () {
              setState(() {
                _selectedFile = null;
                _fileName = null;
                _fileType = null;
                _fileSize = null;
              });
            },
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    if (_fileType?.toLowerCase().contains('pdf') == true) {
      return Icons.picture_as_pdf;
    } else if (_fileType?.toLowerCase().contains('image') == true ||
        _fileType?.toLowerCase().contains('jpg') == true ||
        _fileType?.toLowerCase().contains('jpeg') == true ||
        _fileType?.toLowerCase().contains('png') == true) {
      return Icons.photo;
    } else if (_fileType?.toLowerCase().contains('doc') == true) {
      return Icons.description;
    }
    return Icons.insert_drive_file;
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prescription Date',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => _selectDate(context),
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
                  DateFormat('MMMM dd, yyyy').format(_date),
                  style: Theme.of(context).textTheme.bodyLarge,
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

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElderlyFriendlyButton(
        onPressed: () => _addPrescription(context),
        text: 'Add Prescription',
        icon: Icons.add,
        backgroundColor: AppTheme.primaryColor,
        textColor: AppTheme.onPrimaryColor,
        fontSize: 18,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        _handleFileSelection(result.files.first);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final file = File(image.path);
        setState(() {
          _selectedFile = file;
          _fileName = image.name;
          _fileType = 'image/${image.path.split('.').last}';
          _fileSize = file.lengthSync() / 1024; // Convert to KB
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to take photo: $e');
    }
  }

  Future<void> _pickFileFromStorage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.isNotEmpty) {
        _handleFileSelection(result.files.first);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick file: $e');
    }
  }

  void _handleFileSelection(PlatformFile platformFile) {
    final file = File(platformFile.path!);
    final fileType = FileUtils.getFileType('.${platformFile.extension ?? 'unknown'}');
    
    setState(() {
      _selectedFile = file;
      _fileName = platformFile.name;
      _fileType = fileType;
      _fileSize = platformFile.size / 1024; // Convert to KB
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: AppTheme.datePickerThemeBuilder,
    );

    if (pickedDate != null) {
      setState(() {
        _date = pickedDate;
      });
    }
  }

  Future<void> _addPrescription(BuildContext context) async {
    if (_selectedFile == null) {
      _showErrorSnackbar('Please select a prescription file');
      return;
    }

    // Check file size
    if (!FileUtils.isFileSizeValid(_selectedFile!)) {
      _showErrorSnackbar('File is too large. Maximum size is 10MB');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save file to app directory
      final fileInfo = await FileUtils.savePrescriptionFile(_selectedFile!);

      final prescription = createNewPrescription(
        filePath: fileInfo['path'],
        fileName: fileInfo['name'],
        fileType: fileInfo['type'],
        date: _date,
        doctorName: _doctorNameController.text.isNotEmpty
            ? _doctorNameController.text
            : null,
        clinicName: _clinicNameController.text.isNotEmpty
            ? _clinicNameController.text
            : null,
        notes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
        fileSize: fileInfo['size'],
      );

      await ref.read(prescriptionListProvider.notifier).addPrescription(prescription);

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Prescription added successfully'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );

      // Navigate back
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to add prescription: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}
