import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String department;
  final String graduationYear;
  final String contactPreference;

  const EditProfileScreen({
    super.key,
    required this.name,
    required this.department,
    required this.graduationYear,
    required this.contactPreference,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _graduationYearController;

  late String _contactPreference;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.name);
    _departmentController = TextEditingController(text: widget.department);
    _graduationYearController = TextEditingController(
      text: widget.graduationYear,
    );
    _contactPreference = widget.contactPreference;
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(context, <String, String>{
      "name": _nameController.text.trim(),
      "department": _departmentController.text.trim(),
      "graduationYear": _graduationYearController.text.trim(),
      "contactPreference": _contactPreference,
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _graduationYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1D4ED8),
                          width: 2.5,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 44,
                        backgroundColor: Color(0xFF1D4ED8),
                        child: Icon(
                          Icons.person_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Name required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: "Department / Major",
                        prefixIcon: const Icon(Icons.school_outlined),
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Department required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _graduationYearController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Graduation Year",
                        prefixIcon: const Icon(Icons.calendar_month_outlined),
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Graduation year required";
                        }
                        if (value.trim().length != 4) {
                          return "Enter a valid 4-digit year";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      initialValue: _contactPreference,
                      decoration: InputDecoration(
                        labelText: "Contact Preference",
                        prefixIcon: const Icon(Icons.chat_outlined),
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "In-App Messaging",
                          child: Text("In-App Messaging (Recommended)"),
                        ),
                        DropdownMenuItem(
                          value: "Email",
                          child: Text("Campus Email"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _contactPreference = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saveProfile,
                        icon: const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Save Profile Changes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
