import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../../core/utils/app_logger.dart';

class CollegeService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Fetches all registered colleges. Tries Supabase cloud first and updates local cache,
  /// seamlessly falling back to cached colleges if offline.
  Future<List<Map<String, dynamic>>> getColleges() async {
    final client = _supabase;
    if (client != null) {
      try {
        final response = await client.from('colleges').select().order('name');
        final colleges = List<Map<String, dynamic>>.from(response);
        if (colleges.isNotEmpty) {
          await OfflineCacheService.instance.cacheColleges(colleges);
        }
        OfflineCacheService.instance.isOnline = true;
        return colleges;
      } catch (e) {
        AppLogger.warning('Failed to fetch remote colleges, using offline cache: $e');
        OfflineCacheService.instance.isOnline = false;
      }
    }

    return OfflineCacheService.instance.getCachedColleges();
  }

  /// Registers a new college with its official student email domain.
  Future<Map<String, dynamic>> registerCollege({
    required String name,
    required String domain,
  }) async {
    final cleanName = name.trim();
    final cleanDomain = domain.trim().toLowerCase().replaceAll('@', '');

    if (cleanName.isEmpty || cleanDomain.isEmpty) {
      throw AppError.validation('College name and domain are required.');
    }

    final client = _supabase;
    if (client == null) {
      throw AppError.network('Cannot register college without internet connection.');
    }

    try {
      final response = await client
          .from('colleges')
          .insert({'name': cleanName, 'domain': cleanDomain})
          .select()
          .single();

      final newCollege = Map<String, dynamic>.from(response);
      final currentList = await OfflineCacheService.instance.getCachedColleges();
      currentList.add(newCollege);
      await OfflineCacheService.instance.cacheColleges(currentList);

      OfflineCacheService.instance.isOnline = true;
      return newCollege;
    } catch (e) {
      AppLogger.error('CollegeService.registerCollege failed', e);
      throw AppError.fromException(e);
    }
  }

  /// Retrieves the current user's profile with college affiliation.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final client = _supabase;
    final user = client?.auth.currentUser;

    if (client != null && user != null) {
      try {
        final response = await client
            .from('profiles')
            .select('*, colleges(*)')
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          final profileMap = Map<String, dynamic>.from(response);
          await OfflineCacheService.instance.cacheProfile(profileMap);
          OfflineCacheService.instance.isOnline = true;
          return profileMap;
        }
      } catch (e) {
        AppLogger.warning('Failed to fetch remote profile, reading offline cache: $e');
        OfflineCacheService.instance.isOnline = false;
      }
    }

    // Offline or network error fallback
    return OfflineCacheService.instance.getCachedProfile();
  }
}
