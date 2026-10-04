import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/app_logger.dart';
import '../../../navigation/main_navigation_shell.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    try {
      final client = Supabase.instance.client;
      _authSubscription = client.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        AppLogger.info('AuthGate received auth event: $event');

        if (event == AuthChangeEvent.passwordRecovery) {
          if (mounted) {
            setState(() {
              _isPasswordRecovery = true;
            });
            // Ensure any pushed screens (e.g. ForgotPasswordScreen) are popped so ResetPasswordScreen is visible
            Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
          }
        } else if (event == AuthChangeEvent.signedIn) {
          if (!_isPasswordRecovery && mounted) {
            setState(() {});
          }
        } else if (event == AuthChangeEvent.signedOut) {
          if (mounted) {
            setState(() {
              _isPasswordRecovery = false;
            });
          }
        }
      });
    } catch (_) {
      // Supabase may not be initialized if in demo mode
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  bool _isSupabaseReady() {
    try {
      final _ = Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppConfig.instance.isDemoModeNotifier,
      builder: (context, isDemo, _) {
        if (isDemo) {
          if (_isPasswordRecovery) {
            return ResetPasswordScreen(
              onPasswordReset: () {
                setState(() => _isPasswordRecovery = false);
              },
            );
          }
          final demoUser = AppConfig.instance.currentDemoUser;
          if (demoUser != null) {
            return const MainNavigationShell();
          }
          return const LoginScreen();
        }

        if (!_isSupabaseReady()) {
          AppLogger.warning(
            'Supabase not available in AuthGate, defaulting to LoginScreen',
          );
          return const LoginScreen();
        }

        if (_isPasswordRecovery) {
          return ResetPasswordScreen(
            onPasswordReset: () {
              setState(() => _isPasswordRecovery = false);
            },
          );
        }

        return StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            // Also check snapshot event for recovery in case of race during stream setup
            if (snapshot.hasData &&
                snapshot.data?.event == AuthChangeEvent.passwordRecovery) {
              return ResetPasswordScreen(
                onPasswordReset: () {
                  setState(() => _isPasswordRecovery = false);
                },
              );
            }

            try {
              final session = Supabase.instance.client.auth.currentSession;
              if (session != null) {
                return const MainNavigationShell();
              }
            } catch (e) {
              AppLogger.warning(
                'Failed to inspect Supabase session in AuthGate: $e',
              );
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}
