import 'package:flutter/material.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';
import '../../../core/widget/demo_badge.dart';
import '../../../navigation/main_navigation_shell.dart';
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
  bool _isLoading = false;

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        collegeId: 'col_1',
      );

      if (!mounted) return;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
        actions: const [DemoBadge()],
      ),
      body: SafeArea(
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
                    const SizedBox(height: 28),
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
                      hint: "alex.johnson@ddu.ac.in",
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
                      hint: "Enter password again",
                      controller: _confirmPasswordController,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Confirm your password";
                        }

                        if (value != _passwordController.text) {
                          return "Passwords do not match";
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    CustomButton(
                      text: _isLoading
                          ? "Creating Account..."
                          : "Create Account",
                      onPressed: _isLoading ? () {} : _handleSignup,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?"),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Log In"),
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
    );
  }
}
