import 'package:flutter/material.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widget/offline_banner.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
      AppLogger.warning("Error loading colleges: $e");
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
                hintText: "e.g., Dharmsinh Desai University",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: domainController,
              decoration: const InputDecoration(
                labelText: "Email Domain",
                hintText: "e.g., ddu.ac.in",
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
            onPressed: () => Navigator.pop(dialogCtx),
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp && _selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select your college."),
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

        if (res.session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created successfully! Welcome to CampusCart 🎉"),
              backgroundColor: Color(0xFF059669),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigationShell()),
            (route) => false,
          );
        } else {
          // If Supabase email confirmation is enabled
          setState(() => _isSignUp = false);
          _showConfirmationInfoDialog(_emailController.text.trim());
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
          duration: const Duration(seconds: 4),
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
        actions: const [ConnectionStatusChip()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
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
                                ? "Sign up with your official university credentials"
                                : "The trusted marketplace for college students",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // College Picker (Sign Up Only)
                          if (_isSignUp) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Select Your University",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _showAddCollegeDialog,
                                  icon: const Icon(Icons.add_circle_outline, size: 14),
                                  label: const Text(
                                    "Add College",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
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
                                  hint: const Text("Select your university"),
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
                            const SizedBox(height: 14),

                            // Full Name Field (Sign Up Only)
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: "Full Name",
                                hintText: "Alex Johnson",
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return "Please enter your full name";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Campus Email",
                              hintText: _isSignUp
                                  ? "student@$requiredDomain"
                                  : "student@ddu.ac.in",
                              prefixIcon: const Icon(Icons.alternate_email_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Please enter your campus email";
                              }
                              if (!val.contains('@')) {
                                return "Please enter a valid email address";
                              }
                              if (_isSignUp &&
                                  _selectedCollege != null &&
                                  !val.toLowerCase().endsWith(
                                        _selectedCollege!['domain']
                                            .toString()
                                            .toLowerCase(),
                                      )) {
                                return "Must use official campus domain (@${_selectedCollege!['domain']})";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Password",
                              hintText: "••••••••",
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return "Please enter your password";
                              }
                              if (val.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),

                          // Forgot Password Link (Login Only)
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
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 6,
                                  ),
                                ),
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryIris,
                                  ),
                                ),
                              ),
                            ),
                          ] else
                            const SizedBox(height: 20),

                          // Submit Action Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryIris,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
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
                                    _isSignUp ? "Create Account" : "Log In",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),

                          // Toggle Login / SignUp
                          TextButton(
                            onPressed: () => setState(() => _isSignUp = !_isSignUp),
                            child: Text(
                              _isSignUp
                                  ? "Already registered? Log In"
                                  : "New to CampusCart? Create an Account",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.primaryIris,
                              ),
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
