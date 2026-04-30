import 'package:flutter_riverpod/flutter_riverpod.dart';

// App state provider
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});

// App state model
class AppState {
  final bool isLoading;
  final String? error;
  final bool isDarkMode;
  final String currentScreen;

  const AppState({
    this.isLoading = false,
    this.error,
    this.isDarkMode = false,
    this.currentScreen = 'dashboard',
  });

  AppState copyWith({
    bool? isLoading,
    String? error,
    bool? isDarkMode,
    String? currentScreen,
  }) {
    return AppState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currentScreen: currentScreen ?? this.currentScreen,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is AppState &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isDarkMode == isDarkMode &&
        other.currentScreen == currentScreen;
  }

  @override
  int get hashCode {
    return isLoading.hashCode ^
        error.hashCode ^
        isDarkMode.hashCode ^
        currentScreen.hashCode;
  }
}

// App state notifier
class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(const AppState());

  // Set loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  // Set error state
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Toggle dark mode
  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  // Set current screen
  void setCurrentScreen(String screen) {
    state = state.copyWith(currentScreen: screen);
  }

  // Reset app state
  void reset() {
    state = const AppState();
  }
}

// Loading state provider (simplified)
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider.select((state) => state.isLoading));
});

// Error state provider (simplified)
final errorProvider = Provider<String?>((ref) {
  return ref.watch(appStateProvider.select((state) => state.error));
});

// Dark mode provider (simplified)
final darkModeProvider = Provider<bool>((ref) {
  return ref.watch(appStateProvider.select((state) => state.isDarkMode));
});

// Current screen provider (simplified)
final currentScreenProvider = Provider<String>((ref) {
  return ref.watch(appStateProvider.select((state) => state.currentScreen));
});