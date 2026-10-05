import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cart/core/errors/app_error.dart';

void main() {
  group('AppError Centralized Error Handling Tests', () {
    test(
      'SocketException maps to AppErrorType.network with friendly message',
      () {
        final socketError = const SocketException(
          'Failed host lookup: gkjmdrlnirwtemzkpcvw.supabase.co',
        );
        final appError = AppError.fromException(socketError);

        expect(appError.type, AppErrorType.network);
        expect(appError.message, contains('Network connection error'));
        expect(appError.technicalDetails, contains('SocketException'));
      },
    );

    test('TimeoutException maps to AppErrorType.timeout', () {
      final timeoutError = TimeoutException('Connection timed out');
      final appError = AppError.fromException(timeoutError);

      expect(appError.type, AppErrorType.timeout);
      expect(appError.message, contains('took too long'));
    });

    test('FormatException maps to AppErrorType.validation', () {
      final formatError = const FormatException('Invalid number format: abc');
      final appError = AppError.fromException(formatError);

      expect(appError.type, AppErrorType.validation);
      expect(appError.message, contains('Invalid data format'));
    });

    test('Supabase invalid credentials maps to authentication error', () {
      final authError = Exception('Invalid login credentials provided');
      final appError = AppError.fromException(authError);

      expect(appError.type, AppErrorType.authentication);
      expect(appError.message, contains('Invalid email or password'));
    });

    test('Unconfirmed email maps to check inbox message', () {
      final unconfirmedError = Exception('Email not confirmed');
      final appError = AppError.fromException(unconfirmedError);

      expect(appError.type, AppErrorType.authentication);
      expect(appError.message, contains('confirm your email'));
    });

    test(
      'Unknown error returns safe fallback without exposing stack traces',
      () {
        final unexpected = Exception('FATAL internal memory pointer corrupt');
        final appError = AppError.fromException(unexpected);

        expect(appError.type, AppErrorType.unknown);
        expect(
          appError.message,
          equals('Something went wrong. Please try again.'),
        );
        expect(
          appError.technicalDetails,
          contains('FATAL internal memory pointer corrupt'),
        );
      },
    );
  });
}
