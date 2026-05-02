import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/elderly_friendly_button.dart';
import '../../core/utils/file_utils.dart';
import '../providers/prescription_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Prescription'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File upload section
                    _buildFileUploadSection(),
                    const SizedBox(height: 24),

                    // Date
                    _buildDatePicker(),
                    const SizedBox(height: 16),

                    // Doctor name
                    _buildTextField(
                      label: 'Doctor Name (Optional)',
                      controller: _doctorNameController,
                      hintText: 'Enter doctor name',
                      icon: Icons.person,
                      validator: (_) => null, // Optional field
                    ),
                    const SizedBox(height: 16),

                    // Clinic name
                    _buildTextField(
                      label: 'Clinic/Hospital (Optional)',
                      controller: _clinicNameController,
                      hintText: 'Enter clinic or hospital name',
                      icon: Icons.local_hospital,
                      validator: (_) => null, // Optional field
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    _buildTextField(
                      label: 'Notes (Optional)',
                      controller: _notesController,
                      hintText: 'Any additional notes about this prescription',
                      maxLines: 3,
                      icon: Icons.note,
                      validator: (_) => null, // Optional field
                    ),
                    const SizedBox(height: 24),

                    // Add button
                    _buildAddButton(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFileUploadSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prescription File',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload a photo or document of your prescription',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            if (_selectedFile != null) ...[
              _buildSelectedFileInfo(),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: ElderlyFriendlyButton(
                    onPressed: () => _pickImageFromGallery(),
                    text: 'Gallery',
                    icon: Icons.photo_library,
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElderlyFriendlyButton(
                    onPressed: () => _takePhotoWithCamera(),
                    text: 'Camera',
                    icon: Icons.camera_alt,
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    textColor: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElderlyFriendlyButton(
              onPressed: () => _pickFileFromStorage(),
              text: 'Browse Files',
              icon: Icons.insert_drive_file,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              textColor: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFileInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(),
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
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
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (_fileSize != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${_fileSize!.toStringAsFixed(1)} KB',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 12),
                Text(
                  DateFormat('MMMM dd, yyyy').format(_date),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
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
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
contentPadding: EdgeInsets.symmetric(
  horizontal: 16,
  vertical: maxLines > 1 ? 16 : 0,
),
          ),
          validator: validator,
          maxLines: maxLines,
          textInputAction: TextInputAction.next,
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        textColor: Theme.of(context).colorScheme.onPrimary,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prescription added successfully'),
          backgroundColor: Colors.green,
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
        backgroundColor: Colors.red,
      ),
    );
  }
}