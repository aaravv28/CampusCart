import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_cart/core/services/offline_cache_service.dart';
import 'package:campus_cart/features/auth/screens/login_screen.dart';
import 'package:campus_cart/navigation/main_navigation_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await OfflineCacheService.instance.init();
  });

  group('CampusCart Widget & Navigation Smoke Tests', () {
    testWidgets('LoginScreen renders real login controls and validates input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      // Verify Login Screen UI elements
      expect(find.text('CampusCart 👋'), findsOneWidget);
      expect(find.text('Campus Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('New to CampusCart? Create an Account'), findsOneWidget);

      // Verify submission validation
      await tester.ensureVisible(find.text('Log In'));
      await tester.tap(find.text('Log In'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your campus email'), findsOneWidget);
    });

    testWidgets('LoginScreen navigates to Forgot Password and toggles registration mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      // 1. Navigate to Forgot Password
      await tester.ensureVisible(find.text('Forgot Password?'));
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
      expect(find.text('Reset Password'), findsOneWidget);

      // Return back to Login
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('CampusCart 👋'), findsOneWidget);

      // 2. Toggle to Sign Up mode
      await tester.ensureVisible(find.text('New to CampusCart? Create an Account'));
      await tester.tap(find.text('New to CampusCart? Create an Account'));
      await tester.pumpAndSettle();
      expect(find.text('Campus Registration 🎓'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // 3. Toggle back to Log In mode
      await tester.ensureVisible(find.text('Already registered? Log In'));
      await tester.tap(find.text('Already registered? Log In'));
      await tester.pumpAndSettle();
      expect(find.text('CampusCart 👋'), findsOneWidget);
    });

    testWidgets('MainNavigationShell renders all tabs and switches destinations', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: MainNavigationShell()),
      );
      await tester.pumpAndSettle();

      // Verify all 6 navigation bar destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('CartAI'), findsOneWidget);
      expect(find.text('Sell'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Switch to Search tab
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Explore & Filter 🔍'), findsOneWidget);

      // Switch to CartAI tab
      await tester.tap(find.text('CartAI'));
      await tester.pumpAndSettle();
      expect(find.text('CartAI Copilot'), findsOneWidget);

      // Switch to Sell tab
      await tester.tap(find.text('Sell'));
      await tester.pumpAndSettle();
      expect(find.text('Sell an Item 🏷️'), findsOneWidget);

      // Switch to Messages tab
      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();
      expect(find.text('Campus Chats 💬'), findsOneWidget);

      // Switch to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('My Profile 👤'), findsOneWidget);
    });
  });
}
