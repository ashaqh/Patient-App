import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/reminder_scheduler.dart';
import '../../core/utils/error_utils.dart';
import '../../data/datasources/database_helper.dart';
import '../../data/repositories/medicine_repository_impl.dart';
import '../../domain/entities/medicine.dart';
import '../../domain/repositories/medicine_repository.dart';

// Medicine filter enum
enum MedicineFilter {
  all,
  active,
  inactive,
}

// Database helper provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

// Reminder scheduler provider (duplicated from reminder_provider.dart to avoid circular dependency)
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return ReminderScheduler(databaseHelper);
});

// Medicine repository provider
final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return MedicineRepositoryImpl(databaseHelper);
});

// Medicine list state
class MedicineListState {
  final List<Medicine> medicines;
  final bool isLoading;
  final String? error;
  final MedicineFilter filter;
  final String searchQuery;

  const MedicineListState({
    this.medicines = const [],
    this.isLoading = false,
    this.error,
    this.filter = MedicineFilter.all,
    this.searchQuery = '',
  });

  MedicineListState copyWith({
    List<Medicine>? medicines,
    bool? isLoading,
    String? error,
    MedicineFilter? filter,
    String? searchQuery,
  }) {
    return MedicineListState(
      medicines: medicines ?? this.medicines,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is MedicineListState &&
        other.medicines.length == medicines.length &&
        other.medicines.every((medicine) => medicines.contains(medicine)) &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.filter == filter &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return medicines.hashCode ^ 
           isLoading.hashCode ^ 
           error.hashCode ^ 
           filter.hashCode ^ 
           searchQuery.hashCode;
  }
}

// Medicine list notifier
class MedicineListNotifier extends StateNotifier<MedicineListState> {
  final MedicineRepository _medicineRepository;
  final ReminderScheduler _reminderScheduler;

  MedicineListNotifier(this._medicineRepository, this._reminderScheduler) : super(const MedicineListState()) {
    _loadMedicines();
  }

  // Load all medicines
  Future<void> _loadMedicines() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final medicines = await _medicineRepository.getAllMedicines();
      state = state.copyWith(medicines: medicines, isLoading: false);
    } catch (e, stackTrace) {
      ErrorUtils.logError(
        'Failed to load medicines',
        error: e,
        stackTrace: stackTrace,
        tag: 'Medicine',
      );
      state = state.copyWith(error: ErrorUtils.getUserFriendlyErrorMessage(e), isLoading: false);
    }
  }

  // Add new medicine
  Future<void> addMedicine(Medicine medicine) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _medicineRepository.createMedicine(medicine);
      
      // Schedule reminders for the new medicine
      if (medicine.isActive) {
        await _reminderScheduler.scheduleMedicineReminders(medicine);
      }
      
      await _loadMedicines(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Update medicine
  Future<void> updateMedicine(Medicine medicine) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Get current medicine to check if active status changed
      final currentMedicine = await _medicineRepository.getMedicineById(medicine.id);
      
      await _medicineRepository.updateMedicine(medicine);
      
      // Update reminders based on active status
      if (currentMedicine != null) {
        if (currentMedicine.isActive && !medicine.isActive) {
          // Medicine was deactivated, cancel reminders
          await _reminderScheduler.notificationService.cancelMedicineReminders(medicine.id);
        } else if (!currentMedicine.isActive && medicine.isActive) {
          // Medicine was activated, schedule reminders
          await _reminderScheduler.scheduleMedicineReminders(medicine);
        } else if (medicine.isActive) {
          // Medicine is still active, reschedule reminders (in case times changed)
          await _reminderScheduler.notificationService.cancelMedicineReminders(medicine.id);
          await _reminderScheduler.scheduleMedicineReminders(medicine);
        }
      }
      
      await _loadMedicines(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Delete medicine
  Future<void> deleteMedicine(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Cancel reminders before deleting medicine
      await _reminderScheduler.notificationService.cancelMedicineReminders(id);
      
      await _medicineRepository.deleteMedicineById(id);
      await _loadMedicines(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Toggle medicine active status
  Future<void> toggleMedicineStatus(String id, bool isActive) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Get current medicine to check current status
      final medicine = await _medicineRepository.getMedicineById(id);
      if (medicine == null) {
        throw Exception('Medicine not found');
      }
      
      await _medicineRepository.toggleMedicineStatus(id, isActive);
      
      // Update reminders based on new active status
      if (medicine.isActive && !isActive) {
        // Medicine was deactivated, cancel reminders
        await _reminderScheduler.notificationService.cancelMedicineReminders(id);
      } else if (!medicine.isActive && isActive) {
        // Medicine was activated, schedule reminders
        final updatedMedicine = medicine.copyWith(isActive: isActive);
        await _reminderScheduler.scheduleMedicineReminders(updatedMedicine);
      }
      
      await _loadMedicines(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Get medicines for today
  Future<List<Medicine>> getMedicinesForToday() async {
    try {
      return await _medicineRepository.getMedicinesForToday();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Search medicines
  Future<List<Medicine>> searchMedicines(String query) async {
    try {
      return await _medicineRepository.searchMedicines(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Refresh medicine list
  Future<void> refresh() async {
    await _loadMedicines();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Set filter
  void setFilter(MedicineFilter filter) {
    state = state.copyWith(filter: filter);
  }

  // Search medicines
  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Toggle medicine active status (alias for toggleMedicineStatus)
  Future<void> toggleMedicineActive(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Get current medicine to check current status
      final medicine = await _medicineRepository.getMedicineById(id);
      if (medicine == null) {
        throw Exception('Medicine not found');
      }
      
      final newActiveStatus = !medicine.isActive;
      await _medicineRepository.toggleMedicineStatus(id, newActiveStatus);
      
      // Update reminders based on new active status
      if (medicine.isActive && !newActiveStatus) {
        // Medicine was deactivated, cancel reminders
        await _reminderScheduler.notificationService.cancelMedicineReminders(id);
      } else if (!medicine.isActive && newActiveStatus) {
        // Medicine was activated, schedule reminders
        final updatedMedicine = medicine.copyWith(isActive: newActiveStatus);
        await _reminderScheduler.scheduleMedicineReminders(updatedMedicine);
      }
      
      await _loadMedicines(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
}

// Medicine list provider
final medicineListProvider = StateNotifierProvider<MedicineListNotifier, MedicineListState>((ref) {
  final medicineRepository = ref.watch(medicineRepositoryProvider);
  final reminderScheduler = ref.watch(reminderSchedulerProvider);
  return MedicineListNotifier(medicineRepository, reminderScheduler);
});

// Today's medicines provider
final todaysMedicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  final medicineRepository = ref.watch(medicineRepositoryProvider);
  return await medicineRepository.getMedicinesForToday();
});

// Active medicines provider
final activeMedicinesProvider = FutureProvider<List<Medicine>>((ref) async {
  final medicineRepository = ref.watch(medicineRepositoryProvider);
  return await medicineRepository.getActiveMedicines();
});

// Medicine count provider
final medicineCountProvider = FutureProvider<int>((ref) async {
  final medicineRepository = ref.watch(medicineRepositoryProvider);
  return await medicineRepository.getMedicineCount();
});

// Helper function to create a new medicine
Medicine createNewMedicine({
  String? id,
  required String name,
  required String dosage,
  required String frequency,
  required List<String> times,
  required DateTime startDate,
  DateTime? endDate,
  String? notes,
  String? instructions,
  bool isActive = true,
}) {
  return Medicine(
    id: id,
    name: name,
    dosage: dosage,
    frequency: frequency,
    times: times,
    startDate: startDate,
    endDate: endDate,
    notes: notes,
    instructions: instructions,
    isActive: isActive,
  );
}