import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';
import '../../auth/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "CampusCart Student";
  String department = "Computer Engineering";
  String graduationYear = "2027";
  String contactPreference = "In-App Messaging";

  // Open Edit Profile Screen
  Future<void> _editProfile() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          name: name,
          department: department,
          graduationYear: graduationYear,
          contactPreference: contactPreference,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      name = result["name"] ?? name;
      department = result["department"] ?? department;
      graduationYear = result["graduationYear"] ?? graduationYear;
      contactPreference =
          result["contactPreference"] ?? contactPreference;
    });
  }

  // Logout
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit),
            tooltip: "Edit Profile",
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Avatar
            const CircleAvatar(
              radius: 55,
              child: Icon(
                Icons.person,
                size: 60,
              ),
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // Email
            const Text(
              "student@college.edu",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            // Department
            _ProfileItem(
              icon: Icons.school_outlined,
              title: "Department",
              value: department,
            ),

            // Graduation Year
            _ProfileItem(
              icon: Icons.calendar_month_outlined,
              title: "Graduation Year",
              value: graduationYear,
            ),

            // Contact Preference
            _ProfileItem(
              icon: Icons.chat_outlined,
              title: "Contact Preference",
              value: contactPreference,
            ),

            const SizedBox(height: 30),

            // Active Listings
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Active Listings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Card(
              child: ListTile(
                leading: Icon(Icons.menu_book),
                title: Text(
                  "Data Structures Textbook",
                ),
                subtitle: Text(
                  "₹500 • Available",
                ),
                trailing: Icon(
                  Icons.chevron_right,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Past Selling History
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Past Selling History",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.check_circle_outline,
                ),
                title: Text(
                  "Scientific Calculator",
                ),
                subtitle: Text(
                  "Sold • ₹750",
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  "Log Out",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Reusable Profile Information Card
class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}