import 'dart:async';
import 'dart:io';

enum AppErrorType {
  network,
  authentication,
  validation,
  database,
  storage,
  notFound,
  timeout,
  permission,
  unknown,
}

/// Centralized application error model representing converted low-level exceptions
/// into user-friendly, safe messages without exposing raw technical stack traces.
class AppError implements Exception {
  final String message;
  final String? technicalDetails;
  final AppErrorType type;
  final dynamic originalError;

  const AppError({
    required this.message,
    required this.type,
    this.technicalDetails,
    this.originalError,
  });

  factory AppError.network([String? details]) {
    return AppError(
      message: 'Unable to connect to campus servers. Please check your internet connection.',
      type: AppErrorType.network,
      technicalDetails: details,
    );
  }

  factory AppError.authentication(String message, [String? details]) {
    return AppError(
      message: message,
      type: AppErrorType.authentication,
      technicalDetails: details,
    );
  }

  factory AppError.validation(String message) {
    return AppError(message: message, type: AppErrorType.validation);
  }

  factory AppError.notFound([String item = 'Item']) {
    return AppError(
      message: '$item was not found or has been removed.',
      type: AppErrorType.notFound,
    );
  }

  factory AppError.database([String? details]) {
    return AppError(
      message: 'Could not complete database operation. Please try again.',
      type: AppErrorType.database,
      technicalDetails: details,
    );
  }

  factory AppError.fromException(dynamic error) {
    if (error is AppError) {
      return error;
    }

    final errorString = error.toString().toLowerCase();

    // Check for Socket/Network errors
    if (error is SocketException ||
        errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection closed') ||
        errorString.contains('clientexception')) {
      return AppError(
        message: 'Network connection error. Please verify your connection or use Demo Mode.',
        type: AppErrorType.network,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    // Check for Timeouts
    if (error is TimeoutException || errorString.contains('timeout')) {
      return AppError(
        message: 'The request took too long to respond. Please try again.',
        type: AppErrorType.timeout,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    // Check for Format / Parsing errors
    if (error is FormatException || errorString.contains('formatexception')) {
      return AppError(
        message: 'Invalid data format encountered. Please verify your input.',
        type: AppErrorType.validation,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    // Check for Supabase Auth errors
    if (errorString.contains('invalid login credentials') ||
        errorString.contains('invalid_grant') ||
        errorString.contains('user not found')) {
      return AppError(
        message: 'Invalid email or password. Please verify your credentials.',
        type: AppErrorType.authentication,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    if (errorString.contains('email not confirmed')) {
      return AppError(
        message: 'Please check your campus inbox to confirm your email before logging in.',
        type: AppErrorType.authentication,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    if (errorString.contains('user already registered') ||
        errorString.contains('already exists')) {
      return AppError(
        message: 'An account with this campus email already exists.',
        type: AppErrorType.authentication,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    if (errorString.contains('over_email_send_rate_limit') ||
        errorString.contains('email rate limit') ||
        errorString.contains('rate limit')) {
      return AppError(
        message: 'Supabase email rate limit reached (free tier allows ~3-4 emails/hour). Please wait a few minutes before trying again.',
        type: AppErrorType.authentication,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    if (errorString.contains('same_password') ||
        errorString.contains('different from the old password')) {
      return AppError(
        message: 'New password must be different from your previous password.',
        type: AppErrorType.validation,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    if (errorString.contains('weak_password') ||
        errorString.contains('should be at least 6 characters')) {
      return AppError(
        message: 'Password is too weak. Please use at least 6 characters.',
        type: AppErrorType.validation,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    if (errorString.contains('recovery_token_expired') ||
        errorString.contains('token has expired') ||
        errorString.contains('invalid or expired link')) {
      return AppError(
        message: 'Your password reset link has expired or has already been used. Please request a new link.',
        type: AppErrorType.authentication,
        technicalDetails: error.toString(),
        originalError: error,
      );
    }

    // Generic fallback
    return AppError(
      message: 'Something went wrong. Please try again.',
      type: AppErrorType.unknown,
      technicalDetails: error.toString(),
      originalError: error,
    );
  }

  @override
  String toString() => message;
}
