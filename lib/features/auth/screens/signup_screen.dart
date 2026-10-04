import 'package:flutter/material.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';
import '../../../core/widget/offline_banner.dart';
import '../../../navigation/main_navigation_shell.dart';
import '../../colleges/services/college_service.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();
  final CollegeService _collegeService = CollegeService();

  List<Map<String, dynamic>> _colleges = [];
  Map<String, dynamic>? _selectedCollege;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  Future<void> _loadColleges() async {
    final list = await _collegeService.getColleges();
    if (mounted) {
      setState(() {
        _colleges = list;
        if (list.isNotEmpty) {
          _selectedCollege = list.first;
        }
      });
    }
  }

  void _showConfirmationInfoDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.mark_email_read_outlined, color: AppTheme.primaryIris, size: 26),
            const SizedBox(width: 10),
            Text("Verify Campus Email", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your account has been created in Supabase Authentication!",
              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              "A confirmation link was dispatched to:\n$email",
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                "💡 Tip: If you don't see the email, check your Spam folder. In Supabase Dashboard, accounts are registered under 'Authentication -> Users'. To enable instant logins without email verification, turn off 'Confirm email' in Supabase Dashboard (Authentication -> Providers -> Email).",
                style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await _authService.resendConfirmationEmail(email);
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                    const SnackBar(content: Text("Confirmation email re-sent! 🚀")),
                  );
                }
              } catch (_) {}
            },
            child: const Text("Resend Link"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryIris,
              foregroundColor: Colors.white,
            ),
            child: const Text("Continue to Log In"),
          ),
        ],
      ),
    );
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your university.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        collegeId: _selectedCollege!['id'],
      );

      if (!mounted) return;

      if (res.session != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Account created successfully! Welcome to CampusCart 🎓",
            ),
            backgroundColor: Color(0xFF059669),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationShell()),
          (route) => false,
        );
      } else {
        _showConfirmationInfoDialog(_emailController.text.trim());
      }
    } catch (e) {
      if (!mounted) return;
      final appError = AppError.fromException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appError.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final domain = _selectedCollege?['domain'] ?? 'ddu.ac.in';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        actions: const [ConnectionStatusChip()],
      ),
      body: SafeArea(
        child: Column(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Create Campus Account",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Sign up using your verified college email to connect with classmates.",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // University dropdown
                          const Text(
                            "University",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                value: _selectedCollege,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                items: _colleges.map((c) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: c,
                                    child: Text(
                                      "${c['name']} (@${c['domain']})",
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedCollege = val);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          CustomTextField(
                            label: "Full Name",
                            hint: "Alex Johnson",
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Name required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: "College Email",
                            hint: "student@$domain",
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Email required";
                              }
                              final email = value.trim().toLowerCase();
                              if (!email.contains("@")) {
                                return "Enter a valid campus email";
                              }
                              if (_selectedCollege != null &&
                                  !email.endsWith(_selectedCollege!['domain'])) {
                                return "Must use campus domain (@${_selectedCollege!['domain']})";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: "Password",
                            hint: "Create a password",
                            controller: _passwordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password required";
                              }
                              if (value.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            label: "Confirm Password",
                            hint: "Confirm password",
                            controller: _confirmPasswordController,
                            isPassword: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Confirm password required";
                              }
                              if (value != _passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          CustomButton(
                            text: "Register",
                            isLoading: _isLoading,
                            onPressed: _handleSignup,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Already have an account? Log In"),
                            ),
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
      ),
    );
  }
}
