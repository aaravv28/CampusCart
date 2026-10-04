import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cart/core/config/app_config.dart';

void main() {
  group('AppConfig & Offline Demo Store Tests', () {
    setUp(() {
      AppConfig.instance.resetDemoData();
    });

    test('Initializes with default demo data and demo mode enabled', () {
      expect(AppConfig.instance.isDemoMode, isTrue);
      expect(AppConfig.instance.currentDemoUser, isNotNull);
      expect(
        AppConfig.instance.currentDemoUser?['email'],
        equals('alex.johnson@ddu.ac.in'),
      );
      expect(AppConfig.instance.demoColleges.length, greaterThanOrEqualTo(5));
      expect(AppConfig.instance.demoListings.length, greaterThanOrEqualTo(8));
      expect(AppConfig.instance.demoChatRooms.length, greaterThanOrEqualTo(2));
    });

    test('addDemoListing adds item to beginning of demo listings', () {
      final initialCount = AppConfig.instance.demoListings.length;
      AppConfig.instance.addDemoListing({
        'id': 'test_list_999',
        'title': 'Test Item Title',
        'price': 99.0,
        'course_code': 'TEST101',
        'category': 'Electronics',
        'condition': 'New',
        'college_id': 'col_1',
      });

      expect(AppConfig.instance.demoListings.length, equals(initialCount + 1));
      expect(
        AppConfig.instance.demoListings.first['title'],
        equals('Test Item Title'),
      );
    });

    test('updateDemoProfile alters current demo user profile', () {
      AppConfig.instance.updateDemoProfile(
        name: 'Jordan Smith',
        department: 'Electrical Engineering',
        graduationYear: '2028',
      );

      final user = AppConfig.instance.currentDemoUser;
      expect(user?['full_name'], equals('Jordan Smith'));
      expect(user?['department'], equals('Electrical Engineering'));
      expect(user?['graduation_year'], equals('2028'));
    });

    test('resetDemoData restores original pre-seeded state', () {
      AppConfig.instance.addDemoListing({
        'id': 'temporary_item',
        'title': 'Temporary',
        'price': 10.0,
      });
      AppConfig.instance.updateDemoProfile(name: 'Changed Name');

      AppConfig.instance.resetDemoData();

      expect(
        AppConfig.instance.currentDemoUser?['full_name'],
        equals('Alex Johnson'),
      );
      expect(
        AppConfig.instance.demoListings.any((l) => l['id'] == 'temporary_item'),
        isFalse,
      );
    });

    test(
      'sendDemoMessage and getDemoMessagesStream receive real-time updates',
      () async {
        final stream = AppConfig.instance.getDemoMessagesStream('room_1');
        final expectation = expectLater(
          stream,
          emitsThrough(
            predicate<List<Map<String, dynamic>>>(
              (msgs) => msgs.any(
                (m) => m['content'] == 'Offline presentation test message',
              ),
            ),
          ),
        );

        AppConfig.instance.sendDemoMessage(
          chatRoomId: 'room_1',
          content: 'Offline presentation test message',
        );

        await expectation;
      },
    );
  });
}
