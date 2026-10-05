import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_cart/core/config/app_config.dart';
import 'package:campus_cart/core/services/offline_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineCacheService & AppConfig Tests', () {
    late OfflineCacheService cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      cache = OfflineCacheService.instance;
      await cache.init();
    });

    test('AppConfig metadata and campus safe trade zones are valid', () {
      expect(AppConfig.appName, equals('CampusCart'));
      expect(AppConfig.campusSafeTradeZones, isNotEmpty);
      expect(AppConfig.campusSafeTradeZones.first['name'], contains('Library'));
      expect(AppConfig.campusSafeTradeZones.first['safety_level'], isNotNull);
    });

    test('Connection status defaults and toggles properly', () {
      cache.isOnline = true;
      expect(cache.isOnline, isTrue);
      expect(AppConfig.instance.isOnline, isTrue);

      cache.isOnline = false;
      expect(cache.isOnline, isFalse);
      expect(AppConfig.instance.isOnline, isFalse);
    });

    test('Colleges fallback returns official universities when cache empty', () async {
      final colleges = await cache.getCachedColleges();
      expect(colleges, isNotEmpty);
      expect(colleges.first['name'], contains('Dharmsinh Desai University'));
    });

    test('Colleges can be cached and retrieved', () async {
      final customColleges = [
        {'id': 'c1', 'name': 'Tech University', 'domain': 'tech.edu'},
      ];
      await cache.cacheColleges(customColleges);

      final retrieved = await cache.getCachedColleges();
      expect(retrieved.length, equals(1));
      expect(retrieved.first['name'], equals('Tech University'));
    });

    test('Listings can be cached and retrieved', () async {
      final sampleListings = [
        {
          'id': 'list_1',
          'title': 'Calculus 3rd Edition',
          'price': 45.0,
          'course_code': 'MATH101',
          'category': 'Books',
        }
      ];
      await cache.cacheListings(sampleListings);

      final cached = await cache.getCachedListings();
      expect(cached.length, equals(1));
      expect(cached.first['title'], equals('Calculus 3rd Edition'));
    });

    test('Favorites can be toggled and checked synchronously', () async {
      const listingId = 'item_fav_123';
      expect(cache.isFavorite(listingId), isFalse);

      final toggledOn = await cache.toggleFavorite(listingId);
      expect(toggledOn, isTrue);
      expect(cache.isFavorite(listingId), isTrue);

      final toggledOff = await cache.toggleFavorite(listingId);
      expect(toggledOff, isFalse);
      expect(cache.isFavorite(listingId), isFalse);
    });

    test('Offline draft listings queue supports save, retrieval, and removal', () async {
      final draft = {
        'id': 'draft_100',
        'title': 'Dorm Desk Fan',
        'price': 15.0,
        'category': 'Dorm Essentials',
        'condition': 'Like New',
        'course_code': '',
      };

      await cache.saveOfflineDraft(draft);
      final drafts = await cache.getOfflineDrafts();
      expect(drafts.length, equals(1));
      expect(drafts.first['title'], equals('Dorm Desk Fan'));

      await cache.removeOfflineDraft('draft_100');
      final emptyDrafts = await cache.getOfflineDrafts();
      expect(emptyDrafts, isEmpty);
    });

    test('User profile can be cached and cleared on logout', () async {
      final profile = {
        'id': 'user_abc_123',
        'email': 'student@ddu.ac.in',
        'full_name': 'Aarav Patel',
        'college_id': 'c1',
      };

      await cache.cacheProfile(profile);
      final retrieved = await cache.getCachedProfile();
      expect(retrieved?['full_name'], equals('Aarav Patel'));

      await cache.clearCachedProfile();
      final cleared = await cache.getCachedProfile();
      expect(cleared, isNull);
    });
  });
}
