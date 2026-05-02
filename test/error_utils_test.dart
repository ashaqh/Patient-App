import 'package:flutter_test/flutter_test.dart';
import 'package:carevault/core/utils/error_utils.dart';

void main() {
  group('ErrorUtils', () {
    test('getUserFriendlyErrorMessage returns appropriate messages', () {
      // Database errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Database error'),
        'Sorry, there was a problem with your data. Please try again.',
      );
      
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('SQL error'),
        'Sorry, there was a problem with your data. Please try again.',
      );
      
      // Network errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Network error'),
        'Please check your internet connection and try again.',
      );
      
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('No internet connection'),
        'Please check your internet connection and try again.',
      );
      
      // File errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('File not found'),
        'Unable to access the file. Please check permissions and try again.',
      );
      
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Storage error'),
        'Unable to access the file. Please check permissions and try again.',
      );
      
      // Permission errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Permission denied'),
        'App needs permission to perform this action. Please check app settings.',
      );
      
      // Notification errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Notification error'),
        'Unable to set reminder. Please check notification permissions.',
      );
      
      // Timeout errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Timeout error'),
        'Action took too long. Please try again.',
      );
      
      // Validation errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Validation error'),
        'Please check your input and try again.',
      );
      
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Invalid input'),
        'Please check your input and try again.',
      );
      
      // Not found errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Not found'),
        'Item not found. It may have been deleted.',
      );
      
      // Duplicate errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Duplicate entry'),
        'This item already exists.',
      );
      
      // Empty/required errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Field is required'),
        'Please fill in all required fields.',
      );
      
      // Format errors
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Invalid format'),
        'Please check your input and try again.',
      );
      
      // Generic error
      expect(
        ErrorUtils.getUserFriendlyErrorMessage('Some random error'),
        'Something went wrong. Please try again.',
      );
    });

    test('extractErrorMessage extracts message from different error types', () {
      expect(ErrorUtils.extractErrorMessage('String error'), 'String error');
      expect(ErrorUtils.extractErrorMessage(Exception('Exception error')), 'Exception: Exception error');
      expect(ErrorUtils.extractErrorMessage(123), 'An unexpected error occurred');
    });

    test('isDatabaseError identifies database errors', () {
      expect(ErrorUtils.isDatabaseError('Database error'), true);
      expect(ErrorUtils.isDatabaseError('SQL error'), true);
      expect(ErrorUtils.isDatabaseError('sqflite error'), true);
      expect(ErrorUtils.isDatabaseError('Network error'), false);
    });

    test('isNetworkError identifies network errors', () {
      expect(ErrorUtils.isNetworkError('Network error'), true);
      expect(ErrorUtils.isNetworkError('Internet connection lost'), true);
      expect(ErrorUtils.isNetworkError('Socket error'), true);
      expect(ErrorUtils.isNetworkError('Database error'), false);
    });

    test('isFileSystemError identifies file system errors', () {
      expect(ErrorUtils.isFileSystemError('File error'), true);
      expect(ErrorUtils.isFileSystemError('Storage error'), true);
      expect(ErrorUtils.isFileSystemError('Permission denied'), true);
      expect(ErrorUtils.isFileSystemError('Access error'), true);
      expect(ErrorUtils.isFileSystemError('Network error'), false);
    });

    test('isValidationError identifies validation errors', () {
      expect(ErrorUtils.isValidationError('Validation error'), true);
      expect(ErrorUtils.isValidationError('Invalid input'), true);
      expect(ErrorUtils.isValidationError('Field is empty'), true);
      expect(ErrorUtils.isValidationError('Required field missing'), true);
      expect(ErrorUtils.isValidationError('Invalid format'), true);
      expect(ErrorUtils.isValidationError('Database error'), false);
    });
  });
}