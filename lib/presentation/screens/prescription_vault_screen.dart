import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../domain/entities/prescription.dart';
import '../../domain/entities/test_report.dart';
import '../providers/prescription_provider.dart';
import '../providers/test_report_provider.dart';
import 'add_prescription_screen.dart';
import 'add_test_report_screen.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';
import '../widgets/common/glass_widgets.dart';

enum VaultCategory {
  all,
  prescriptions,
  testReports,
}

class PrescriptionVaultScreen extends ConsumerStatefulWidget {
  const PrescriptionVaultScreen({super.key});

  @override
  ConsumerState<PrescriptionVaultScreen> createState() => _PrescriptionVaultScreenState();
}

class _PrescriptionVaultScreenState extends ConsumerState<PrescriptionVaultScreen>
    with SingleTickerProviderStateMixin {
  VaultCategory _selectedCategory = VaultCategory.all;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientOrbBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Prescription Vault'),
          backgroundColor: Colors.transparent,
          foregroundColor: AppTheme.onPrimaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _refreshData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _showSearchDialog(context);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Category filter chips
            _buildCategoryFilter(),
            // Tab bar for prescriptions and test reports
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.onSurfaceVariant,
              indicatorColor: AppTheme.primaryColor,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'All Documents'),
                Tab(text: 'Prescriptions'),
                Tab(text: 'Test Reports'),
              ],
              onTap: (index) {
                setState(() {
                  _selectedCategory = index == 0
                      ? VaultCategory.all
                      : index == 1
                          ? VaultCategory.prescriptions
                          : VaultCategory.testReports;
                });
              },
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllDocumentsView(),
                  _buildPrescriptionsView(),
                  _buildTestReportsView(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showAddDocumentOptions(context);
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          icon: const Icon(Icons.add),
          label: Text(_getActiveTab() == VaultCategory.testReports
              ? 'Add Test Report'
              : 'Add Prescription'),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text(
            'Filter: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategory == VaultCategory.all,
            backgroundColor: const Color(0x14FFFFFF),
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: Colors.white,
            side: const BorderSide(color: AppTheme.outlineColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: _selectedCategory == VaultCategory.all
                  ? Colors.white
                  : AppTheme.onSurfaceColor,
            ),
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? VaultCategory.all : _selectedCategory;
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Prescriptions'),
            selected: _selectedCategory == VaultCategory.prescriptions,
            backgroundColor: const Color(0x14FFFFFF),
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: Colors.white,
            side: const BorderSide(color: AppTheme.outlineColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: _selectedCategory == VaultCategory.prescriptions
                  ? Colors.white
                  : AppTheme.onSurfaceColor,
            ),
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? VaultCategory.prescriptions : _selectedCategory;
              });
            },
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Test Reports'),
            selected: _selectedCategory == VaultCategory.testReports,
            backgroundColor: const Color(0x14FFFFFF),
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: Colors.white,
            side: const BorderSide(color: AppTheme.outlineColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            labelStyle: TextStyle(
              color: _selectedCategory == VaultCategory.testReports
                  ? Colors.white
                  : AppTheme.onSurfaceColor,
            ),
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? VaultCategory.testReports : _selectedCategory;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllDocumentsView() {
    final prescriptionState = ref.watch(prescriptionListProvider);
    final testReportState = ref.watch(testReportListProvider);

    if (prescriptionState.isLoading || testReportState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (prescriptionState.error != null || testReportState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${prescriptionState.error ?? testReportState.error}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final allDocuments = [
      ...prescriptionState.prescriptions.map((p) => ('prescription', p)),
      ...testReportState.reports.map((r) => ('test_report', r)),
    ];

    // Sort by date
    allDocuments.sort((a, b) {
      final dateA = a.$1 == 'prescription'
          ? (a.$2 as Prescription).date
          : (a.$2 as TestReport).date;
      final dateB = b.$1 == 'prescription'
          ? (b.$2 as Prescription).date
          : (b.$2 as TestReport).date;
      return dateB.compareTo(dateA);
    });

    if (allDocuments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No documents yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.onSurfaceColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first prescription or test report',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allDocuments.length,
      itemBuilder: (context, index) {
        final doc = allDocuments[index];
        final isPrescription = doc.$1 == 'prescription';
        final entity = doc.$2;

        if (entity is Prescription) {
          return _buildPrescriptionCard(entity);
        } else if (entity is TestReport) {
          return _buildTestReportCard(entity);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildPrescriptionsView() {
    final state = ref.watch(prescriptionListProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(prescriptionListProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No prescriptions yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.onSurfaceColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first prescription',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.prescriptions.length,
      itemBuilder: (context, index) {
        return _buildPrescriptionCard(state.prescriptions[index]);
      },
    );
  }

  Widget _buildTestReportsView() {
    final state = ref.watch(testReportListProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(testReportListProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No test reports yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.onSurfaceColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first test report',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.reports.length,
      itemBuilder: (context, index) {
        return _buildTestReportCard(state.reports[index]);
      },
    );
  }

  Widget _buildPrescriptionCard(Prescription prescription) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          _showPrescriptionDetails(prescription);
        },
        onLongPress: () {
          _showPrescriptionActions(prescription);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    prescription.fileIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prescription.fileName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurfaceColor,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${prescription.fileType}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    prescription.displayDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              if (prescription.doctorName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      'Dr. ${prescription.doctorName!}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceColor,
                          ),
                    ),
                  ],
                ),
              ],
              if (prescription.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  prescription.notes!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestReportCard(TestReport report) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          _showTestReportDetails(report);
        },
        onLongPress: () {
          _showTestReportActions(report);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    report.typeIcon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.fileName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurfaceColor,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.displayType,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    report.displayDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              if (report.testName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.biotech, size: 16, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      report.testName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceColor,
                          ),
                    ),
                  ],
                ),
              ],
              if (report.labName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.business, size: 16, color: AppTheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      report.labName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceColor,
                          ),
                    ),
                  ],
                ),
              ],
              if (report.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  report.notes!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDocumentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassSurfaceStrong,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppTheme.outlineColor),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                    title: Text(
                      'Add Prescription',
                      style: TextStyle(color: AppTheme.onSurfaceColor, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPrescriptionScreen(),
                        ),
                      );
                    },
                  ),
                  Divider(color: AppTheme.outlineVariant, height: 1),
                  ListTile(
                    leading: const Icon(Icons.medical_services, color: AppTheme.primaryColor),
                    title: Text(
                      'Add Test Report',
                      style: TextStyle(color: AppTheme.onSurfaceColor, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTestReportScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPrescriptionDetails(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            borderRadius: 24,
            color: const Color(0xB2111827),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Prescription Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.m),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineColor),
                  ),
                  child: Row(
                    children: [
                      Text(prescription.fileIcon, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prescription.fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurfaceColor,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${prescription.fileType}',
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                const Divider(color: AppTheme.outlineVariant, height: 1),
                const SizedBox(height: AppSpacing.m),
                _buildDetailItem('Date', DateFormat('MMMM dd, yyyy').format(prescription.date)),
                if (prescription.doctorName != null)
                  _buildDetailItem('Doctor', 'Dr. ${prescription.doctorName!}'),
                if (prescription.clinicName != null)
                  _buildDetailItem('Clinic', prescription.clinicName!),
                if (prescription.fileSize != null)
                  _buildDetailItem('Size', '${prescription.fileSize!.toStringAsFixed(1)} KB'),
                if (prescription.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.m),
                  const Divider(color: AppTheme.outlineVariant, height: 1),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Notes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.onSurfaceColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prescription.notes!,
                    style: TextStyle(color: AppTheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: AppTheme.neutralColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.onPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                          vertical: AppSpacing.m,
                        ),
                        minimumSize: const Size(100, 48),
                      ),
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Opening ${prescription.fileName}...')),
                        );

                        try {
                          final result = await OpenFile.open(prescription.filePath);

                          if (result.type != ResultType.done) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to open file: ${result.message}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Error opening file: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('View File'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.onSurfaceColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionActions(Prescription prescription) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassSurfaceStrong,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppTheme.outlineColor),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.visibility, color: AppTheme.primaryColor),
                    title: Text(
                      'View Details',
                      style: TextStyle(color: AppTheme.onSurfaceColor, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showPrescriptionDetails(prescription);
                    },
                  ),
                  Divider(color: AppTheme.outlineVariant, height: 1),
                  ListTile(
                    leading: Icon(Icons.delete, color: AppTheme.errorColor),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeletePrescriptionConfirmation(prescription);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeletePrescriptionConfirmation(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xCC1E293B),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.outlineColor),
          ),
          title: Text(
            'Delete Prescription',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Text(
            'Are you sure you want to delete "${prescription.fileName}"?',
            style: TextStyle(color: AppTheme.onSurfaceColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.neutralColor, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.m,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref
                    .read(prescriptionListProvider.notifier)
                    .deletePrescription(prescription.id);
                ref.invalidate(recentPrescriptionsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${prescription.fileName}"')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestReportDetails(TestReport report) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.l),
            borderRadius: 24,
            color: const Color(0xB2111827),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Test Report Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.m),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.outlineColor),
                  ),
                  child: Row(
                    children: [
                      Icon(report.typeIcon, size: 32, color: AppTheme.primaryColor),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              report.fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSurfaceColor,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Type: ${report.displayType}',
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                const Divider(color: AppTheme.outlineVariant, height: 1),
                const SizedBox(height: AppSpacing.m),
                _buildDetailItem('Date', DateFormat('MMMM dd, yyyy').format(report.date)),
                if (report.testName != null) _buildDetailItem('Test Name', report.testName!),
                if (report.labName != null) _buildDetailItem('Lab', report.labName!),
                if (report.doctorName != null)
                  _buildDetailItem('Doctor', 'Dr. ${report.doctorName!}'),
                if (report.fileSize != null)
                  _buildDetailItem('Size', '${report.fileSize!.toStringAsFixed(1)} KB'),
                if (report.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.m),
                  const Divider(color: AppTheme.outlineVariant, height: 1),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'Notes:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.onSurfaceColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    report.notes!,
                    style: TextStyle(color: AppTheme.onSurfaceVariant, height: 1.4),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: AppTheme.neutralColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.onPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                          vertical: AppSpacing.m,
                        ),
                        minimumSize: const Size(100, 48),
                      ),
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        scaffoldMessenger.showSnackBar(
                          SnackBar(content: Text('Opening ${report.fileName}...')),
                        );

                        try {
                          final result = await OpenFile.open(report.filePath);

                          if (result.type != ResultType.done) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to open file: ${result.message}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Error opening file: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text('View File'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTestReportActions(TestReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassSurfaceStrong,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppTheme.outlineColor),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.visibility, color: AppTheme.primaryColor),
                    title: Text(
                      'View Details',
                      style: TextStyle(color: AppTheme.onSurfaceColor, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showTestReportDetails(report);
                    },
                  ),
                  Divider(color: AppTheme.outlineVariant, height: 1),
                  ListTile(
                    leading: Icon(Icons.delete, color: AppTheme.errorColor),
                    title: Text(
                      'Delete',
                      style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteTestReportConfirmation(report);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteTestReportConfirmation(TestReport report) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xCC1E293B),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.outlineColor),
          ),
          title: Text(
            'Delete Test Report',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Text(
            'Are you sure you want to delete "${report.fileName}"?',
            style: TextStyle(color: AppTheme.onSurfaceColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.neutralColor, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.m,
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(testReportListProvider.notifier).deleteReport(report.id);
                ref.invalidate(recentTestReportsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "${report.fileName}"')),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: const Color(0xCC1E293B),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppTheme.outlineColor),
          ),
          title: Text(
            'Search Documents',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name, doctor, or notes',
            ),
            style: TextStyle(color: AppTheme.onSurfaceColor),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppTheme.neutralColor, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.onPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.l,
                  vertical: AppSpacing.m,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search feature coming soon')),
                );
              },
              child: const Text('Search'),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshData() {
    ref.read(prescriptionListProvider.notifier).refresh();
    ref.read(testReportListProvider.notifier).refresh();
  }

  VaultCategory _getActiveTab() {
    return _selectedCategory;
  }
}
