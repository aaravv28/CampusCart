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

  // Logout and return to Login Screen
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
        title: const Text(
          "My Profile 👤",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit Profile",
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Avatar
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF0F52BA),
              child: Icon(
                Icons.person,
                size: 55,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // User Name
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // College Email
            Text(
              "student@college.edu",
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 24),

            // User Statistics
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 24,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        "1",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Active Listings",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        "1",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Items Sold",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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

            const SizedBox(height: 24),

            // Active Listings Heading
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

            // Active Listing Example
            const Card(
              child: ListTile(
                leading: Icon(
                  Icons.menu_book,
                ),
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

            const SizedBox(height: 24),

            // Selling History Heading
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

            // Sold Item Example
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

            const SizedBox(height: 16),

            // Saved Items
            ListTile(
              leading: const Icon(
                Icons.favorite_border,
              ),
              title: const Text(
                "Saved Items",
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: () {
                // Saved items functionality can be added later
              },
            ),

            // College Verification
            ListTile(
              leading: const Icon(
                Icons.verified_user_outlined,
              ),
              title: const Text(
                "College Verification Status",
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              onTap: () {},
            ),

            const Divider(
              height: 32,
            ),

            // Logout
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                "Log Out",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _logout,
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