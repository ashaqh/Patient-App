import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/prescription_repository_impl.dart';
import '../../domain/entities/prescription.dart';
import '../../domain/repositories/prescription_repository.dart';

// Import database helper provider from medicine_provider
import 'medicine_provider.dart';

// Prescription repository provider
final prescriptionRepositoryProvider = Provider<PrescriptionRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return PrescriptionRepositoryImpl(databaseHelper);
});

// Prescription list state
class PrescriptionListState {
  final List<Prescription> prescriptions;
  final bool isLoading;
  final String? error;

  const PrescriptionListState({
    this.prescriptions = const [],
    this.isLoading = false,
    this.error,
  });

  PrescriptionListState copyWith({
    List<Prescription>? prescriptions,
    bool? isLoading,
    String? error,
  }) {
    return PrescriptionListState(
      prescriptions: prescriptions ?? this.prescriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PrescriptionListState &&
        other.prescriptions.length == prescriptions.length &&
        other.prescriptions.every((prescription) => prescriptions.contains(prescription)) &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return prescriptions.hashCode ^ isLoading.hashCode ^ error.hashCode;
  }
}

// Prescription list notifier
class PrescriptionListNotifier extends StateNotifier<PrescriptionListState> {
  final PrescriptionRepository _prescriptionRepository;

  PrescriptionListNotifier(this._prescriptionRepository) : super(const PrescriptionListState()) {
    _loadPrescriptions();
  }

  // Load all prescriptions
  Future<void> _loadPrescriptions() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final prescriptions = await _prescriptionRepository.getAllPrescriptions();
      state = state.copyWith(prescriptions: prescriptions, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Add new prescription
  Future<void> addPrescription(Prescription prescription) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _prescriptionRepository.createPrescription(prescription);
      await _loadPrescriptions(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Update prescription
  Future<void> updatePrescription(Prescription prescription) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _prescriptionRepository.updatePrescription(prescription);
      await _loadPrescriptions(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Delete prescription
  Future<void> deletePrescription(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _prescriptionRepository.deletePrescriptionById(id);
      await _loadPrescriptions(); // Reload the list
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }

  // Search prescriptions
  Future<List<Prescription>> searchPrescriptions(String query) async {
    try {
      return await _prescriptionRepository.searchPrescriptions(query);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Get prescriptions by doctor
  Future<List<Prescription>> getPrescriptionsByDoctor(String doctorName) async {
    try {
      return await _prescriptionRepository.getPrescriptionsByDoctor(doctorName);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Get prescriptions by date range
  Future<List<Prescription>> getPrescriptionsByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _prescriptionRepository.getPrescriptionsByDateRange(startDate, endDate);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Get recent prescriptions
  Future<List<Prescription>> getRecentPrescriptions({int limit = 10}) async {
    try {
      return await _prescriptionRepository.getRecentPrescriptions(limit: limit);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // Get prescription count
  Future<int> getPrescriptionCount() async {
    try {
      return await _prescriptionRepository.getPrescriptionCount();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return 0;
    }
  }

  // Refresh prescription list
  Future<void> refresh() async {
    await _loadPrescriptions();
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Prescription list provider
final prescriptionListProvider = StateNotifierProvider<PrescriptionListNotifier, PrescriptionListState>((ref) {
  final prescriptionRepository = ref.watch(prescriptionRepositoryProvider);
  return PrescriptionListNotifier(prescriptionRepository);
});

// Recent prescriptions provider
final recentPrescriptionsProvider = FutureProvider<List<Prescription>>((ref) async {
  final prescriptionRepository = ref.watch(prescriptionRepositoryProvider);
  return await prescriptionRepository.getRecentPrescriptions(limit: 5);
});

// Prescription count provider
final prescriptionCountProvider = FutureProvider<int>((ref) async {
  final prescriptionRepository = ref.watch(prescriptionRepositoryProvider);
  return await prescriptionRepository.getPrescriptionCount();
});

// Helper function to create a new prescription
Prescription createNewPrescription({
  String? id,
  required String filePath,
  required String fileName,
  required String fileType,
  required DateTime date,
  String? notes,
  String? doctorName,
  String? clinicName,
  double? fileSize,
}) {
  return Prescription(
    id: id,
    filePath: filePath,
    fileName: fileName,
    fileType: fileType,
    date: date,
    notes: notes,
    doctorName: doctorName,
    clinicName: clinicName,
    fileSize: fileSize,
  );
}