import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/app_logger.dart';

class CollegeService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Fetch all registered colleges
  Future<List<Map<String, dynamic>>> getColleges() async {
    if (AppConfig.instance.isDemoMode || _supabase == null) {
      return List<Map<String, dynamic>>.from(AppConfig.instance.demoColleges);
    }

    try {
      final response = await _supabase!.from('colleges').select().order('name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch remote colleges, falling back to local list',
        e,
      );
      // Fallback to local offline colleges to ensure UI never breaks
      return List<Map<String, dynamic>>.from(AppConfig.instance.demoColleges);
    }
  }

  // Register a new college with its official domain
  Future<Map<String, dynamic>> registerCollege({
    required String name,
    required String domain,
  }) async {
    final cleanName = name.trim();
    final cleanDomain = domain.trim().toLowerCase().replaceAll('@', '');

    if (cleanName.isEmpty || cleanDomain.isEmpty) {
      throw AppError.validation('College name and domain are required.');
    }

    if (AppConfig.instance.isDemoMode || _supabase == null) {
      final newCollege = {
        'id': 'col_${DateTime.now().millisecondsSinceEpoch}',
        'name': cleanName,
        'domain': cleanDomain,
      };
      AppConfig.instance.addDemoCollege(newCollege);
      return newCollege;
    }

    try {
      final response = await _supabase!
          .from('colleges')
          .insert({'name': cleanName, 'domain': cleanDomain})
          .select()
          .single();

      return response;
    } catch (e) {
      AppLogger.error('CollegeService.registerCollege failed', e);
      throw AppError.fromException(e);
    }
  }

  // Get current user's profile and college ID
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (AppConfig.instance.isDemoMode || _supabase == null) {
      return AppConfig.instance.currentDemoUser;
    }

    try {
      final user = _supabase?.auth.currentUser;
      if (user == null) {
        return AppConfig.instance.currentDemoUser;
      }

      final response = await _supabase!
          .from('profiles')
          .select('*, colleges(*)')
          .eq('id', user.id)
          .maybeSingle();

      return response ?? AppConfig.instance.currentDemoUser;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch remote profile, falling back to local profile',
        e,
      );
      return AppConfig.instance.currentDemoUser;
    }
  }
}
