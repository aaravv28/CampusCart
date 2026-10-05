import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_cart/core/services/offline_cache_service.dart';
import 'package:campus_cart/features/listings/services/listings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListingsService Offline & Filter Tests', () {
    late ListingsService listingsService;

    final sampleListings = [
      {
        'id': 'l1',
        'title': 'Organic Chemistry 8th Edition',
        'price': 45.0,
        'course_code': 'CHEM210',
        'category': 'Books',
        'condition': 'Good',
        'seller_id': 'u1',
        'college_id': 'col_1',
      },
      {
        'id': 'l2',
        'title': 'TI-84 Plus CE Graphing Calculator',
        'price': 75.0,
        'course_code': 'MATH150',
        'category': 'Electronics',
        'condition': 'Like New',
        'seller_id': 'u2',
        'college_id': 'col_1',
      },
      {
        'id': 'l3',
        'title': 'Dorm Mini Desk Fan',
        'price': 15.0,
        'course_code': 'GEN100',
        'category': 'Dorm',
        'condition': 'New',
        'seller_id': 'u3',
        'college_id': 'col_1',
      },
    ];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OfflineCacheService.instance.init();
      await OfflineCacheService.instance.cacheListings(sampleListings);
      listingsService = ListingsService();
    });

    test('getListings retrieves cached items when offline', () async {
      final items = await listingsService.getListings();
      expect(items, isNotEmpty);
      expect(items.length, equals(3));
    });

    test('searchListings finds items matching title or course code', () async {
      final organicResults = await listingsService.searchListings('organic');
      expect(organicResults, isNotEmpty);
      expect(organicResults.first['title'], contains('Organic Chemistry'));

      final courseResults = await listingsService.searchListings('MATH150');
      expect(courseResults, isNotEmpty);
      expect(courseResults.first['course_code'], equals('MATH150'));

      final noResults = await listingsService.searchListings(
        'XYZNonExistentCourse999',
      );
      expect(noResults, isEmpty);
    });

    test('filterListings applies category, condition, price, and sorting', () async {
      // 1. Category filter
      final electronics = await listingsService.filterListings(
        category: 'Electronics',
      );
      expect(electronics, isNotEmpty);
      expect(
        electronics.every((e) => e['category'] == 'Electronics'),
        isTrue,
      );

      // 2. Condition filter
      final newItems = await listingsService.filterListings(condition: 'New');
      expect(newItems, isNotEmpty);
      expect(newItems.every((n) => n['condition'] == 'New'), isTrue);

      // 3. Max price filter
      final cheapItems = await listingsService.filterListings(maxPrice: 30);
      expect(cheapItems, isNotEmpty);
      expect(cheapItems.every((c) => (c['price'] as num) <= 30), isTrue);
    });

    test('createListing queues item into offline drafts queue when disconnected', () async {
      OfflineCacheService.instance.isOnline = false;

      await listingsService.createListing(
        title: 'Physics Lab Notebook with Graph Paper',
        price: 15.0,
        courseCode: 'PHYS102',
        category: 'Books',
        condition: 'New',
      );

      final drafts = await OfflineCacheService.instance.getOfflineDrafts();
      expect(drafts, isNotEmpty);
      expect(drafts.first['title'], equals('Physics Lab Notebook with Graph Paper'));
      expect(drafts.first['price'], equals(15.0));
      expect(drafts.first['course_code'], equals('PHYS102'));
    });
  });
}
