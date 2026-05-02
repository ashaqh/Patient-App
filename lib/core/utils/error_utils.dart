import 'dart:developer' as developer;
import '../utils/error_utils.dart';

/// Error handling utilities for the Patient Companion App
/// Provides consistent error logging and user-friendly error messages

class ErrorUtils {
  // Private constructor to prevent instantiation
  ErrorUtils._();

  /// Log an error with contextual information
  static void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final tagPrefix = tag != null ? '[$tag] ' : '';
    
    developer.log(
      '$tagPrefix$message',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      level: 1000, // SEVERE level
    );
  }

  /// Log a warning with contextual information
  static void logWarning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final tagPrefix = tag != null ? '[$tag] ' : '';
    
    developer.log(
      '$tagPrefix$message',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
      level: 800, // WARNING level
    );
  }

  /// Log information for debugging
  static void logInfo(
    String message, {
    String? tag,
  }) {
    final tagPrefix = tag != null ? '[$tag] ' : '';
    
    developer.log(
      '$tagPrefix$message',
      time: DateTime.now(),
      level: 600, // INFO level
    );
  }

  /// Convert a technical error to a user-friendly message for elderly users
  static String getUserFriendlyErrorMessage(Object error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('database') || errorString.contains('sql')) {
      return 'Sorry, there was a problem with your data. Please try again.';
    } else if (errorString.contains('network') || errorString.contains('internet')) {
      return 'Please check your internet connection and try again.';
    } else if (errorString.contains('file') || errorString.contains('storage')) {
      return 'Unable to access the file. Please check permissions and try again.';
    } else if (errorString.contains('permission') || errorString.contains('access')) {
      return 'App needs permission to perform this action. Please check app settings.';
    } else if (errorString.contains('notification')) {
      return 'Unable to set reminder. Please check notification permissions.';
    } else if (errorString.contains('timeout') || errorString.contains('timed out')) {
      return 'Action took too long. Please try again.';
    } else if (errorString.contains('validation') || errorString.contains('invalid')) {
      return 'Please check your input and try again.';
    } else if (errorString.contains('not found') || errorString.contains('does not exist')) {
      return 'Item not found. It may have been deleted.';
    } else if (errorString.contains('duplicate') || errorString.contains('already exists')) {
      return 'This item already exists.';
    } else if (errorString.contains('empty') || errorString.contains('required')) {
      return 'Please fill in all required fields.';
    } else if (errorString.contains('format') || errorString.contains('parse')) {
      return 'Invalid format. Please check your input.';
    }
    
    // Generic error message for elderly users
    return 'Something went wrong. Please try again.';
  }

  /// Extract error message from exception
  static String extractErrorMessage(Object error) {
    if (error is String) {
      return error;
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unexpected error occurred';
    }
  }

  /// Check if error is a database error
  static bool isDatabaseError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('database') ||
           errorString.contains('sql') ||
           errorString.contains('sqflite');
  }

  /// Check if error is a network error
  static bool isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('internet') ||
           errorString.contains('connection') ||
           errorString.contains('socket');
  }

  /// Check if error is a file system error
  static bool isFileSystemError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('file') ||
           errorString.contains('storage') ||
           errorString.contains('permission') ||
           errorString.contains('access');
  }

  /// Check if error is a validation error
  static bool isValidationError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('validation') ||
           errorString.contains('invalid') ||
           errorString.contains('empty') ||
           errorString.contains('required') ||
           errorString.contains('format');
  }

  /// Handle database operation with error logging
  static Future<T> handleDatabaseOperation<T>(
    Future<T> operation, {
    String operationName = 'Database operation',
    String? tag,
  }) async {
    try {
      return await operation;
    } catch (error, stackTrace) {
      logError(
        '$operationName failed',
        error: error,
        stackTrace: stackTrace,
        tag: tag ?? 'Database',
      );
      rethrow;
    }
  }

  /// Handle file operation with error logging
  static Future<T> handleFileOperation<T>(
    Future<T> operation, {
    String operationName = 'File operation',
    String? tag,
  }) async {
    try {
      return await operation;
    } catch (error, stackTrace) {
      logError(
        '$operationName failed',
        error: error,
        stackTrace: stackTrace,
        tag: tag ?? 'File',
      );
      rethrow;
    }
  }

  /// Handle network operation with error logging
  static Future<T> handleNetworkOperation<T>(
    Future<T> operation, {
    String operationName = 'Network operation',
    String? tag,
  }) async {
    try {
      return await operation;
    } catch (error, stackTrace) {
      logError(
        '$operationName failed',
        error: error,
        stackTrace: stackTrace,
        tag: tag ?? 'Network',
      );
      rethrow;
    }
  }

  /// Handle notification operation with error logging
  static Future<T> handleNotificationOperation<T>(
    Future<T> operation, {
    String operationName = 'Notification operation',
    String? tag,
  }) async {
    try {
      return await operation;
    } catch (error, stackTrace) {
      logError(
        '$operationName failed',
        error: error,
        stackTrace: stackTrace,
        tag: tag ?? 'Notification',
      );
      rethrow;
    }
  }
}