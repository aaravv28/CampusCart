import 'package:flutter/material.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';
import '../../../core/widget/demo_badge.dart';
import '../../../navigation/main_navigation_shell.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final VoidCallback? onPasswordReset;

  const ResetPasswordScreen({super.key, this.onPasswordReset});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _tokenController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _showTokenFallback = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      // If user is entering a recovery OTP code manually because link didn't sign in
      if (_showTokenFallback && _tokenController.text.trim().isNotEmpty) {
        final email = _authService.currentUser?.email;
        if (email != null && email.isNotEmpty) {
          await _authService.verifyRecoveryOtp(
            email: email,
            token: _tokenController.text.trim(),
          );
        }
      }

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
    final userEmail = user?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Set New Password"),
        actions: const [DemoBadge()],
      ),
      body: Center(
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
                    "Choose a strong, secure password for your campus marketplace account.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Display Verified Account Info if available
                  if (userEmail != null && userEmail.isNotEmpty)
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
                              userEmail,
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
                  const SizedBox(height: 24),

                  // Optional recovery OTP code input if user has a code
                  if (_showTokenFallback) ...[
                    CustomTextField(
                      label: "6-Digit Recovery Code",
                      hint: "123456",
                      controller: _tokenController,
                      prefixIcon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_showTokenFallback &&
                            (value == null || value.trim().isEmpty)) {
                          return "Enter the 6-digit recovery code from your email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
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
                  const SizedBox(height: 16),

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
                    text: _isLoading
                        ? "Updating Password..."
                        : "Update Password",
                    isLoading: _isLoading,
                    onPressed: _handleResetPassword,
                  ),
                  const SizedBox(height: 12),

                  // Token fallback toggle
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showTokenFallback = !_showTokenFallback;
                      });
                    },
                    icon: Icon(
                      _showTokenFallback
                          ? Icons.check_circle_outline_rounded
                          : Icons.password_rounded,
                      size: 16,
                      color: AppTheme.primaryIris,
                    ),
                    label: Text(
                      _showTokenFallback
                          ? "Hide Recovery Code Field"
                          : "Have a 6-digit reset code from email?",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryIris,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const Divider(height: 24),

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
    );
  }
}
