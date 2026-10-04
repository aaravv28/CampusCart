import 'package:flutter/material.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';
import '../../../core/widget/offline_banner.dart';
import '../../../navigation/main_navigation_shell.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback? onPasswordReset;
  final String? initialEmail;

  const ResetPasswordScreen({
    super.key,
    this.onPasswordReset,
    this.initialEmail,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isCheckingUri = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialEmail ?? _authService.currentUser?.email ?? '',
    );
    _checkInitialUri();
  }

  Future<void> _checkInitialUri() async {
    if (_authService.hasActiveSession) return;

    try {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('code') ||
          uri.queryParameters.containsKey('token_hash') ||
          uri.fragment.contains('access_token')) {
        setState(() => _isCheckingUri = true);
        await _authService.exchangeCodeOrUri(uri);
        if (mounted) {
          setState(() {
            _isCheckingUri = false;
            if (_authService.currentUser?.email != null) {
              _emailController.text = _authService.currentUser!.email!;
            }
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isCheckingUri = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _hasSession => _authService.hasActiveSession;

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      // 1. If not authenticated yet, authenticate with the email & recovery token
      if (!_hasSession) {
        final email = _emailController.text.trim();
        final token = _tokenController.text.trim();

        if (token.isEmpty) {
          throw AppError.validation(
            "Please enter the 6-digit recovery code from your student email.",
          );
        }

        await _authService.verifyRecoveryOtp(
          email: email,
          token: token,
        );
      }

      // 2. Now update the password with the active session
      await _authService.updatePassword(_passwordController.text.trim());

      if (!mounted) return;

      if (widget.onPasswordReset != null) {
        widget.onPasswordReset!();
      } else {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
          (route) => false,
        );
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Password updated successfully! Welcome back to CampusCart 🎓",
          ),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final appError = AppError.fromException(e);
      messenger.showSnackBar(
        SnackBar(
          content: Text(appError.message),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cancelAndReturnToLogin() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userEmail = user?.email ?? _emailController.text;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Set New Password"),
        actions: const [ConnectionStatusChip()],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  // Lock Icon Badge
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.heroGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryIris.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.key_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Create New Password 🔑",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _hasSession
                        ? "Your reset link has been verified! Choose a strong password to secure your account."
                        : "Enter your campus email, the recovery code from your email, and choose your new password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isCheckingUri)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Verifying recovery link...",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                  // Display Verified Account Info if session is active
                  if (_hasSession && userEmail.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            size: 18,
                            color: Color(0xFF059669),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              "$userEmail (Verified via Link)",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF065F46),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else if (!_hasSession) ...[
                    // When no active session, show Email and Recovery Code fields
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF1D4ED8),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Check your student email for the 6-digit recovery code or tap the link in the email.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: "Campus Email",
                      hint: "alex.johnson@ddu.ac.in",
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (!_hasSession) {
                          if (value == null || value.trim().isEmpty) {
                            return "Campus email required";
                          }
                          if (!value.contains('@')) {
                            return "Enter a valid campus email";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    CustomTextField(
                      label: "6-Digit Recovery Code",
                      hint: "123456",
                      controller: _tokenController,
                      prefixIcon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (!_hasSession) {
                          if (value == null || value.trim().isEmpty) {
                            return "Enter the 6-digit recovery code from your email";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                  ],

                  // New Password Field
                  CustomTextField(
                    label: "New Password",
                    hint: "At least 6 characters",
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "New password required";
                      }
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Confirm Password Field
                  CustomTextField(
                    label: "Confirm New Password",
                    hint: "Re-enter new password",
                    controller: _confirmPasswordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_reset_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Confirm your new password";
                      }
                      if (value != _passwordController.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomButton(
                    text: _isLoading ? "Updating Password..." : "Update Password",
                    isLoading: _isLoading,
                    onPressed: _handleResetPassword,
                  ),

                  const Divider(height: 28),

                  // Navigation actions
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text(
                          "Request New Link",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _cancelAndReturnToLogin,
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text(
                          "Back to Log In",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ],
),
);
  }
}
