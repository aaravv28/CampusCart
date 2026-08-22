import 'package:flutter/material.dart';

import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  void _sendResetLink() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Password reset instructions sent",
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.lock_reset,
                  size: 70,
                ),

                const SizedBox(height: 24),

                const Text(
                  "Reset Password",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Enter your college email and we'll send you password reset instructions.",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 32),

                CustomTextField(
                  label: "College Email",
                  hint: "alex@yourcollege.edu",
                  controller: _emailController,
                  keyboardType:
                  TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Email required";
                    }

                    final email =
                    value.trim().toLowerCase();

                    if (!email.contains("@")) {
                      return "Enter a valid email";
                    }

                    if (!email.endsWith(".edu")) {
                      return "Use your college email";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 28),

                CustomButton(
                  text: "Send Reset Link",
                  onPressed: _sendResetLink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}