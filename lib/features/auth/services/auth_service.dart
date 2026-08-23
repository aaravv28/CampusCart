import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign Up and create matching profile with college_id
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String collegeId,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    if (response.user != null) {
      // Save profile entry linking user to college
      await _supabase.from('profiles').insert({
        'id': response.user!.id,
        'full_name': fullName,
        'email': email,
        'college_id': collegeId,
      });
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}