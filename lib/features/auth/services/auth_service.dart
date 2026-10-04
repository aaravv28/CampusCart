import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/app_logger.dart';

class AuthService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser {
    if (AppConfig.instance.isDemoMode) {
      final demoUser = AppConfig.instance.currentDemoUser;
      if (demoUser == null) return null;
      return User(
        id: demoUser['id'] as String,
        appMetadata: const {},
        userMetadata: {'full_name': demoUser['full_name']},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    try {
      return _supabase?.auth.currentUser;
    } catch (e) {
      AppLogger.warning('Failed to retrieve currentUser from Supabase', e);
      return null;
    }
  }

  Session? get currentSession {
    if (AppConfig.instance.isDemoMode) {
      if (AppConfig.instance.currentDemoUser != null) {
        return Session(
          accessToken: 'demo_token',
          tokenType: 'bearer',
          user: currentUser!,
        );
      }
      return null;
    }
    try {
      return _supabase?.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  bool get hasActiveSession => currentSession != null;

  Stream<AuthState> get authStateChanges {
    final client = _supabase;
    if (client != null && !AppConfig.instance.isDemoMode) {
      return client.auth.onAuthStateChange;
    }
    // Return empty or dummy stream for demo mode
    return const Stream.empty();
  }

  /// Sign Up and create matching profile with college_id
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String collegeId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final isExplicitDemo =
        cleanEmail == 'demo@example.com' || cleanEmail.startsWith('demo@');

    if (_supabase == null || isExplicitDemo) {
      AppLogger.info('Demo Mode: Simulating user registration for $email');
      AppConfig.instance.loginDemoUser(email);
      AppConfig.instance.updateDemoProfile(name: fullName);
      final user = currentUser!;
      return AuthResponse(user: user);
    }

    try {
      final response = await _supabase!.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'college_id': collegeId},
      );

      final user = response.user;
      if (user != null) {
        // If Supabase has email confirmation enabled and email already exists,
        // it returns a dummy User object with identities = [] to prevent user enumeration.
        if (user.identities != null && user.identities!.isEmpty) {
          throw AppError.authentication(
            'This campus email is already registered. Please switch to Log In or use "Forgot Password".',
          );
        }

        // Upsert user profile (safely ignore errors if table has RLS requiring confirmed session or triggers)
        try {
          await _supabase!.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
            'email': email,
            'college_id': collegeId,
          });
        } catch (profileErr) {
          AppLogger.warning('Profile creation warning on signup: $profileErr');
          final errStr = profileErr.toString();
          if (errStr.contains('23503') || errStr.contains('profiles_id_fkey')) {
            throw AppError.authentication(
              'This campus email is already registered. Please switch to Log In.',
            );
          }
        }
      }

      AppConfig.instance.isDemoMode = false;
      return response;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.error('AuthService.signUp failed', e);
      throw AppError.fromException(e);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final isExplicitDemo =
        cleanEmail == 'demo@example.com' || cleanEmail.startsWith('demo@');

    if (_supabase == null || isExplicitDemo) {
      AppLogger.info(
        'Demo Mode: Signing in with campus demo account ($cleanEmail)',
      );
      AppConfig.instance.loginDemoUser(cleanEmail);
      final user = currentUser!;
      return AuthResponse(user: user);
    }

    try {
      final response = await _supabase!.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppConfig.instance.isDemoMode = false;

      // Ensure profile exists for this authenticated user
      if (response.user != null) {
        try {
          final profile = await _supabase!
              .from('profiles')
              .select('id')
              .eq('id', response.user!.id)
              .maybeSingle();

          if (profile == null) {
            final domain = cleanEmail.split('@').last;
            final colleges = await _supabase!
                .from('colleges')
                .select('id')
                .eq('domain', domain);
            final cId = colleges.isNotEmpty
                ? colleges.first['id'] as String?
                : null;

            await _supabase!.from('profiles').insert({
              'id': response.user!.id,
              'full_name':
                  response.user!.userMetadata?['full_name'] ??
                  cleanEmail.split('@').first,
              'email': cleanEmail,
              'college_id': ?cId,
            });
          }
        } catch (profileErr) {
          AppLogger.warning('Profile sync warning on login: $profileErr');
        }
      }

      return response;
    } catch (e) {
      AppLogger.error('AuthService.signIn failed', e);
      throw AppError.fromException(e);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_supabase == null ||
        cleanEmail == 'demo@example.com' ||
        cleanEmail.startsWith('demo@')) {
      AppLogger.info(
        'Demo Mode: Simulating password reset email for $cleanEmail',
      );
      return;
    }

    try {
      final String? redirectTo = kIsWeb
          ? null
          : 'io.supabase.campuscart://login-callback';

      await _supabase!.auth.resetPasswordForEmail(
        cleanEmail,
        redirectTo: redirectTo,
      );
      AppLogger.info(
        'Password reset email requested for $cleanEmail (redirect: $redirectTo)',
      );
    } catch (e) {
      AppLogger.error('AuthService.sendPasswordResetEmail failed', e);
      throw AppError.fromException(e);
    }
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    if (!hasActiveSession) {
      throw AppError.authentication(
        'No active password reset session was found. Please enter your campus email and the 6-digit recovery code from your email to update your password.',
      );
    }

    if (_supabase == null || AppConfig.instance.isDemoMode) {
      AppLogger.info('Demo Mode: Simulating password update');
      AppConfig.instance.updateDemoUserPassword(newPassword);
      final user = currentUser;
      return UserResponse.fromJson(user?.toJson() ?? {});
    }

    try {
      final response = await _supabase!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      AppLogger.info('User password successfully updated');
      return response;
    } catch (e) {
      AppLogger.error('AuthService.updatePassword failed', e);
      throw AppError.fromException(e);
    }
  }

  Future<AuthResponse> verifyRecoveryOtp({
    String? email,
    String? token,
    String? tokenHash,
  }) async {
    final cleanEmail = email?.trim().toLowerCase();
    if (_supabase == null || AppConfig.instance.isDemoMode) {
      AppLogger.info(
        'Demo Mode: Simulating recovery OTP verification for $cleanEmail',
      );
      if (cleanEmail != null && cleanEmail.isNotEmpty) {
        AppConfig.instance.loginDemoUser(cleanEmail);
      } else {
        AppConfig.instance.loginDemoUser();
      }
      final user = currentUser!;
      return AuthResponse(user: user);
    }

    try {
      final response = await _supabase!.auth.verifyOTP(
        email: cleanEmail,
        token: token?.trim(),
        tokenHash: tokenHash?.trim(),
        type: OtpType.recovery,
      );
      AppConfig.instance.isDemoMode = false;
      return response;
    } catch (e) {
      AppLogger.error('AuthService.verifyRecoveryOtp failed', e);
      throw AppError.fromException(e);
    }
  }

  /// Attempts to exchange a deep link or URI containing auth parameters for an active session.
  Future<AuthSessionUrlResponse?> exchangeCodeOrUri(Uri uri) async {
    if (_supabase == null || AppConfig.instance.isDemoMode) {
      return null;
    }

    try {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        AppLogger.info('Exchanging auth code from URI for session');
        return await _supabase!.auth.exchangeCodeForSession(code);
      }

      final tokenHash = uri.queryParameters['token_hash'];
      if (tokenHash != null && tokenHash.isNotEmpty) {
        AppLogger.info('Verifying token_hash from URI for session');
        final res = await _supabase!.auth.verifyOTP(
          tokenHash: tokenHash,
          type: OtpType.recovery,
        );
        if (res.session != null) {
          return AuthSessionUrlResponse(
            session: res.session!,
            redirectType: 'recovery',
          );
        }
      }

      final uriStr = uri.toString();
      if (uriStr.contains('access_token') || uri.fragment.contains('access_token')) {
        AppLogger.info('Extracting session from URL fragment');
        return await _supabase!.auth.getSessionFromUrl(uri);
      }
    } catch (e) {
      AppLogger.warning('Failed to exchange code or URI for session: $e');
    }
    return null;
  }

  Future<void> signOut() async {
    AppConfig.instance.logoutDemoUser();
    AppConfig.instance.isDemoMode = false;
    try {
      await _supabase?.auth.signOut();
    } catch (e) {
      AppLogger.warning('Supabase signOut error ignored', e);
    }
  }
}
