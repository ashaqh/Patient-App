import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../domain/entities/prescription.dart';
import '../providers/prescription_provider.dart';
import 'add_prescription_screen.dart';
import '../../core/themes/app_theme.dart';
import '../../core/constants/spacing_constants.dart';

class PrescriptionListScreenNew extends ConsumerWidget {
  const PrescriptionListScreenNew({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionListState = ref.watch(prescriptionListProvider);
    final recentPrescriptionsAsync = ref.watch(recentPrescriptionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.secondaryColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar with gradient
          SliverAppBar(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: AppTheme.onPrimaryColor,
            elevation: 4,
            floating: true,
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  'Prescription Vault',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.onPrimaryColor,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.onPrimaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.search, size: 22),
                ),
                onPressed: () {
                  _showSearchDialog(context, ref);
                },
                tooltip: 'Search',
              ),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenHorizontal,
              vertical: AppSpacing.m,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Header
                _buildWelcomeHeader(context),
                const SizedBox(height: AppSpacing.l),

                // Statistics Section
                _buildStatisticsSection(context, recentPrescriptionsAsync),
                const SizedBox(height: AppSpacing.l),

                // Recent Prescriptions
                _buildRecentPrescriptionsSection(
                  context, 
                  ref, 
                  recentPrescriptionsAsync,
                ),
                const SizedBox(height: AppSpacing.l),

                // All Prescriptions
                _buildAllPrescriptionsSection(
                  context, 
                  ref, 
                  prescriptionListState,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddPrescriptionScreen(),
              ),
            );
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.onPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
          ),
          elevation: 6,
          icon: const Icon(Icons.add, size: 24),
          label: const Text(
            'Add Prescription',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Manage your prescription documents',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(BuildContext context, AsyncValue<List<Prescription>> recentPrescriptionsAsync) {
    return recentPrescriptionsAsync.when(
      data: (prescriptions) {
        final totalCount = prescriptions.length;
        final thisMonthCount = prescriptions
            .where((p) => _isThisMonth(p.date))
            .length;
        final lastUpload = prescriptions.isNotEmpty 
            ? DateFormat('MMM dd').format(prescriptions.first.date)
            : 'None';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vault Overview',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${totalCount.toString()} items',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              mainAxisSpacing: AppSpacing.m,
              crossAxisSpacing: AppSpacing.m,
              children: [
                _buildStatCard(
                  context,
                  'Total',
                  totalCount.toString(),
                  Icons.description,
                  AppTheme.primaryColor,
                  totalCount == 0 ? 'Start adding prescriptions' : 'All documents',
                ),
                _buildStatCard(
                  context,
                  'This Month',
                  thisMonthCount.toString(),
                  Icons.calendar_month,
                  thisMonthCount > 0 ? AppTheme.primaryColor : AppTheme.neutralColor,
                  'Added this month',
                ),
                _buildStatCard(
                  context,
                  'Last Upload',
                  lastUpload,
                  Icons.upload,
                  prescriptions.isNotEmpty ? AppTheme.primaryColor : AppTheme.neutralColor,
                  prescriptions.isNotEmpty ? 'Most recent' : 'No uploads yet',
                ),
              ],
            ),
          ],
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
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
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          border: Border.all(color: AppTheme.errorColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                'Error loading statistics',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPrescriptionsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Prescription>> recentPrescriptionsAsync,
  ) {
    return recentPrescriptionsAsync.when(
      data: (prescriptions) {
        if (prescriptions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: AppTheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'No recent uploads',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Start by adding your first prescription',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final recent = prescriptions.take(3).toList();

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Uploads',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.onSurfaceColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'New',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.onPrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.outlineVariant),
              ...recent.map((prescription) => Column(
                children: [
                  _buildPrescriptionCard(context, prescription, ref),
                  if (recent.last != prescription)
                    const Divider(height: 1, color: AppTheme.outlineVariant),
                ],
              )).toList(),
              if (prescriptions.length > 3)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSpacing.borderRadiusMedium),
                      bottomRight: Radius.circular(AppSpacing.borderRadiusMedium),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () {
                      // Show all prescriptions
                      ref.read(prescriptionListProvider.notifier).refresh();
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      padding: const EdgeInsets.all(AppSpacing.m),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(AppSpacing.borderRadiusMedium),
                          bottomRight: Radius.circular(AppSpacing.borderRadiusMedium),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View All ${prescriptions.length} Prescriptions',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppSpacing.m),
              Text('Loading recent prescriptions...'),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => Container(
        padding: const EdgeInsets.all(AppSpacing.l),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          border: Border.all(color: AppTheme.errorColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppTheme.errorColor),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Text(
                'Error loading recent prescriptions',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllPrescriptionsSection(
    BuildContext context,
    WidgetRef ref,
    PrescriptionListState prescriptionListState,
  ) {
    final prescriptions = prescriptionListState.prescriptions;
    
    if (prescriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.description_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'Your vault is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.onSurfaceColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Start by adding your first prescription document. You can upload PDFs or images of your prescriptions.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPrescriptionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.onPrimaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: AppSpacing.m,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 22),
                    const SizedBox(width: AppSpacing.s),
                    const Text(
                      'Add First Prescription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Prescriptions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.onSurfaceColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Text(
                    '${prescriptions.length} items',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.outlineVariant),
          ...prescriptions.map((prescription) => Column(
            children: [
              _buildPrescriptionCard(context, prescription, ref),
              if (prescriptions.last != prescription)
                const Divider(height: 1, color: AppTheme.outlineVariant),
            ],
          )).toList(),

        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, Prescription prescription, WidgetRef ref) {
    final date = DateFormat('MMM dd, yyyy').format(prescription.date);
    final doctorName = prescription.doctorName?.isNotEmpty == true ? prescription.doctorName : 'No doctor specified';
    final fileType = prescription.isPdf ? 'PDF' : 'Image';
    final fileIcon = prescription.isPdf ? Icons.picture_as_pdf : Icons.image;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
      ),
      child: InkWell(
        onTap: () {
          _showPrescriptionDetails(context, prescription, ref);
        },
        splashColor: AppTheme.primaryColor.withOpacity(0.1),
        highlightColor: AppTheme.primaryColor.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Type Badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  fileIcon,
                  color: AppTheme.onPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              
              // Prescription Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prescription Document',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.onSurfaceColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                date,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: fileType == 'PDF' 
                                ? const Color(0xFFF44336).withOpacity(0.1)
                                : const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: fileType == 'PDF' 
                                  ? const Color(0xFFF44336).withOpacity(0.3)
                                  : const Color(0xFF4CAF50).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            fileType,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: fileType == 'PDF' 
                                  ? const Color(0xFFF44336)
                                  : const Color(0xFF4CAF50),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.m),
                    
                    // Doctor Info
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 16,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Doctor',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                doctorName!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.onSurfaceColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Notes (if available)
                    if (prescription.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.m),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: 16,
                              color: AppTheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.s),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Notes',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    prescription.notes!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.onSurfaceColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // File Info and Actions
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            prescription.filePath.split('/').last,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              onPressed: () {
                                _showPrescriptionDetails(context, prescription, ref);
                              },
                              tooltip: 'View Details',
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              onPressed: () {
                                _showDeleteDialog(context, prescription.id, ref);
                              },
                              tooltip: 'Delete',
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
        ),
      ),
    );
  }

  void _showPrescriptionDetails(BuildContext context, Prescription prescription, WidgetRef ref) {
    final date = DateFormat('MMMM dd, yyyy').format(prescription.date);
    final time = DateFormat('h:mm a').format(prescription.date);
    final fileType = prescription.filePath.endsWith('.pdf') ? 'PDF Document' : 'Image File';
    final fileIcon = prescription.filePath.endsWith('.pdf') ? Icons.picture_as_pdf : Icons.image;
    final fileSize = prescription.fileSize != null 
        ? '${prescription.fileSize!.toStringAsFixed(1)} KB' 
        : 'Unknown size';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.borderRadiusLarge),
          topRight: Radius.circular(AppSpacing.borderRadiusLarge),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with drag indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    
                    // Prescription title
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            fileIcon,
                            color: AppTheme.onPrimaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prescription Details',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.onSurfaceColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Uploaded on $date at $time',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.l),
                    
                    // Details Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 3,
                      mainAxisSpacing: AppSpacing.m,
                      crossAxisSpacing: AppSpacing.m,
                      children: [
                        _buildDetailCard(
                          context,
                          'File Type',
                          fileType,
                          Icons.insert_drive_file,
                        ),
                        _buildDetailCard(
                          context,
                          'File Size',
                          fileSize,
                          Icons.storage,
                        ),
                        _buildDetailCard(
                          context,
                          'Date',
                          date,
                          Icons.calendar_today,
                        ),
                        _buildDetailCard(
                          context,
                          'Time',
                          time,
                          Icons.access_time,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.l),
                    
                    // Doctor Information
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Doctor Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.onSurfaceColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          _buildDetailRow(
                            context,
                            'Name',
                            prescription.doctorName?.isNotEmpty == true 
                                ? 'Dr. ${prescription.doctorName!}'
                                : 'Not specified',
                            Icons.person,
                          ),
                          if (prescription.clinicName?.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.s),
                            _buildDetailRow(
                              context,
                              'Clinic',
                              prescription.clinicName!,
                              Icons.business,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Notes Section
                    if (prescription.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: AppSpacing.l),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                          border: Border.all(
                            color: AppTheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.note,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Text(
                                  'Notes',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.onSurfaceColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.m),
                            Text(
                              prescription.notes!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: AppSpacing.l),
                    
                    // File Information
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                        border: Border.all(
                          color: AppTheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'File Information',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.onSurfaceColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          _buildDetailRow(
                            context,
                            'File Name',
                            prescription.filePath.split('/').last,
                            Icons.description,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          _buildDetailRow(
                            context,
                            'File Path',
                            prescription.filePath,
                            Icons.folder_open,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.l),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _showDeleteDialog(context, prescription.id, ref);
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                              side: BorderSide(color: AppTheme.errorColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.errorColor,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Text(
                                  'Delete',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Opening ${prescription.fileName}...'),
                                  backgroundColor: AppTheme.primaryColor,
                                ),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.onPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
                              ),
                              elevation: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.visibility, size: 20),
                                const SizedBox(width: AppSpacing.s),
                                Text(
                                  'View File',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.onPrimaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailCard(BuildContext context, String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  

  bool _isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
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
            'Search Prescriptions',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.onSurfaceColor,
            ),
          ),
          content: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by doctor name or notes...',
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
                  // TODO: Implement search functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Searching for "$query"...'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.onPrimaryColor,
                minimumSize: const Size(100, 48),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

  Future<void> _showDeleteDialog(BuildContext context, String prescriptionId, WidgetRef ref) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Delete Prescription',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.onSurfaceColor,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this prescription? This action cannot be undone.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
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
              onPressed: () async {
                await ref.read(prescriptionListProvider.notifier).deletePrescription(prescriptionId);
                // Invalidate the recent prescriptions provider to refresh the list
                ref.invalidate(recentPrescriptionsProvider);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: AppTheme.surfaceColor,
              ),
              child: Text(
                'Delete',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.surfaceColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
