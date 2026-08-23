import 'package:supabase_flutter/supabase_flutter.dart';

class CollegeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all registered colleges
  Future<List<Map<String, dynamic>>> getColleges() async {
    final response = await _supabase.from('colleges').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  // Register a new college with its official domain
  Future<Map<String, dynamic>> registerCollege({
    required String name,
    required String domain,
  }) async {
    final cleanDomain = domain.trim().toLowerCase().replaceAll('@', '');

    final response = await _supabase
        .from('colleges')
        .insert({
      'name': name.trim(),
      'domain': cleanDomain,
    })
        .select()
        .single();

    return response;
  }

  // Get current user's profile and college ID
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select('*, colleges(*)')
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }
}