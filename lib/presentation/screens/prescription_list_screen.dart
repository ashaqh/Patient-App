import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../domain/entities/prescription.dart';
import '../providers/prescription_provider.dart';
import 'add_prescription_screen.dart';

class PrescriptionListScreen extends ConsumerWidget {
  const PrescriptionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionListState = ref.watch(prescriptionListProvider);
    final recentPrescriptionsAsync = ref.watch(recentPrescriptionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Prescriptions'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(prescriptionListProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context, ref);
            },
          ),
        ],
      ),
      body: _buildBody(context, ref, prescriptionListState, recentPrescriptionsAsync),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPrescriptionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PrescriptionListState prescriptionListState,
    AsyncValue<List<Prescription>> recentPrescriptionsAsync,
  ) {
    // Show loading state
    if (prescriptionListState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (prescriptionListState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${prescriptionListState.error}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(prescriptionListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (prescriptionListState.prescriptions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No prescriptions yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first prescription by tapping the + button',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Recent prescriptions section
        if (recentPrescriptionsAsync.valueOrNull?.isNotEmpty == true) ...[
          _buildRecentPrescriptionsSection(context, ref, recentPrescriptionsAsync),
          const Divider(),
        ],
        
        // All prescriptions list
        Expanded(
          child: _buildPrescriptionList(context, ref, prescriptionListState),
        ),
      ],
    );
  }

  Widget _buildRecentPrescriptionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Prescription>> recentPrescriptionsAsync,
  ) {
    return recentPrescriptionsAsync.when(
      data: (prescriptions) {
        if (prescriptions.isEmpty) return const SizedBox();
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent Prescriptions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...prescriptions.map((prescription) => 
                _buildPrescriptionCard(context, ref, prescription, isRecent: true)
              ).toList(),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const SizedBox(),
    );
  }

  Widget _buildPrescriptionList(
    BuildContext context,
    WidgetRef ref,
    PrescriptionListState prescriptionListState,
  ) {
    return RefreshIndicator(
      onRefresh: () => ref.read(prescriptionListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: prescriptionListState.prescriptions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final prescription = prescriptionListState.prescriptions[index];
          return _buildPrescriptionCard(context, ref, prescription);
        },
      ),
    );
  }

  Widget _buildPrescriptionCard(
    BuildContext context,
    WidgetRef ref,
    Prescription prescription, {
    bool isRecent = false,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showPrescriptionDetails(context, prescription);
        },
        onLongPress: () {
          _showPrescriptionActions(context, ref, prescription);
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
                  if (!isRecent)
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
              if (prescription.fileSize != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${prescription.fileSize!.toStringAsFixed(1)} KB',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Prescriptions'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search by doctor, notes, or filename',
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
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement search functionality
              // For now, just show a snackbar
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

  void _showPrescriptionDetails(BuildContext context, Prescription prescription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Prescription Details'),
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
                // Open the file using the file path
                final result = await OpenFile.open(prescription.filePath);
                
                if (result.type != ResultType.done) {
                  // Show error message if file couldn't be opened
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to open file: ${result.message}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Show error message if an exception occurs
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

  void _showPrescriptionActions(BuildContext context, WidgetRef ref, Prescription prescription) {
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
                _showPrescriptionDetails(context, prescription);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit feature coming soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, ref, prescription);
            },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, Prescription prescription) {
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
              await _deletePrescription(context, ref, prescription);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePrescription(BuildContext context, WidgetRef ref, Prescription prescription) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      await ref.read(prescriptionListProvider.notifier).deletePrescription(prescription.id);
      // Invalidate the recent prescriptions provider to refresh the list
      ref.invalidate(recentPrescriptionsProvider);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Deleted "${prescription.fileName}"')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error deleting prescription: $e')),
      );
    }
  }
}