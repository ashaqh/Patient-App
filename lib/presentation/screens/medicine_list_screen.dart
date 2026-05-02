import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/medicine.dart';
import '../providers/medicine_provider.dart';
import 'add_medicine_screen.dart';

class MedicineListScreen extends ConsumerWidget {
  const MedicineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicineListState = ref.watch(medicineListProvider);
    final activeMedicinesAsync = ref.watch(activeMedicinesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medicines'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(medicineListProvider.notifier).refresh();
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
      body: _buildBody(context, ref, medicineListState, activeMedicinesAsync),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreen(),
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
    MedicineListState medicineListState,
    AsyncValue<List<Medicine>> activeMedicinesAsync,
  ) {
    // Show loading state
    if (medicineListState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (medicineListState.error != null) {
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
              'Error: ${medicineListState.error}',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(medicineListProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Statistics bar
        _buildStatisticsBar(context, activeMedicinesAsync),
        const SizedBox(height: 8),
        
        // Filter tabs
        _buildFilterTabs(context, ref),
        const SizedBox(height: 8),
        
        // Medicine list
        Expanded(
          child: _buildMedicineList(context, ref, medicineListState),
        ),
      ],
    );
  }

  Widget _buildStatisticsBar(BuildContext context, AsyncValue<List<Medicine>> activeMedicinesAsync) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              'Total',
              activeMedicinesAsync.when(
                data: (medicines) => medicines.length.toString(),
                loading: () => '...',
                error: (error, stackTrace) => '0',
              ),
              Icons.medication,
              Theme.of(context).colorScheme.primary,
            ),
            _buildStatItem(
              context,
              'Active',
              activeMedicinesAsync.when(
                data: (medicines) => medicines.where((m) => m.isActive).length.toString(),
                loading: () => '...',
                error: (error, stackTrace) => '0',
              ),
              Icons.check_circle,
              Colors.green,
            ),
            _buildStatItem(
              context,
              'Inactive',
              activeMedicinesAsync.when(
                data: (medicines) => medicines.where((m) => !m.isActive).length.toString(),
                loading: () => '...',
                error: (error, stackTrace) => '0',
              ),
              Icons.pause_circle,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: true,
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Active'),
            selected: false,
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Today'),
            selected: false,
            onSelected: (_) {},
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineList(BuildContext context, WidgetRef ref, MedicineListState medicineListState) {
    if (medicineListState.medicines.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: medicineListState.medicines.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final medicine = medicineListState.medicines[index];
        return _buildMedicineCard(context, ref, medicine);
      },
    );
  }

  Widget _buildMedicineCard(BuildContext context, WidgetRef ref, Medicine medicine) {
    final isTodayMedicine = medicine.shouldBeTakenToday();
    final nextReminderTime = medicine.getNextReminderTime();

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medicine.isActive 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
          child: Icon(
            medicine.isActive ? Icons.medication : Icons.medication_outlined,
            color: medicine.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
          ),
        ),
        title: Text(
          medicine.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${medicine.dosage}'),
            Text('Frequency: ${medicine.frequency}'),
            if (medicine.times.isNotEmpty)
              Text(
                'Times: ${medicine.times.join(", ")}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (isTodayMedicine && nextReminderTime != null)
              Text(
                'Next: ${_formatTime(nextReminderTime)}',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (medicine.notes != null && medicine.notes!.isNotEmpty)
              Text(
                'Note: ${medicine.notes}',
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editMedicine(context, medicine),
              tooltip: 'Edit',
            ),
            Switch(
              value: medicine.isActive,
              onChanged: (value) {
                _toggleMedicineStatus(context, ref, medicine.id, value);
              },
            ),
          ],
        ),
        onTap: () => _showMedicineDetails(context, medicine),
        onLongPress: () => _showDeleteDialog(context, ref, medicine),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No medicines added yet',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first medicine',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) async {
    final TextEditingController searchController = TextEditingController();

    final result = await showDialog<List<Medicine>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Medicines'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Enter medicine name',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final query = searchController.text.trim();
              if (query.isNotEmpty) {
                final results = await ref.read(medicineListProvider.notifier).searchMedicines(query);
                Navigator.pop(context, results);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _showSearchResults(context, result);
    } else if (result != null && result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No medicines found'),
        ),
      );
    }
  }

  Future<void> _showSearchResults(BuildContext context, List<Medicine> results) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search Results (${results.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final medicine = results[index];
              return ListTile(
                leading: Icon(
                  medicine.isActive ? Icons.medication : Icons.medication_outlined,
                  color: medicine.isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
                ),
                title: Text(medicine.name),
                subtitle: Text('Dosage: ${medicine.dosage}'),
                onTap: () {
                  Navigator.pop(context);
                  _showMedicineDetails(context, medicine);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editMedicine(BuildContext context, Medicine medicine) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${medicine.name}'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  void _toggleMedicineStatus(BuildContext context, WidgetRef ref, String id, bool isActive) async {
    try {
      await ref.read(medicineListProvider.notifier).toggleMedicineStatus(id, isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medicine ${isActive ? 'activated' : 'deactivated'}'),
          backgroundColor: isActive ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMedicineDetails(BuildContext context, Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(medicine.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailItem(context, 'Dosage', medicine.dosage, Icons.balance),
              _buildDetailItem(context, 'Frequency', medicine.frequency, Icons.schedule),
              if (medicine.times.isNotEmpty)
                _buildDetailItem(context, 'Times', medicine.times.join(", "), Icons.access_time),
              _buildDetailItem(
                context,
                'Start Date',
                '${medicine.startDate.year}-${medicine.startDate.month.toString().padLeft(2, '0')}-${medicine.startDate.day.toString().padLeft(2, '0')}',
                Icons.calendar_today,
              ),
              if (medicine.endDate != null)
                _buildDetailItem(
                  context,
                  'End Date',
                  '${medicine.endDate!.year}-${medicine.endDate!.month.toString().padLeft(2, '0')}-${medicine.endDate!.day.toString().padLeft(2, '0')}',
                  Icons.calendar_today,
                ),
              if (medicine.notes != null && medicine.notes!.isNotEmpty)
                _buildDetailItem(context, 'Notes', medicine.notes!, Icons.note),
              if (medicine.instructions != null && medicine.instructions!.isNotEmpty)
                _buildDetailItem(context, 'Instructions', medicine.instructions!, Icons.info),
              _buildDetailItem(
                context,
                'Status',
                medicine.isActive ? 'Active' : 'Inactive',
                medicine.isActive ? Icons.check_circle : Icons.pause_circle,
                color: medicine.isActive ? Colors.green : Colors.orange,
              ),
              if (medicine.shouldBeTakenToday())
                _buildDetailItem(
                  context,
                  'Today',
                  'Should be taken today',
                  Icons.today,
                  color: Colors.blue,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color ?? Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Medicine medicine) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete "${medicine.name}"? This will also cancel all scheduled reminders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteMedicine(context, ref, medicine.id);
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

  Future<void> _deleteMedicine(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(medicineListProvider.notifier).deleteMedicine(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicine deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting medicine: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}