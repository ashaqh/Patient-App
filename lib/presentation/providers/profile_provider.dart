import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final notifier = ProfileNotifier(ref.watch(profileServiceProvider));
  notifier.loadProfile();
  return notifier;
});

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._service) : super(ProfileState.initial());

  final ProfileService _service;

  Future<void> loadProfile() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      final profile = await _service.getProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: $e',
      );
    }
  }

  Future<bool> saveProfile(ProfileData profile) async {
    try {
      state = state.copyWith(isSaving: true, clearError: true);
      await _service.saveProfile(profile);
      state = state.copyWith(isSaving: false, profile: profile);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save profile: $e',
      );
      return false;
    }
  }

  Future<void> clearProfile() async {
    try {
      state = state.copyWith(isSaving: true, clearError: true);
      await _service.clearProfile();
      state = state.copyWith(isSaving: false, profile: ProfileData.empty);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to clear profile: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

class ProfileState {
  const ProfileState({
    required this.profile,
    required this.isLoading,
    required this.isSaving,
    this.error,
  });

  final ProfileData profile;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  factory ProfileState.initial() => const ProfileState(
    profile: ProfileData.empty,
    isLoading: false,
    isSaving: false,
  );

  ProfileState copyWith({
    ProfileData? profile,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
