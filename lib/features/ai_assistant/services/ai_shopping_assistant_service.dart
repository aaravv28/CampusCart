import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/offline_cache_service.dart';
import '../../../core/utils/app_logger.dart';

/// Structured response model from the AI Shopping Assistant
class AiShoppingResponse {
  final String message;
  final List<Map<String, dynamic>> recommendedListings;
  final List<String> suggestedFollowUps;
  final bool isOfflineEngine;

  const AiShoppingResponse({
    required this.message,
    required this.recommendedListings,
    this.suggestedFollowUps = const [],
    this.isOfflineEngine = false,
  });
}

/// In-Item Deal Analysis Model
class ItemDealAnalysis {
  final String
  dealScore; // e.g. "Steal Deal 🔥", "Great Deal ⚡", "Fair Price 👍"
  final int savingsPercent; // e.g. 45
  final double estimatedRetail;
  final String summary;
  final List<String> negotiationScripts;
  final List<String> inspectionChecklist;

  const ItemDealAnalysis({
    required this.dealScore,
    required this.savingsPercent,
    required this.estimatedRetail,
    required this.summary,
    required this.negotiationScripts,
    required this.inspectionChecklist,
  });
}

/// AI Shopping Assistant Service
/// Features dual-engine intelligence:
/// 1. Google Gemini 2.0 / 1.5 Flash (When online and GEMINI_API_KEY is available)
/// 2. Deterministic Campus Heuristic NLP Engine (100% offline, zero-network fallback)
class AiShoppingAssistantService {
  static final AiShoppingAssistantService _instance =
      AiShoppingAssistantService._internal();
  factory AiShoppingAssistantService() => _instance;
  AiShoppingAssistantService._internal();

  String? get _geminiApiKey {
    try {
      final key = dotenv.env['GEMINI_API_KEY']?.trim();
      return (key != null && key.isNotEmpty) ? key : null;
    } catch (_) {
      return null;
    }
  }

  /// Primary conversational shopping copilot
  Future<AiShoppingResponse> askAssistant({
    required String query,
    List<Map<String, dynamic>>? availableListings,
  }) async {
    final listings = availableListings ??
        await OfflineCacheService.instance.getCachedListings();
    final apiKey = _geminiApiKey;

    // If API key is present and device is online, attempt Gemini API
    if (apiKey != null && OfflineCacheService.instance.isOnline) {
      try {
        final geminiResponse = await _callGeminiApi(
          query: query,
          apiKey: apiKey,
          listings: listings,
        );
        if (geminiResponse != null) {
          return geminiResponse;
        }
      } catch (e) {
        AppLogger.warning(
          'Gemini API request failed or timed out. Falling back to Local Campus AI Engine: $e',
        );
      }
    }

    // High-Resilience Fallback: Campus Heuristic NLP Engine (Offline-Safe)
    return _runLocalCampusAIEngine(query: query, listings: listings);
  }

  /// Real Google Gemini API Call with JSON structured output
  Future<AiShoppingResponse?> _callGeminiApi({
    required String query,
    required String apiKey,
    required List<Map<String, dynamic>> listings,
  }) async {
    final catalogSummary = listings.map((l) {
      return {
        'id': l['id'],
        'title': l['title'],
        'price': l['price'],
        'course_code': l['course_code'],
        'category': l['category'],
        'condition': l['condition'],
        'description': l['description'],
      };
    }).toList();

    final systemInstruction =
        '''
You are CartAI, an ultra-smart, friendly campus marketplace shopping assistant for college students.
Your goal is to recommend the best products from the university catalog matching the student's request, save them money, and give smart buying tips.
Available campus catalog:
${jsonEncode(catalogSummary)}

Respond ONLY with valid JSON with this exact schema:
{
  "message": "Friendly markdown response explaining what was found and why it helps their college course/life",
  "matched_listing_ids": ["list_1", "list_2"],
  "suggested_follow_ups": ["Next question 1", "Next question 2"]
}
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': '$systemInstruction\n\nStudent Query: "$query"'},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.3,
              'responseMimeType': 'application/json',
            },
          }),
        )
        .timeout(const Duration(seconds: 7));

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final rawText =
          jsonBody['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (rawText != null) {
        final parsed = jsonDecode(rawText);
        final message = parsed['message'] as String? ?? '';
        final matchedIds =
            (parsed['matched_listing_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            {};
        final followUps =
            (parsed['suggested_follow_ups'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        final matchedItems = listings
            .where((item) => matchedIds.contains(item['id']))
            .toList();

        return AiShoppingResponse(
          message: message,
          recommendedListings: matchedItems,
          suggestedFollowUps: followUps,
          isOfflineEngine: false,
        );
      }
    }
    return null;
  }

  /// Campus Heuristic NLP Engine
  /// Fast, zero-latency, 100% offline-ready semantic evaluation
  AiShoppingResponse _runLocalCampusAIEngine({
    required String query,
    required List<Map<String, dynamic>> listings,
  }) {
    final lower = query.toLowerCase().trim();

    // 1. Extract course code matches (e.g., CS101, CHEM210, MATH150, ME201, EE204)
    final courseRegex = RegExp(
      r'\b(cs\s*\d+|math\s*\d+|chem\s*\d+|me\s*\d+|ee\s*\d+|phys\s*\d+)\b',
      caseSensitive: false,
    );
    final courseMatch = courseRegex
        .firstMatch(lower)
        ?.group(0)
        ?.replaceAll(' ', '')
        .toUpperCase();

    // 2. Extract budget constraints (e.g., under $50, less than 40, below 100)
    double? maxBudget;
    final budgetRegex = RegExp(r'(?:under|below|less than|\$)\s*(\d+)');
    final budgetMatch = budgetRegex.firstMatch(lower);
    if (budgetMatch != null) {
      maxBudget = double.tryParse(budgetMatch.group(1) ?? '');
    }

    // 3. Keyword / Category scoring
    final scoredListings = <Map<String, dynamic>, int>{};

    for (final item in listings) {
      int score = 0;
      final title = (item['title'] ?? '').toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      final courseCode = (item['course_code'] ?? '').toString().toUpperCase();
      final desc = (item['description'] ?? '').toString().toLowerCase();
      final price = (item['price'] as num?)?.toDouble() ?? 0.0;

      // Course code match is top priority
      if (courseMatch != null && courseCode == courseMatch) {
        score += 50;
      }

      // Budget check
      if (maxBudget != null) {
        if (price <= maxBudget) {
          score += 25;
        } else {
          score -= 40; // penalize items over budget
        }
      }

      // Keyword associations
      if (lower.contains('book') ||
          lower.contains('textbook') ||
          lower.contains('syllabus')) {
        if (category.contains('textbook')) score += 20;
      }
      if (lower.contains('calc') ||
          lower.contains('calculator') ||
          lower.contains('math')) {
        if (title.contains('calculator') || courseCode.contains('MATH')) {
          score += 35;
        }
      }
      if (lower.contains('screen') ||
          lower.contains('monitor') ||
          lower.contains('display')) {
        if (title.contains('monitor')) score += 35;
      }
      if (lower.contains('dorm') ||
          lower.contains('lamp') ||
          lower.contains('room')) {
        if (category.contains('dorm') || title.contains('lamp')) score += 30;
      }
      if (lower.contains('lab') ||
          lower.contains('coat') ||
          lower.contains('goggle') ||
          lower.contains('chemistry')) {
        if (category.contains('lab') ||
            title.contains('coat') ||
            courseCode.contains('CHEM')) {
          score += 30;
        }
      }
      if (lower.contains('cs') ||
          lower.contains('coding') ||
          lower.contains('algorithm') ||
          lower.contains('computer')) {
        if (courseCode.startsWith('CS') || title.contains('algorithm')) {
          score += 30;
        }
      }
      if (lower.contains('electronic') ||
          lower.contains('circuit') ||
          lower.contains('multimeter')) {
        if (category.contains('electronics') || title.contains('multimeter')) {
          score += 30;
        }
      }

      // Word intersection
      final queryWords = lower.split(RegExp(r'\s+'));
      for (final w in queryWords) {
        if (w.length > 2) {
          if (title.contains(w)) score += 10;
          if (desc.contains(w)) score += 5;
        }
      }

      if (score > 0) {
        scoredListings[item] = score;
      }
    }

    // Sort by score descending
    final sortedMatches = scoredListings.keys.toList()
      ..sort((a, b) => scoredListings[b]!.compareTo(scoredListings[a]!));

    final topItems = sortedMatches.take(3).toList();

    // Formulate intelligent response
    final StringBuffer responseBuffer = StringBuffer();
    final List<String> followUps = [];

    if (topItems.isNotEmpty) {
      if (courseMatch != null) {
        responseBuffer.writeln(
          '🎯 **Found ${topItems.length} campus item(s) matching course `$courseMatch`!**',
        );
      } else if (maxBudget != null) {
        responseBuffer.writeln(
          '💰 **Here are the best campus deals under \$${maxBudget.toInt()}:**',
        );
      } else {
        responseBuffer.writeln(
          '✨ **I found ${topItems.length} great campus match(es) for your request:**',
        );
      }

      for (final item in topItems) {
        final title = item['title'];
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final condition = item['condition'];
        final seller = item['seller_name'];

        responseBuffer.writeln(
          '\n• **$title** (\$${price.toStringAsFixed(0)})\n  '
          'Condition: *$condition* • Listed by $seller.',
        );
      }

      responseBuffer.writeln(
        '\n💡 *Tip: Tap on any item below to inspect verified condition photos or message the student seller directly.*',
      );

      followUps.add('Are these prices negotiable?');
      followUps.add('Where can we meet safely on campus?');
      followUps.add('Find textbooks for next semester');
    } else {
      responseBuffer.writeln(
        '👋 I couldn\'t find an exact listing matching "$query" right now, but our campus inventory updates daily!',
      );
      responseBuffer.writeln(
        '\nWould you like me to check items in **Textbooks**, **Electronics**, or **Dorm Essentials**?',
      );

      // Provide top general deals as recommendations
      final generalRecommendations = listings.take(2).toList();
      topItems.addAll(generalRecommendations);

      followUps.add('Show textbooks under \$50');
      followUps.add('Calculators for MATH150');
      followUps.add('Dorm essentials under \$30');
    }

    return AiShoppingResponse(
      message: responseBuffer.toString(),
      recommendedListings: topItems,
      suggestedFollowUps: followUps,
      isOfflineEngine: true,
    );
  }

  /// In-Listing Deal & Bargaining Inspector
  ItemDealAnalysis analyzeListingDeal(Map<String, dynamic> item) {
    final title = (item['title'] ?? '').toString();
    final price = (item['price'] as num?)?.toDouble() ?? 40.0;
    final category = (item['category'] ?? 'Textbooks').toString();
    final condition = (item['condition'] ?? 'Good').toString();

    // Baseline retail estimates for college goods
    double retailBenchmark = 80.0;
    if (category == 'Textbooks') {
      retailBenchmark = 95.0;
      if (title.toLowerCase().contains('chemistry') ||
          title.toLowerCase().contains('algorithm')) {
        retailBenchmark = 120.0;
      }
    } else if (category == 'Electronics') {
      retailBenchmark = 140.0;
      if (title.toLowerCase().contains('calculator')) retailBenchmark = 135.0;
      if (title.toLowerCase().contains('monitor')) retailBenchmark = 160.0;
    } else if (category == 'Lab Gear') {
      retailBenchmark = 45.0;
    } else if (category == 'Dorm & Furniture') {
      retailBenchmark = 40.0;
    }

    final savings = ((retailBenchmark - price) / retailBenchmark * 100).round();
    final savingsPercent = savings.clamp(10, 85);

    String dealScore = 'Fair Price 👍';
    if (savingsPercent >= 50) {
      dealScore = 'Steal Deal 🔥';
    } else if (savingsPercent >= 30) {
      dealScore = 'Great Value ⚡';
    }

    final summary =
        'Priced at \$${price.toStringAsFixed(0)} vs estimated campus bookstore/retail of \$${retailBenchmark.toStringAsFixed(0)}. '
        'You save ~$savingsPercent%! Given its "$condition" condition, this is a solid campus bargain.';

    // Generate 3 polite, contextual bargaining messages
    final offerPrice = (price * 0.85).round();
    final negotiationScripts = [
      'Hi! Would you accept \$$offerPrice if I pick it up within 30 minutes at the University Library with exact cash?',
      'Hey there! I am taking this course this semester. Would you consider \$$offerPrice? I can meet you anywhere on campus today.',
      'Hello! Really interested in this item. Is the price slightly negotiable if I come directly to your dorm/campus building?',
    ];

    // Category inspection checklist
    final List<String> checklist;
    if (category == 'Textbooks') {
      checklist = [
        'Check that all problem set and index pages are intact.',
        'Verify textbook edition matches your professor\'s syllabus.',
        'Inspect for excessive highlighter markings or moisture damage.',
      ];
    } else if (category == 'Electronics') {
      checklist = [
        'Turn on device and test display screen for dead pixels/lines.',
        'Inspect charging port and verify battery holds charge.',
        'Ask seller to demonstrate functionality in person before paying.',
      ];
    } else if (category == 'Lab Gear') {
      checklist = [
        'Check fabric for any chemical stains or tears.',
        'Ensure size fits comfortably over regular clothing.',
        'Verify goggles create an airtight seal with clean elastic band.',
      ];
    } else {
      checklist = [
        'Inspect physical condition and stability in person.',
        'Ensure all accompanying cables, bulbs, or accessories are present.',
        'Meet at a verified campus Safe Trade Zone during daytime.',
      ];
    }

    return ItemDealAnalysis(
      dealScore: dealScore,
      savingsPercent: savingsPercent,
      estimatedRetail: retailBenchmark,
      summary: summary,
      negotiationScripts: negotiationScripts,
      inspectionChecklist: checklist,
    );
  }
}
