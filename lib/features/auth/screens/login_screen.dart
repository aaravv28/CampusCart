import 'package:flutter/material.dart';
import '../../../core/widget/custom_text_field.dart';
import '../../../core/widget/custom_button.dart';
import '../../../navigation/main_navigation_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text("Welcome Back! 👋", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Log in with your college email to continue.", style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 36),
                CustomTextField(
                  label: "College Email",
                  hint: "alex@yourcollege.edu",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Email required";
                    if (!val.endsWith(".edu")) return "Must end in .edu";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: "Password",
                  hint: "••••••••",
                  controller: _passwordController,
                  isPassword: true,
                  validator: (val) => val == null || val.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(text: "Log In", onPressed: _handleLogin),
              ],
            ),
          ),
        ),
      ),
    );
  }
}