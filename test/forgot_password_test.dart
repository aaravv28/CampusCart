import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cart/core/config/app_config.dart';
import 'package:campus_cart/core/errors/app_error.dart';
import 'package:campus_cart/features/auth/screens/forgot_password_screen.dart';
import 'package:campus_cart/features/auth/screens/reset_password_screen.dart';
import 'package:campus_cart/features/auth/services/auth_service.dart';

void main() {
  setUp(() {
    AppConfig.instance.resetDemoData();
  });

  group('Forgot Password & Password Reset Tests', () {
    test(
      'AuthService password reset methods execute without error in Demo Mode',
      () async {
        final authService = AuthService();

        // Test sending reset email
        await expectLater(
          authService.sendPasswordResetEmail('alex.johnson@ddu.ac.in'),
          completes,
        );

        // Test updating password
        final updateResponse = await authService.updatePassword(
          'newSecurePassword123',
        );
        expect(updateResponse.user, isNotNull);
        expect(
          AppConfig.instance.currentDemoUser?['password'],
          equals('newSecurePassword123'),
        );

        // Test verifying recovery OTP
        final otpResponse = await authService.verifyRecoveryOtp(
          email: 'alex.johnson@ddu.ac.in',
          token: '123456',
        );
        expect(otpResponse.user, isNotNull);
      },
    );

    test(
      'AuthService throws AppError if updatePassword is called without active session',
      () async {
        final authService = AuthService();
        AppConfig.instance.logoutDemoUser();
        expect(authService.hasActiveSession, isFalse);

        expect(
          () => authService.updatePassword('newPassword123'),
          throwsA(isA<AppError>()),
        );
      },
    );

    testWidgets('ForgotPasswordScreen validates email and sends reset link', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);

      // 1. Submit empty form
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();
      expect(find.text('Campus email required'), findsOneWidget);

      // 2. Submit invalid email
      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'not-an-email');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid campus email address'), findsOneWidget);

      // 3. Submit valid campus email
      await tester.enterText(emailField, 'student@ddu.ac.in');
      await tester.tap(find.text('Send Reset Link'));
      await tester.pumpAndSettle();

      // Verify success UI
      expect(find.text('Resend Reset Link'), findsOneWidget);
      expect(
        find.textContaining('Clicking the link in your student email'),
        findsOneWidget,
      );
      expect(find.text('Set Password'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen validates password matching and length', (
      WidgetTester tester,
    ) async {
      bool resetCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: ResetPasswordScreen(
            onPasswordReset: () {
              resetCalled = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create New Password 🔑'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);

      // 1. Submit empty form
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('New password required'), findsOneWidget);

      // 2. Password too short (< 6 characters)
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), '12345');
      await tester.enterText(textFields.at(1), '12345');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );

      // 3. Passwords mismatch
      await tester.enterText(textFields.at(0), 'secretPass123');
      await tester.enterText(textFields.at(1), 'differentPass456');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);

      // 4. Valid matching passwords
      await tester.enterText(textFields.at(0), 'campusSecure2026!');
      await tester.enterText(textFields.at(1), 'campusSecure2026!');
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();

      // Verify password updated in demo state
      expect(resetCalled, isTrue);
      expect(
        AppConfig.instance.currentDemoUser?['password'],
        equals('campusSecure2026!'),
      );
    });

    testWidgets(
      'ForgotPasswordScreen navigates to ResetPasswordScreen via button',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: ForgotPasswordScreen()),
        );
        await tester.pumpAndSettle();

        final setPasswordButton = find.text(
          'Already clicked link or have code? Set Password',
        );
        expect(setPasswordButton, findsOneWidget);

        await tester.tap(setPasswordButton);
        await tester.pumpAndSettle();

        // Verify we navigated to ResetPasswordScreen
        expect(find.text('Create New Password 🔑'), findsOneWidget);
        expect(find.text('Update Password'), findsOneWidget);
      },
    );

    testWidgets(
      'ResetPasswordScreen requires email and OTP when unauthenticated and updates password',
      (WidgetTester tester) async {
        // Log out demo user so there is no active session
        AppConfig.instance.logoutDemoUser();
        bool resetCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: ResetPasswordScreen(
              initialEmail: 'student@ddu.ac.in',
              onPasswordReset: () {
                resetCalled = true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check unauthenticated fields are present
        expect(find.text('Campus Email'), findsOneWidget);
        expect(find.text('6-Digit Recovery Code'), findsOneWidget);
        expect(find.text('New Password'), findsOneWidget);
        expect(find.text('Confirm New Password'), findsOneWidget);

        // Find the 4 text fields
        final textFields = find.byType(TextFormField);
        expect(textFields, findsNWidgets(4));

        // 1. Leave recovery code empty and submit
        await tester.enterText(textFields.at(2), 'campusSecure2026!');
        await tester.enterText(textFields.at(3), 'campusSecure2026!');
        await tester.ensureVisible(find.text('Update Password'));
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter the 6-digit recovery code from your email'),
          findsOneWidget,
        );

        // 2. Fill in recovery code and submit
        await tester.enterText(textFields.at(1), '123456');
        await tester.ensureVisible(find.text('Update Password'));
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();

        expect(resetCalled, isTrue);
        expect(
          AppConfig.instance.currentDemoUser?['password'],
          equals('campusSecure2026!'),
        );
      },
    );
  });
}
