import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_logger.dart';

/// Central offline caching service managing local persistence via SharedPreferences.
/// Ensures the application remains fast and fully functional even when offline.
class OfflineCacheService {
  static final OfflineCacheService instance = OfflineCacheService._internal();

  OfflineCacheService._internal();

  // Keys for SharedPreferences
  static const String _keyColleges = 'campus_cart_cached_colleges';
  static const String _keyListings = 'campus_cart_cached_listings';
  static const String _keyProfile = 'campus_cart_cached_profile';
  static const String _keyFavorites = 'campus_cart_saved_favorites';
  static const String _keyOfflineDrafts = 'campus_cart_offline_draft_listings';
  static const String _keyChatRooms = 'campus_cart_cached_chat_rooms';
  static const String _keyMessagesPrefix = 'campus_cart_cached_msgs_';

  // Network connection state
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  bool get isOnline => isOnlineNotifier.value;
  set isOnline(bool value) {
    if (isOnlineNotifier.value != value) {
      isOnlineNotifier.value = value;
      AppLogger.info('Connection status changed: ${value ? "Online ☁️" : "Offline ⚡"}');
    }
  }

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ================= COLLEGES CACHE =================

  Future<List<Map<String, dynamic>>> getCachedColleges() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyColleges);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached colleges: $e');
    }
    return defaultFallbackColleges;
  }

  Future<void> cacheColleges(List<Map<String, dynamic>> colleges) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyColleges, jsonEncode(colleges));
    } catch (e) {
      AppLogger.warning('Failed to cache colleges: $e');
    }
  }

  // Pre-configured official university fallbacks in case of fresh install without internet
  static const List<Map<String, dynamic>> defaultFallbackColleges = [
    {
      'id': 'a7de0f10-76f6-4c9d-bb04-6ad6ef4e0ed4',
      'name': 'Dharmsinh Desai University',
      'domain': 'ddu.ac.in',
    },
    {
      'id': 'b8ef1f20-87a7-4d9e-cc15-7be7fa5f1fe5',
      'name': 'Nirma University',
      'domain': 'nirmauni.ac.in',
    },
    {
      'id': 'c9fa2a30-98b8-4e0f-dd26-8cf8ab6a2af6',
      'name': 'IIT Bombay',
      'domain': 'iitb.ac.in',
    },
  ];

  // ================= LISTINGS CACHE =================

  Future<List<Map<String, dynamic>>> getCachedListings() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyListings);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached listings: $e');
    }
    return [];
  }

  Future<void> cacheListings(List<Map<String, dynamic>> listings) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyListings, jsonEncode(listings));
    } catch (e) {
      AppLogger.warning('Failed to cache listings: $e');
    }
  }

  // ================= USER PROFILE CACHE =================

  Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyProfile);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(jsonStr) as Map);
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached profile: $e');
    }
    return null;
  }

  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyProfile, jsonEncode(profile));
    } catch (e) {
      AppLogger.warning('Failed to cache profile: $e');
    }
  }

  Future<void> clearCachedProfile() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyProfile);
    } catch (e) {
      AppLogger.warning('Failed to clear profile cache: $e');
    }
  }

  // ================= FAVORITES =================

  final Set<String> _cachedFavorites = {};

  Future<void> init() async {
    await getFavorites();
  }

  Future<Set<String>> getFavorites() async {
    try {
      final prefs = await _getPrefs();
      final list = prefs.getStringList(_keyFavorites);
      if (list != null) {
        _cachedFavorites
          ..clear()
          ..addAll(list);
      }
    } catch (e) {
      AppLogger.warning('Failed to load favorites: $e');
    }
    return Set.unmodifiable(_cachedFavorites);
  }

  bool isFavorite(String listingId) {
    return _cachedFavorites.contains(listingId);
  }

  Future<bool> toggleFavorite(String listingId) async {
    try {
      final prefs = await _getPrefs();
      final bool nowFavorite;
      if (_cachedFavorites.contains(listingId)) {
        _cachedFavorites.remove(listingId);
        nowFavorite = false;
      } else {
        _cachedFavorites.add(listingId);
        nowFavorite = true;
      }
      await prefs.setStringList(_keyFavorites, _cachedFavorites.toList());
      return nowFavorite;
    } catch (e) {
      AppLogger.warning('Failed to toggle favorite: $e');
      return false;
    }
  }

  // ================= OFFLINE DRAFT LISTINGS =================

  Future<List<Map<String, dynamic>>> getOfflineDrafts() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyOfflineDrafts);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      AppLogger.warning('Failed to load offline drafts: $e');
    }
    return [];
  }

  Future<void> saveOfflineDraft(Map<String, dynamic> draft) async {
    try {
      final prefs = await _getPrefs();
      final drafts = await getOfflineDrafts();
      // Assign client-side temporary ID if not present
      draft['id'] = draft['id'] ?? 'draft_${DateTime.now().millisecondsSinceEpoch}';
      draft['is_offline_draft'] = true;
      drafts.insert(0, draft);
      await prefs.setString(_keyOfflineDrafts, jsonEncode(drafts));
      AppLogger.info('Listing draft saved to offline storage: ${draft['title']}');
    } catch (e) {
      AppLogger.warning('Failed to save offline draft: $e');
    }
  }

  Future<void> removeOfflineDraft(String draftId) async {
    try {
      final prefs = await _getPrefs();
      final drafts = await getOfflineDrafts();
      drafts.removeWhere((d) => d['id'] == draftId);
      await prefs.setString(_keyOfflineDrafts, jsonEncode(drafts));
    } catch (e) {
      AppLogger.warning('Failed to remove offline draft: $e');
    }
  }

  Future<void> clearOfflineDrafts() async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove(_keyOfflineDrafts);
    } catch (e) {
      AppLogger.warning('Failed to clear offline drafts: $e');
    }
  }

  // ================= CHAT CACHE =================

  Future<List<Map<String, dynamic>>> getCachedChatRooms() async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString(_keyChatRooms);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached chat rooms: $e');
    }
    return [];
  }

  Future<void> cacheChatRooms(List<Map<String, dynamic>> rooms) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_keyChatRooms, jsonEncode(rooms));
    } catch (e) {
      AppLogger.warning('Failed to cache chat rooms: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCachedMessages(String roomId) async {
    try {
      final prefs = await _getPrefs();
      final jsonStr = prefs.getString('$_keyMessagesPrefix$roomId');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr) as List;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      AppLogger.warning('Failed to load cached messages for $roomId: $e');
    }
    return [];
  }

  Future<void> cacheMessages(String roomId, List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString('$_keyMessagesPrefix$roomId', jsonEncode(messages));
    } catch (e) {
      AppLogger.warning('Failed to cache messages for $roomId: $e');
    }
  }

  // ================= SAFE TRADE ZONES =================

  List<Map<String, dynamic>> getSafeTradeZones() {
    return const [
      {
        'id': 'zone_1',
        'name': 'University Library Entrance',
        'description': 'Main ground floor lobby, monitored by 24/7 security desk and CCTV cameras.',
        'safety_level': 'High Security',
        'recommended_hours': '8:00 AM – 9:00 PM',
      },
      {
        'id': 'zone_2',
        'name': 'Student Center Main Desk',
        'description': 'Central hub with high foot traffic, campus security patrol, and bright lighting.',
        'safety_level': 'Recommended',
        'recommended_hours': '9:00 AM – 6:00 PM',
      },
      {
        'id': 'zone_3',
        'name': 'Campus Security Office Post',
        'description': 'Designated safe transaction zone outside the campus police department.',
        'safety_level': 'Maximum Safety',
        'recommended_hours': '24/7 Monitored',
      },
    ];
  }
}
