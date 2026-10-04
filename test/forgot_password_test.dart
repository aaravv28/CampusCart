import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_cart/core/errors/app_error.dart';
import 'package:campus_cart/core/services/offline_cache_service.dart';
import 'package:campus_cart/features/auth/screens/forgot_password_screen.dart';
import 'package:campus_cart/features/auth/screens/reset_password_screen.dart';
import 'package:campus_cart/features/auth/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OfflineCacheService.instance.init();
  });

  group('Forgot Password & Password Reset Tests', () {
    test(
      'AuthService throws AppError if updatePassword is called without active session',
      () async {
        final authService = AuthService();
        expect(authService.hasActiveSession, isFalse);

        expect(
          () => authService.updatePassword('newPassword123'),
          throwsA(isA<AppError>()),
        );
      },
    );

    testWidgets('ForgotPasswordScreen validates email inputs', (
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
    });

    testWidgets('ResetPasswordScreen validates password matching and length', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create New Password 🔑'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);

      // 1. Submit empty form
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Campus email required'), findsOneWidget);

      // 2. Fill email and code
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(textFields.at(0), 'student@ddu.ac.in');
      await tester.enterText(textFields.at(1), '123456');

      // 3. Password too short (< 6 characters)
      await tester.enterText(textFields.at(2), '12345');
      await tester.enterText(textFields.at(3), '12345');
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );

      // 4. Passwords mismatch
      await tester.enterText(textFields.at(2), 'secretPass123');
      await tester.enterText(textFields.at(3), 'differentPass456');
      await tester.ensureVisible(find.text('Update Password'));
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match'), findsOneWidget);
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

        // Verify navigation to ResetPasswordScreen
        expect(find.text('Create New Password 🔑'), findsOneWidget);
        expect(find.text('Update Password'), findsOneWidget);
      },
    );
  });
}
