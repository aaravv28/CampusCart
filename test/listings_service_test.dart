import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cart/core/config/app_config.dart';
import 'package:campus_cart/features/listings/services/listings_service.dart';

void main() {
  group('ListingsService Offline & Filter Tests', () {
    late ListingsService listingsService;

    setUp(() {
      AppConfig.instance.resetDemoData();
      listingsService = ListingsService();
    });

    test('getListings returns campus-isolated items in demo mode', () async {
      final items = await listingsService.getListings();
      expect(items, isNotEmpty);
      expect(items.every((i) => i['college_id'] == 'col_1'), isTrue);
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

    test(
      'filterListings applies category, condition, price, and sorting',
      () async {
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

        // 4. Sorting price low to high
        final sortedLow = await listingsService.filterListings(
          sortBy: 'price_low',
        );
        for (int i = 0; i < sortedLow.length - 1; i++) {
          expect(
            (sortedLow[i]['price'] as num) <=
                (sortedLow[i + 1]['price'] as num),
            isTrue,
          );
        }

        // 5. Sorting price high to low
        final sortedHigh = await listingsService.filterListings(
          sortBy: 'price_high',
        );
        for (int i = 0; i < sortedHigh.length - 1; i++) {
          expect(
            (sortedHigh[i]['price'] as num) >=
                (sortedHigh[i + 1]['price'] as num),
            isTrue,
          );
        }
      },
    );

    test('createListing persists new item into demo listings store', () async {
      final initialItems = await listingsService.getListings();
      final initialCount = initialItems.length;

      await listingsService.createListing(
        title: 'Physics Lab Notebook with Graph Paper',
        price: 15.0,
        courseCode: 'PHYS102',
        category: 'Lab Gear',
        condition: 'New',
      );

      final updatedItems = await listingsService.getListings();
      expect(updatedItems.length, equals(initialCount + 1));
      expect(
        updatedItems.first['title'],
        equals('Physics Lab Notebook with Graph Paper'),
      );
      expect(updatedItems.first['course_code'], equals('PHYS102'));
    });
  });
}
