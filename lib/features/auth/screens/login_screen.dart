import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../colleges/services/college_service.dart';
import '../services/auth_service.dart';

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

  List<Map<String, dynamic>> _colleges = [];
  Map<String, dynamic>? _selectedCollege;

  @override
  void initState() {
    super.initState();
    _loadColleges();
  }

  Future<void> _loadColleges() async {
    try {
      final colleges = await _collegeService.getColleges();
      setState(() {
        _colleges = colleges;
        if (colleges.isNotEmpty) {
          _selectedCollege = colleges.first;
        }
      });
    } catch (e) {
      print("Error loading colleges: $e");
    }
  }

  void _showAddCollegeDialog() {
    final nameController = TextEditingController();
    final domainController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || domainController.text.isEmpty) return;
              try {
                final newCollege = await _collegeService.registerCollege(
                  name: nameController.text,
                  domain: domainController.text,
                );
                Navigator.pop(context);
                await _loadColleges();
                setState(() => _selectedCollege = newCollege);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("College registered successfully!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Registration failed: $e")),
                );
              }
            },
            child: const Text("Register"),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUp && _selectedCollege == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or register your college.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
          collegeId: _selectedCollege!['id'],
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Account created! Check your campus email for verification.")),
          );
        }
      } else {
        await _authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Auth error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredDomain = _selectedCollege?['domain'] ?? 'ddu.ac.in';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.school_outlined, size: 72, color: Color(0xFF0F52BA)),
                    const SizedBox(height: 12),
                    Text(
                      _isSignUp ? "Campus Registration 🎓" : "Welcome Back 👋",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    if (_isSignUp) ...[
                      // College Selector Dropdown
                      const Text("Select Your College", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<Map<String, dynamic>>(
                              value: _selectedCollege,
                              isExpanded: true,
                              items: _colleges.map((c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c['name'], overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedCollege = val),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_business_outlined, color: Color(0xFF0F52BA)),
                            tooltip: "Register New College",
                            onPressed: _showAddCollegeDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? "Name required" : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: _isSignUp ? "Official Email (@$requiredDomain)" : "Campus Email",
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return "Email required";
                        final email = v.trim().toLowerCase();
                        if (_isSignUp && !email.endsWith('@$requiredDomain')) {
                          return "Email must end with @$requiredDomain";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                      validator: (v) => v == null || v.length < 6 ? "Minimum 6 characters" : null,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F52BA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(_isSignUp ? "Sign Up" : "Log In", style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(_isSignUp ? "Already registered? Log In" : "New to CampusCart? Register Here"),
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