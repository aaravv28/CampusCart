import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cart/core/config/app_config.dart';
import 'package:campus_cart/features/ai_assistant/services/ai_shopping_assistant_service.dart';

void main() {
  group('AI Shopping Assistant & Safe Trade Hubs Tests', () {
    late AiShoppingAssistantService aiService;

    setUp(() {
      AppConfig.instance.resetDemoData();
      aiService = AiShoppingAssistantService();
    });

    test('Campus Safe Trade Hubs are configured with security metadata', () {
      final zones = AppConfig.instance.demoSafeTradeZones;
      expect(zones, isNotEmpty);
      expect(zones.length, greaterThanOrEqualTo(4));

      final libraryZone = zones.firstWhere((z) => z['id'] == 'zone_1');
      expect(libraryZone['name'], contains('Library'));
      expect(libraryZone['safety_level'], isNotNull);
    });

    test(
      'AI Assistant resolves course code query (CHEM210) to matching textbook',
      () async {
        final response = await aiService.askAssistant(
          query: 'I need textbooks for CHEM210 course',
          availableListings: AppConfig.instance.demoListings,
        );

        expect(response.message, isNotEmpty);
        expect(response.recommendedListings, isNotEmpty);
        final match = response.recommendedListings.first;
        expect(match['course_code'], equals('CHEM210'));
        expect(match['title'], contains('Organic Chemistry'));
        expect(response.isOfflineEngine, isTrue); // offline demo mode
      },
    );

    test('AI Assistant handles budget query (under \$30)', () async {
      final response = await aiService.askAssistant(
        query: 'Show me items under \$30',
        availableListings: AppConfig.instance.demoListings,
      );

      expect(response.recommendedListings, isNotEmpty);
      for (final item in response.recommendedListings) {
        final price = (item['price'] as num).toDouble();
        expect(price, lessThanOrEqualTo(30.0));
      }
    });

    test(
      'ItemDealAnalysis generates deal score, polite scripts, and checklist',
      () {
        final sampleListing = {
          'id': 'test_list_1',
          'title': 'TI-84 Plus CE Graphing Calculator',
          'price': 75.0,
          'course_code': 'MATH150',
          'category': 'Electronics',
          'condition': 'Good',
          'seller_name': 'David Chen',
        };

        final analysis = aiService.analyzeListingDeal(sampleListing);

        expect(analysis.dealScore, isNotEmpty);
        expect(analysis.savingsPercent, greaterThan(0));
        expect(analysis.estimatedRetail, greaterThan(75.0));
        expect(analysis.negotiationScripts.length, equals(3));
        expect(analysis.negotiationScripts.first, contains('\$'));
        expect(analysis.inspectionChecklist, isNotEmpty);
      },
    );
  });
}
