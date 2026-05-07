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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Vault'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
        icon: const Icon(Icons.add),
        label: Text(_getActiveTab() == VaultCategory.testReports
            ? 'Add Test Report'
            : 'Add Prescription'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Text('Filter: ', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategory == VaultCategory.all,
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
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first prescription or test report',
              style: Theme.of(context).textTheme.bodyMedium,
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first prescription',
              style: Theme.of(context).textTheme.bodyMedium,
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first test report',
              style: Theme.of(context).textTheme.bodyMedium,
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
    return Card(
      elevation: 2,
      child: InkWell(
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
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${prescription.fileType}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    prescription.displayDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              if (prescription.doctorName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Dr. ${prescription.doctorName!}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (prescription.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  prescription.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
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
    return Card(
      elevation: 2,
      child: InkWell(
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
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.displayType,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    report.displayDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              if (report.testName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.biotech, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      report.testName!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (report.labName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      report.labName!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
              if (report.notes?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  report.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.description, color: Colors.blue),
              title: const Text('Add Prescription'),
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
            ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.green),
              title: const Text('Add Test Report'),
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
    );
  }

  void _showPrescriptionDetails(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prescription Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Text(prescription.fileIcon, style: const TextStyle(fontSize: 32)),
                title: Text(prescription.fileName),
                subtitle: Text('Type: ${prescription.fileType}'),
              ),
              const Divider(),
              _buildDetailItem('Date', DateFormat('MMMM dd, yyyy').format(prescription.date)),
              if (prescription.doctorName != null)
                _buildDetailItem('Doctor', 'Dr. ${prescription.doctorName!}'),
              if (prescription.clinicName != null)
                _buildDetailItem('Clinic', prescription.clinicName!),
              if (prescription.fileSize != null)
                _buildDetailItem('Size', '${prescription.fileSize!.toStringAsFixed(1)} KB'),
              if (prescription.notes?.isNotEmpty == true) ...[
                const Divider(),
                Text('Notes:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(prescription.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
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
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showPrescriptionActions(Prescription prescription) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showPrescriptionDetails(prescription);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeletePrescriptionConfirmation(prescription);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePrescriptionConfirmation(Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: Text('Are you sure you want to delete "${prescription.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTestReportDetails(TestReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Report Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(report.typeIcon, size: 32),
                title: Text(report.fileName),
                subtitle: Text('Type: ${report.displayType}'),
              ),
              const Divider(),
              _buildDetailItem('Date', DateFormat('MMMM dd, yyyy').format(report.date)),
              if (report.testName != null) _buildDetailItem('Test Name', report.testName!),
              if (report.labName != null) _buildDetailItem('Lab', report.labName!),
              if (report.doctorName != null)
                _buildDetailItem('Doctor', 'Dr. ${report.doctorName!}'),
              if (report.fileSize != null)
                _buildDetailItem('Size', '${report.fileSize!.toStringAsFixed(1)} KB'),
              if (report.notes?.isNotEmpty == true) ...[
                const Divider(),
                Text('Notes:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(report.notes!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
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
    );
  }

  void _showTestReportActions(TestReport report) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showTestReportDetails(report);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteTestReportConfirmation(report);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteTestReportConfirmation(TestReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Test Report'),
        content: Text('Are you sure you want to delete "${report.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Documents'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search by name, doctor, or notes',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
