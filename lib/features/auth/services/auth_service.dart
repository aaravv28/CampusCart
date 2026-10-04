import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/services/offline_cache_service.dart';
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
    try {
      return _supabase?.auth.currentUser;
    } catch (e) {
      AppLogger.warning('Failed to retrieve currentUser from Supabase', e);
      return null;
    }
  }

  Session? get currentSession {
    try {
      return _supabase?.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  bool get hasActiveSession => currentSession != null;

  Stream<AuthState> get authStateChanges {
    final client = _supabase;
    if (client != null) {
      return client.auth.onAuthStateChange;
    }
    return const Stream.empty();
  }

  /// Real Supabase Sign Up: registers auth credentials and creates profile row.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String collegeId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (_supabase == null) {
      throw AppError.network(
        'Backend connection not available. Please check internet connection.',
      );
    }

    try {
      final response = await _supabase!.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'full_name': fullName, 'college_id': collegeId},
      );

      final user = response.user;
      if (user != null) {
        if (user.identities != null && user.identities!.isEmpty) {
          // User already exists in Supabase auth.users table.
          // Try signing in directly with the password they provided on the sign-up form.
          try {
            final signInRes = await signIn(email: cleanEmail, password: password);
            return signInRes;
          } catch (signInErr) {
            final errStr = signInErr.toString().toLowerCase();
            if (errStr.contains('email not confirmed')) {
              try {
                await _supabase!.auth.resend(
                  type: OtpType.signup,
                  email: cleanEmail,
                );
              } catch (_) {}
              throw AppError.authentication(
                'An account with this email exists in Supabase Authentication, but email verification is pending. We just re-sent a confirmation link to $cleanEmail. Please check your inbox/spam, or disable "Confirm email" in Supabase Dashboard.',
              );
            }
            throw AppError.authentication(
              'An account with this campus email already exists in Supabase (under Authentication -> Users). Please switch to "Log In", or use "Forgot Password" to reset your password.',
            );
          }
        }

        // Cache profile locally so the user can immediately use the app
        final profileData = {
          'id': user.id,
          'full_name': fullName.trim(),
          'email': cleanEmail,
          'college_id': collegeId,
        };
        await OfflineCacheService.instance.cacheProfile(profileData);

        // Upsert user profile in public.profiles table
        try {
          await _supabase!.from('profiles').upsert(profileData);
        } catch (profileErr) {
          AppLogger.warning('Profile creation warning on signup: $profileErr');
          final errStr = profileErr.toString();
          // If foreign key constraint on college_id failed, fallback to verified college ID
          if (errStr.contains('23503') || errStr.contains('college_id')) {
            try {
              final fallbackData = Map<String, dynamic>.from(profileData)
                ..['college_id'] = 'a7de0f10-76f6-4c9d-bb04-6ad6ef4e0ed4';
              await _supabase!.from('profiles').upsert(fallbackData);
              await OfflineCacheService.instance.cacheProfile(fallbackData);
            } catch (fallbackErr) {
              AppLogger.warning('Fallback profile creation warning: $fallbackErr');
            }
          }
        }
      }

      OfflineCacheService.instance.isOnline = true;
      return response;
    } catch (e) {
      if (e is AppError) rethrow;
      AppLogger.error('AuthService.signUp failed', e);
      throw AppError.fromException(e);
    }
  }

  /// Real Supabase Sign In with email & password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (_supabase == null) {
      throw AppError.network(
        'Backend connection not available. Internet connection required to log in.',
      );
    }

    try {
      final response = await _supabase!.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );

      if (response.user != null) {
        try {
          // Fetch existing profile to populate local cache
          final profile = await _supabase!
              .from('profiles')
              .select('id, full_name, email, college_id')
              .eq('id', response.user!.id)
              .maybeSingle();

          if (profile != null) {
            await OfflineCacheService.instance.cacheProfile(
              Map<String, dynamic>.from(profile),
            );
          } else {
            // Create default profile if missing
            final domain = cleanEmail.split('@').last;
            final colleges = await _supabase!
                .from('colleges')
                .select('id')
                .eq('domain', domain);
            final cId = colleges.isNotEmpty
                ? colleges.first['id'] as String?
                : null;

            final newProfile = {
              'id': response.user!.id,
              'full_name':
                  response.user!.userMetadata?['full_name'] ??
                  cleanEmail.split('@').first,
              'email': cleanEmail,
              'college_id': ?cId,
            };
            await _supabase!.from('profiles').insert(newProfile);
            await OfflineCacheService.instance.cacheProfile(newProfile);
          }
        } catch (profileErr) {
          AppLogger.warning('Profile sync warning on login: $profileErr');
        }
      }

      OfflineCacheService.instance.isOnline = true;
      return response;
    } catch (e) {
      AppLogger.error('AuthService.signIn failed', e);
      throw AppError.fromException(e);
    }
  }

  /// Sends Supabase password reset email with recovery link.
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (_supabase == null) {
      throw AppError.network(
        'Internet connection required to request a password reset email.',
      );
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
      OfflineCacheService.instance.isOnline = true;
    } catch (e) {
      AppLogger.error('AuthService.sendPasswordResetEmail failed', e);
      throw AppError.fromException(e);
    }
  }

  /// Updates authenticated user password.
  Future<UserResponse> updatePassword(String newPassword) async {
    if (!hasActiveSession) {
      throw AppError.authentication(
        'No active password reset session was found. Please enter your campus email and the 6-digit recovery code from your email to update your password.',
      );
    }

    if (_supabase == null) {
      throw AppError.network(
        'Internet connection required to update password.',
      );
    }

    try {
      final response = await _supabase!.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      AppLogger.info('User password successfully updated');
      OfflineCacheService.instance.isOnline = true;
      return response;
    } catch (e) {
      AppLogger.error('AuthService.updatePassword failed', e);
      throw AppError.fromException(e);
    }
  }

  /// Verifies recovery OTP code or token from reset email.
  Future<AuthResponse> verifyRecoveryOtp({
    String? email,
    String? token,
    String? tokenHash,
  }) async {
    final cleanEmail = email?.trim().toLowerCase();

    if (_supabase == null) {
      throw AppError.network(
        'Internet connection required to verify recovery code.',
      );
    }

    try {
      final response = await _supabase!.auth.verifyOTP(
        email: cleanEmail,
        token: token?.trim(),
        tokenHash: tokenHash?.trim(),
        type: OtpType.recovery,
      );
      OfflineCacheService.instance.isOnline = true;
      return response;
    } catch (e) {
      AppLogger.error('AuthService.verifyRecoveryOtp failed', e);
      throw AppError.fromException(e);
    }
  }

  /// Attempts to exchange a deep link or URI containing auth parameters for an active session.
  Future<AuthSessionUrlResponse?> exchangeCodeOrUri(Uri uri) async {
    if (_supabase == null) {
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

  /// Resends signup confirmation email.
  Future<void> resendConfirmationEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_supabase != null) {
      await _supabase!.auth.resend(
        type: OtpType.signup,
        email: cleanEmail,
      );
    }
  }

  /// Signs out of Supabase and clears cached user profile.
  Future<void> signOut() async {
    await OfflineCacheService.instance.clearCachedProfile();
    try {
      await _supabase?.auth.signOut();
    } catch (e) {
      AppLogger.warning('Supabase signOut error ignored: $e');
    }
  }
}
