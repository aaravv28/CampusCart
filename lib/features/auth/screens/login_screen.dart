import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widget/demo_badge.dart';
import '../../../navigation/main_navigation_shell.dart';
import '../../colleges/services/college_service.dart';
import '../services/auth_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: 'alex.johnson@ddu.ac.in',
  );
  final _passwordController = TextEditingController(text: 'demo123');
  final _nameController = TextEditingController();

  final AuthService _authService = AuthService();
  final CollegeService _collegeService = CollegeService();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  List<Map<String, dynamic>> _colleges = [];
  Map<String, dynamic>? _selectedCollege;

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadColleges() async {
    try {
      final colleges = await _collegeService.getColleges();
      if (!mounted) return;
      setState(() {
        _colleges = colleges;
        if (colleges.isNotEmpty) {
          _selectedCollege = colleges.first;
        }
      });
    } catch (e) {
      AppLogger.warning(
        "Error loading colleges, fallback to demo colleges: $e",
      );
      if (!mounted) return;
      setState(() {
        _colleges = List<Map<String, dynamic>>.from(
          AppConfig.instance.demoColleges,
        );
        if (_colleges.isNotEmpty) {
          _selectedCollege = _colleges.first;
        }
      });
    }
  }

  void _showAddCollegeDialog() {
    final nameController = TextEditingController();
    final domainController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Register Your College 🏛️"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "College Name",
                hintText: "e.g., Nirma University",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: domainController,
              decoration: const InputDecoration(
                labelText: "Email Domain",
                hintText: "e.g., nirmauni.ac.in",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final collegeName = nameController.text.trim();
              final collegeDomain = domainController.text.trim();
              if (collegeName.isEmpty || collegeDomain.isEmpty) return;

              try {
                final newCollege = await _collegeService.registerCollege(
                  name: collegeName,
                  domain: collegeDomain,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                await _loadColleges();
                if (!mounted) return;
                setState(() => _selectedCollege = newCollege);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("College registered successfully!"),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                final appError = AppError.fromException(e);
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(appError.message)));
              }
            },
            child: const Text("Register"),
          ),
        ],
      ),
    );
  }

  void _enterDemoMode() {
    AppConfig.instance.loginDemoUser('alex.johnson@ddu.ac.in');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Logged in as Alex Johnson (Offline Demo Mode) 🎓"),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryIris,
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      (route) => false,
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp && _selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select or register your college."),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        final res = await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          collegeId: _selectedCollege!['id'],
        );
        if (!mounted) return;

        if (res.session != null || AppConfig.instance.isDemoMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Account created successfully! Welcome to CampusCart 🎉",
              ),
              backgroundColor: Color(0xFF059669),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationShell()),
            (route) => false,
          );
        } else {
          // Email confirmation is required by Supabase
          setState(() => _isSignUp = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Account created! Please check your campus email to verify, then log in.",
              ),
              backgroundColor: Color(0xFF059669),
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationShell()),
          (route) => false,
        );
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
  Widget build(BuildContext context) {
    final requiredDomain = _selectedCollege?['domain'] ?? 'ddu.ac.in';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 44,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [DemoBadge()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppTheme.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryIris.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 38,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      _isSignUp ? "Campus Registration 🎓" : "CampusCart 👋",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSignUp
                          ? "Join your college's trusted student marketplace"
                          : "Log in with your official university credentials",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isSignUp) ...[
                      // College Selector Dropdown
                      const Text(
                        "Select Your University",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child:
                                DropdownButtonFormField<Map<String, dynamic>>(
                                  initialValue: _selectedCollege,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  items: _colleges.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c['name'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedCollege = val),
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.add_business_rounded,
                                color: AppTheme.primaryIris,
                              ),
                              tooltip: "Register New College",
                              onPressed: _showAddCollegeDialog,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          hintText: "Alex Johnson",
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? "Name required"
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: _isSignUp
                            ? "Official Email (@$requiredDomain)"
                            : "Campus Email",
                        hintText: "alex.johnson@ddu.ac.in",
                        prefixIcon: const Icon(Icons.email_outlined),
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Email required";
                        }
                        final email = v.trim().toLowerCase();
                        if (!email.contains('@')) {
                          return "Enter a valid email address";
                        }
                        if (_isSignUp && !email.endsWith('@$requiredDomain')) {
                          return "Email must end with @$requiredDomain";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password Input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? "Minimum 6 characters"
                          : null,
                    ),

                    // Forgot Password link (when logging in)
                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 8),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryIris,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isSignUp ? "Sign Up" : "Log In",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 6),

                    // Toggle Login / SignUp
                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp
                            ? "Already registered? Log In"
                            : "New to CampusCart? Register Here",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const Divider(height: 20),

                    // Quick Demo Login for presentations / offline testing
                    OutlinedButton.icon(
                      onPressed: _enterDemoMode,
                      icon: const Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppTheme.primaryIris,
                      ),
                      label: const Text(
                        "Quick Demo Login (Offline Ready)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryIris,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(
                          color: AppTheme.primaryIris,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pre-loaded with sample textbooks, calculators, and chats.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
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
