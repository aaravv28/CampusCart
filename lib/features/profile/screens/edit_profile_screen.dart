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
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState
    extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController
  _departmentController;
  late final TextEditingController
  _graduationYearController;

  late String _contactPreference;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.name);

    _departmentController =
        TextEditingController(
          text: widget.department,
        );

    _graduationYearController =
        TextEditingController(
          text: widget.graduationYear,
        );

    _contactPreference =
        widget.contactPreference;
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      <String, String>{
        "name": _nameController.text.trim(),
        "department":
        _departmentController.text.trim(),
        "graduationYear":
        _graduationYearController.text.trim(),
        "contactPreference":
        _contactPreference,
      },
    );
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
        title: const Text("Edit Profile"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(
                    Icons.person,
                    size: 55,
                  ),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Name required";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller:
                  _departmentController,
                  decoration: const InputDecoration(
                    labelText: "Department",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Department required";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller:
                  _graduationYearController,
                  keyboardType:
                  TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Graduation Year",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Graduation year required";
                    }

                    if (value.trim().length != 4) {
                      return "Enter a valid year";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  initialValue:
                  _contactPreference,
                  decoration: const InputDecoration(
                    labelText:
                    "Contact Preference",
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: "In-App Messaging",
                      child:
                      Text("In-App Messaging"),
                    ),
                    DropdownMenuItem(
                      value: "Email",
                      child: Text("Email"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _contactPreference = value;
                    });
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text(
                      "Save Profile",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}