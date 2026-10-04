import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cart/core/config/app_config.dart';
import 'package:campus_cart/main.dart';

void main() {
  setUp(() {
    AppConfig.instance.resetDemoData();
  });

  testWidgets('CampusCart Full Navigation & Offline Presentation Smoke Test', (
    WidgetTester tester,
  ) async {
    // 1. Start with logged-out demo state to verify LoginScreen
    AppConfig.instance.logoutDemoUser();

    await tester.pumpWidget(const CampusCartApp());
    await tester.pumpAndSettle();

    // Verify Login Screen UI elements
    expect(find.text('CampusCart 👋'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Quick Demo Login (Offline Ready)'), findsOneWidget);

    // 2. Perform Quick Demo Login
    await tester.tap(find.text('Quick Demo Login (Offline Ready)'));
    await tester.pumpAndSettle();

    // 3. Verify Landing on MainNavigationShell & Home Feed
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('CartAI'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('CampusCart 🛒'), findsOneWidget);
    expect(find.text('DEMO MODE'), findsWidgets);

    // Verify marketplace items render properly
    expect(find.textContaining('Organic Chemistry'), findsOneWidget);

    // 4. Switch to CartAI tab
    await tester.tap(find.byIcon(Icons.auto_awesome_outlined));
    await tester.pumpAndSettle();
    expect(find.text('CartAI Copilot'), findsOneWidget);

    // 5. Switch to Search tab
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Explore & Filter 🔍'), findsOneWidget);
    expect(find.text('Textbooks'), findsOneWidget);
    expect(find.text('Electronics'), findsOneWidget);

    // 5. Switch to Sell tab
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(find.text('Sell an Item 🏷️'), findsOneWidget);
    expect(find.text('Post Listing'), findsOneWidget);

    // 6. Switch to Messages tab
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();

    expect(find.text('Campus Chats 💬'), findsOneWidget);

    // 7. Switch to Profile tab
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(find.text('My Profile 👤'), findsOneWidget);
    expect(find.text('Alex Johnson'), findsOneWidget);
    expect(find.text('Reset Demo Presentation Data'), findsOneWidget);
  });
}
