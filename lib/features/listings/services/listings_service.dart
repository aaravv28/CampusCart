import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_cache_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../colleges/services/college_service.dart';

class ListingsService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final CollegeService _collegeService = CollegeService();

  // Helper: Fetch current user's college_id
  Future<String?> _getUserCollegeId() async {
    try {
      final profile = await _collegeService.getCurrentUserProfile();
      final collegeId = profile?['college_id'];
      if (collegeId != null && collegeId.toString().isNotEmpty) {
        return collegeId.toString();
      }

      // Fallback: query the first college from Supabase or cache
      final client = _supabase;
      if (client != null) {
        final colleges = await client.from('colleges').select('id').limit(1);
        if (colleges.isNotEmpty) {
          return colleges.first['id'] as String;
        }
      }
      final cached = await OfflineCacheService.instance.getCachedColleges();
      if (cached.isNotEmpty) {
        return cached.first['id'] as String;
      }
      return null;
    } catch (e) {
      AppLogger.warning('Failed to fetch user college ID', e);
      return null;
    }
  }

  /// Uploads or encodes item image for listing
  Future<String?> uploadImage(XFile imageFile) async {
    final client = _supabase;
    if (client != null && OfflineCacheService.instance.isOnline) {
      try {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.name.split('.').last.toLowerCase();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'items/$fileName';

        await client.storage.from('listing-images').uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$fileExt'),
            );

        return client.storage.from('listing-images').getPublicUrl(filePath);
      } catch (e) {
        AppLogger.warning('Storage bucket upload failed, using portable data URI: $e');
      }
    }

    // Portable base64 data URI fallback (guarantees images render anywhere, even offline)
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last.toLowerCase();
      final mime = (fileExt == 'png') ? 'image/png' : 'image/jpeg';
      final base64Str = base64Encode(bytes);
      return 'data:$mime;base64,$base64Str';
    } catch (_) {
      return imageFile.path;
    }
  }

  /// Fetches listings for user's campus. Reads from Supabase when online,
  /// updates local cache, and combines offline drafts.
  Future<List<Map<String, dynamic>>> getListings() async {
    final collegeId = await _getUserCollegeId();
    final client = _supabase;

    List<Map<String, dynamic>> remoteListings = [];

    if (client != null) {
      try {
        var query = client.from('listings').select();
        if (collegeId != null && collegeId.isNotEmpty) {
          query = query.eq('college_id', collegeId);
        }
        final response = await query.order('created_at', ascending: false);
        remoteListings = List<Map<String, dynamic>>.from(response);

        // Update local persistent cache
        await OfflineCacheService.instance.cacheListings(remoteListings);
        OfflineCacheService.instance.isOnline = true;
      } catch (e) {
        AppLogger.warning('Failed to fetch remote listings, reading offline cache: $e');
        OfflineCacheService.instance.isOnline = false;
        remoteListings = await OfflineCacheService.instance.getCachedListings();
      }
    } else {
      remoteListings = await OfflineCacheService.instance.getCachedListings();
    }

    // Prepend any offline drafts pending sync
    final drafts = await OfflineCacheService.instance.getOfflineDrafts();
    if (drafts.isNotEmpty) {
      final combined = <Map<String, dynamic>>[...drafts, ...remoteListings];
      return combined;
    }

    return remoteListings;
  }

  /// Searches listings matching search query
  Future<List<Map<String, dynamic>>> searchListings(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    final allListings = await getListings();

    if (cleanQuery.isEmpty) {
      return allListings;
    }

    return allListings.where((l) {
      final title = (l['title'] ?? '').toString().toLowerCase();
      final course = (l['course_code'] ?? '').toString().toLowerCase();
      final category = (l['category'] ?? '').toString().toLowerCase();
      final description = (l['description'] ?? '').toString().toLowerCase();

      return title.contains(cleanQuery) ||
          course.contains(cleanQuery) ||
          category.contains(cleanQuery) ||
          description.contains(cleanQuery);
    }).toList();
  }

  /// Creates a new listing. Saves directly to Supabase cloud when online,
  /// or saves to offline drafts queue if offline.
  Future<void> createListing({
    required String title,
    required double price,
    required String courseCode,
    required String category,
    required String condition,
    String? description,
    String? imageUrl,
  }) async {
    final collegeId = await _getUserCollegeId();
    final client = _supabase;
    final user = client?.auth.currentUser;

    final sellerId = user?.id ?? 'offline_user';

    final listingPayload = <String, dynamic>{
      'title': title.trim(),
      'price': price,
      'category': category,
      'condition': condition,
      'course_code': courseCode.trim().toUpperCase(),
      'image_url': imageUrl,
      'seller_id': sellerId,
      'college_id': collegeId ?? 'a7de0f10-76f6-4c9d-bb04-6ad6ef4e0ed4',
      if (description != null && description.isNotEmpty)
        'description': description.trim(),
      'created_at': DateTime.now().toIso8601String(),
    };

    if (client != null && user != null && OfflineCacheService.instance.isOnline) {
      try {
        final coreData = <String, dynamic>{
          'title': title.trim(),
          'price': price,
          'category': category,
          'condition': condition,
          'course_code': courseCode.trim().toUpperCase(),
          'image_url': imageUrl,
          'seller_id': user.id,
          'college_id': collegeId,
        };

        try {
          await client.from('listings').insert({
            ...coreData,
            if (description != null && description.trim().isNotEmpty)
              'description': description.trim(),
          });
        } catch (insertErr) {
          // If schema doesn't have description column, insert core columns
          await client.from('listings').insert(coreData);
        }

        // Refresh cache
        final updated = await client.from('listings').select().order('created_at', ascending: false);
        await OfflineCacheService.instance.cacheListings(List<Map<String, dynamic>>.from(updated));
        OfflineCacheService.instance.isOnline = true;
        return;
      } catch (e) {
        AppLogger.warning('Cloud insert failed, saving to offline drafts: $e');
        OfflineCacheService.instance.isOnline = false;
      }
    }

    // Save as offline draft
    await OfflineCacheService.instance.saveOfflineDraft(listingPayload);
  }

  /// Synchronizes pending offline drafts to Supabase cloud
  Future<int> syncOfflineDrafts() async {
    final client = _supabase;
    final user = client?.auth.currentUser;

    if (client == null || user == null) return 0;

    final drafts = await OfflineCacheService.instance.getOfflineDrafts();
    if (drafts.isEmpty) return 0;

    int syncedCount = 0;
    final remainingDrafts = <Map<String, dynamic>>[];

    for (final draft in drafts) {
      try {
        final coreData = <String, dynamic>{
          'title': draft['title'],
          'price': draft['price'],
          'category': draft['category'],
          'condition': draft['condition'],
          'course_code': draft['course_code'],
          'image_url': draft['image_url'],
          'seller_id': user.id,
          'college_id': draft['college_id'],
        };
        await client.from('listings').insert(coreData);
        syncedCount++;
      } catch (e) {
        AppLogger.warning('Failed to sync draft ${draft['id']}: $e');
        remainingDrafts.add(draft);
      }
    }

    if (syncedCount > 0) {
      await OfflineCacheService.instance.clearOfflineDrafts();
      for (final rem in remainingDrafts) {
        await OfflineCacheService.instance.saveOfflineDraft(rem);
      }
      // Refresh cache
      final updated = await client.from('listings').select().order('created_at', ascending: false);
      await OfflineCacheService.instance.cacheListings(List<Map<String, dynamic>>.from(updated));
      OfflineCacheService.instance.isOnline = true;
    }

    return syncedCount;
  }

  /// Deletes a listing
  Future<void> deleteListing(String listingId) async {
    if (listingId.startsWith('draft_')) {
      await OfflineCacheService.instance.removeOfflineDraft(listingId);
      return;
    }

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('listings').delete().eq('id', listingId);
        OfflineCacheService.instance.isOnline = true;
      } catch (e) {
        AppLogger.warning('Remote delete failed: $e');
      }
    }

    // Also remove from local cache
    final cached = await OfflineCacheService.instance.getCachedListings();
    cached.removeWhere((l) => l['id'].toString() == listingId);
    await OfflineCacheService.instance.cacheListings(cached);
  }

  /// Marks a listing as sold locally and updates cache
  Future<void> markListingSold(String listingId) async {
    final cached = await OfflineCacheService.instance.getCachedListings();
    for (final l in cached) {
      if (l['id'].toString() == listingId) {
        l['status'] = 'sold';
        break;
      }
    }
    await OfflineCacheService.instance.cacheListings(cached);
  }

  /// Retrieves listings posted by current user
  Future<List<Map<String, dynamic>>> getUserListings() async {
    final client = _supabase;
    final user = client?.auth.currentUser;
    final allListings = await getListings();

    if (user != null) {
      return allListings.where((l) => l['seller_id'] == user.id).toList();
    }
    return allListings.where((l) => l['is_offline_draft'] == true).toList();
  }

  /// Filters listings by multi-parameter criteria
  Future<List<Map<String, dynamic>>> filterListings({
    String? query,
    String? category,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String? courseCode,
    String? sortBy,
  }) async {
    final listings = (query != null && query.trim().isNotEmpty)
        ? await searchListings(query)
        : await getListings();

    return listings.where((l) {
      if (category != null && category.isNotEmpty && category != 'All') {
        if (l['category'] != category) return false;
      }
      if (condition != null && condition.isNotEmpty && condition != 'All') {
        if (l['condition'] != condition) return false;
      }
      final price = (l['price'] as num?)?.toDouble() ?? 0.0;
      if (minPrice != null && price < minPrice) return false;
      if (maxPrice != null && price > maxPrice) return false;

      if (courseCode != null && courseCode.isNotEmpty) {
        final code = (l['course_code'] ?? '').toString().toUpperCase();
        if (!code.contains(courseCode.toUpperCase())) return false;
      }
      return true;
    }).toList();
  }
}
