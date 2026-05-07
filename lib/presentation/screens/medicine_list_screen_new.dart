import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/medicine.dart';
import '../providers/medicine_provider.dart';
import 'add_medicine_screen_new.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';

class MedicineListScreenNew extends ConsumerWidget {
  const MedicineListScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicineListState = ref.watch(medicineListProvider);
    final activeMedicinesAsync = ref.watch(activeMedicinesProvider);

    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.onPrimaryColor,
            elevation: 0,
            floating: true,
            pinned: true,
            title: Text(
              'My Medicines',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.onPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  _showSearchDialog(context, ref);
                },
                tooltip: 'Search',
              ),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Statistics Cards
                _buildStatisticsSection(context, activeMedicinesAsync),
                const SizedBox(height: AppSpacing.l),

                // Filter Tabs
                _buildFilterTabs(context, ref),
                const SizedBox(height: AppSpacing.l),

                // Medicine List
                _buildMedicineList(context, ref, medicineListState),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreenNew(),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.onPrimaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, AsyncValue<List<Medicine>> activeMedicinesAsync) {
    return activeMedicinesAsync.when(
      data: (medicines) {
        final activeCount = medicines.length;
        final todayCount = medicines.where((m) => _isMedicineActiveToday(m)).length;
        final completedCount = medicines.where((m) => !m.isActive).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              mainAxisSpacing: AppSpacing.s,
              crossAxisSpacing: AppSpacing.s,
              children: [
                _buildStatCard(
                  context,
                  'Active',
                  activeCount.toString(),
                  Icons.medication,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  context,
                  'Today',
                  todayCount.toString(),
                  Icons.today,
                  AppTheme.primaryColor,
                ),
                _buildStatCard(
                  context,
                  'Completed',
                  completedCount.toString(),
                  Icons.check_circle,
                  AppTheme.neutralColor,
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: AppSpacing.m),
            Text('Loading statistics...'),
          ],
        ),
      ),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          border: Border.all(color: AppTheme.errorColor),
        ),
        child: Text(
          'Error loading statistics',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.errorColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(medicineListProvider).filter;
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        border: Border.all(
          width: 1,
          color: AppTheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterTab(
            context,
            label: 'All',
            isActive: filter == MedicineFilter.all,
            onTap: () => ref.read(medicineListProvider.notifier).setFilter(MedicineFilter.all),
          ),
          _buildFilterTab(
            context,
            label: 'Active',
            isActive: filter == MedicineFilter.active,
            onTap: () => ref.read(medicineListProvider.notifier).setFilter(MedicineFilter.active),
          ),
          _buildFilterTab(
            context,
            label: 'Completed',
            isActive: filter == MedicineFilter.inactive,
            onTap: () => ref.read(medicineListProvider.notifier).setFilter(MedicineFilter.inactive),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isActive ? AppTheme.onPrimaryColor : AppTheme.onSurfaceColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineList(
    BuildContext context,
    WidgetRef ref,
    MedicineListState medicineListState,
  ) {
    final medicines = medicineListState.medicines;
    
    if (medicines.isEmpty) {
      return _buildEmptyState(
        context,
        medicineListState.filter == MedicineFilter.active
            ? 'No active medicines'
            : medicineListState.filter == MedicineFilter.inactive
                ? 'No completed medicines'
                : 'No medicines added yet',
        Icons.medication,
        onAddTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddMedicineScreenNew(),
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medicines',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.onSurfaceColor,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        ...medicines.map((medicine) => _buildMedicineCard(context, medicine, ref)).toList(),
      ],
    );
  }

  Widget _buildMedicineCard(BuildContext context, Medicine medicine, WidgetRef ref) {
    final timesText = medicine.times.join(', ');
    final timesDisplayText = medicine.times.map(_formatTimeForDisplay).join(', ');
    final status = _getMedicineStatus(medicine);
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Medicine header
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                  ),
                  child: Icon(
                    Icons.medication,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.onSurfaceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${medicine.dosage} • ${medicine.frequency}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context, status),
              ],
            ),
          ),

          // Medicine details
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.borderRadiusMedium),
                bottomRight: Radius.circular(AppSpacing.borderRadiusMedium),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  timesText.isNotEmpty ? timesDisplayText : 'No specific times',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Duration: ${_formatDate(medicine.startDate)} - ${medicine.endDate != null ? _formatDate(medicine.endDate!) : "Ongoing"}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {
                            _editMedicine(context, medicine);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                        ),
                        const SizedBox(width: AppSpacing.s),
                        IconButton(
                          icon: Icon(
                            medicine.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                            size: 20,
                          ),
                          onPressed: () {
                            ref.read(medicineListProvider.notifier).toggleMedicineActive(medicine.id!);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color badgeColor;
    Color textColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'active':
        badgeColor = AppTheme.primaryColor.withOpacity(0.1);
        textColor = AppTheme.primaryColor;
        borderColor = AppTheme.primaryColor;
        break;
      case 'completed':
        badgeColor = AppTheme.neutralColor.withOpacity(0.1);
        textColor = AppTheme.neutralColor;
        borderColor = AppTheme.neutralColor;
        break;
      case 'inactive':
      default:
        badgeColor = AppTheme.errorColor.withOpacity(0.1);
        textColor = AppTheme.errorColor;
        borderColor = AppTheme.errorColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 1,
          color: borderColor,
        ),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message,
    IconData icon, {
    VoidCallback? onAddTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        border: Border.all(
          width: 1,
          color: AppTheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          if (onAddTap != null) ...[
            const SizedBox(height: AppSpacing.l),
            ElevatedButton(
              onPressed: onAddTap,
              style: AppTheme.primaryButtonStyle,
              child: const Text('Add Your First Medicine'),
            ),
          ],
        ],
      ),
    );
  }

  bool _isMedicineActiveToday(Medicine medicine) {
    final now = DateTime.now();
    final startDate = medicine.startDate;
    
    if (medicine.endDate != null) {
      final endDate = medicine.endDate!;
      return !now.isBefore(startDate) && !now.isAfter(endDate);
    }
    
    return !now.isBefore(startDate);
  }

  String _getMedicineStatus(Medicine medicine) {
    if (!medicine.isActive) return 'Inactive';
    if (!_isMedicineActiveToday(medicine)) return 'Completed';
    return 'Active';
  }

  Future<void> _showSearchDialog(BuildContext context, WidgetRef ref) async {
    final TextEditingController searchController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Search Medicines',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.onSurfaceColor,
            ),
          ),
          content: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Enter medicine name...',
              filled: true,
              fillColor: AppTheme.secondaryColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                borderSide: const BorderSide(color: AppTheme.outlineColor),
              ),
              contentPadding: const EdgeInsets.all(AppSpacing.m),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final query = searchController.text.trim();
                if (query.isNotEmpty) {
                  ref.read(medicineListProvider.notifier).search(query);
                  Navigator.pop(context);
                }
              },
              style: AppTheme.primaryButtonStyle.copyWith(
                minimumSize: MaterialStateProperty.all(const Size(100, 48)),
              ),
              child: Text(
                'Search',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onPrimaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _editMedicine(BuildContext context, Medicine medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreenNew(medicine: medicine),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
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
