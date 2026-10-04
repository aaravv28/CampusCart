import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widget/demo_badge.dart';
import '../../../core/widget/safe_item_image.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../colleges/services/college_service.dart';
import '../../listings/screens/item_detail_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final CollegeService _collegeService = CollegeService();

  String name = "Alex Johnson";
  String email = "alex.johnson@ddu.ac.in";
  String department = "Computer Engineering";
  String graduationYear = "2027";
  String contactPreference = "In-App Messaging";
  String collegeName = "Dharmsinh Desai University";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _collegeService.getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        name = profile['full_name'] ?? name;
        email = profile['email'] ?? email;
        department = profile['department'] ?? department;
        graduationYear = profile['graduation_year'] ?? graduationYear;
        contactPreference = profile['contact_preference'] ?? contactPreference;
        if (profile['colleges'] is Map<String, dynamic>) {
          collegeName = profile['colleges']['name'] ?? collegeName;
        }
      });
    }
  }

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

    if (result == null) return;

    setState(() {
      name = result["name"] ?? name;
      department = result["department"] ?? department;
      graduationYear = result["graduationYear"] ?? graduationYear;
      contactPreference = result["contactPreference"] ?? contactPreference;
    });

    if (AppConfig.instance.isDemoMode) {
      AppConfig.instance.updateDemoProfile(
        name: name,
        department: department,
        graduationYear: graduationYear,
        contactPreference: contactPreference,
      );
    }
  }

  void _resetDemoData() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Reset Demo Data 🔄"),
        content: const Text(
          "This will restore all demo listings, colleges, and messages to their initial presentation state.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              AppConfig.instance.resetDemoData();
              _loadProfile();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Demo data has been restored to factory state! 🎉",
                  ),
                  backgroundColor: Color(0xFF059669),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryIris,
            ),
            child: const Text("Reset", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Log Out?"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        AppConfig.instance.currentDemoUser?['id'] ?? 'demo_user_123';
    final myListings = AppConfig.instance.demoListings
        .where((l) => l['seller_id'] == currentUserId)
        .toList();
    final myActiveCount = myListings.where((l) => l['status'] != 'sold').length;
    final mySoldCount =
        myListings.where((l) => l['status'] == 'sold').length + 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile 👤",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          const DemoBadge(),
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit Profile",
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // 1. Profile Avatar & Name Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryIris,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryIris.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 44,
                          backgroundColor: AppTheme.primaryIris,
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              size: 14,
                              color: AppTheme.primaryIris,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              collegeName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryIris,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. User Marketplace Statistics
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn("$myActiveCount", "Active Listings"),
                      Container(
                        height: 36,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      _buildStatColumn("$mySoldCount", "Items Sold"),
                      Container(
                        height: 36,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      _buildStatColumn(
                        "5.0 ★",
                        "Rating",
                        valueColor: const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. My Active Listings Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "My Campus Listings",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        "${myListings.length} total",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                if (myListings.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 38,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You haven't posted any items yet.",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myListings.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = myListings[index];
                      final isSold = item['status'] == 'sold';

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: SafeItemImage(
                                  imageUrl: item['image_url'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? 'Listing',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "\$${item['price'] ?? 0} • ${item['course_code'] ?? 'GEN'}",
                                    style: TextStyle(
                                      color: isSold
                                          ? Colors.grey
                                          : AppTheme.primaryIris,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSold)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "SOLD",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey,
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ItemDetailScreen(item: item),
                                    ),
                                  );
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // 4. Academic & Contact Details
                _buildInfoCard(Icons.school_outlined, "Department", department),
                _buildInfoCard(
                  Icons.calendar_month_outlined,
                  "Graduation Year",
                  graduationYear,
                ),
                _buildInfoCard(
                  Icons.chat_outlined,
                  "Contact Preference",
                  contactPreference,
                ),

                const SizedBox(height: 12),

                // 5. Verification Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF059669),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Campus Verification: Active",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "Verified official student domain and institutional credentials.",
                              style: TextStyle(
                                color: Color(0xFF047857),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 5.5 Backend / Cloud Mode Switcher
                ValueListenableBuilder<bool>(
                  valueListenable: AppConfig.instance.isDemoModeNotifier,
                  builder: (context, isDemo, _) {
                    return Material(
                      color: isDemo
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFECFDF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDemo
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFA7F3D0),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDemo
                                  ? const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.15)
                                  : const Color(0xFF10B981)
                                        .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isDemo
                                  ? Icons.bolt_rounded
                                  : Icons.cloud_done_rounded,
                              color: isDemo
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF047857),
                            ),
                          ),
                          title: Text(
                            isDemo
                                ? "Offline Demo Mode"
                                : "Live Cloud Mode (Supabase)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDemo
                                  ? const Color(0xFF92400E)
                                  : const Color(0xFF065F46),
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            isDemo
                                ? "Items and chats are stored locally in device memory."
                                : "Items and chats sync to the live Supabase database.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDemo
                                  ? const Color(0xFFB45309)
                                  : const Color(0xFF047857),
                            ),
                          ),
                          value: !isDemo,
                          activeThumbColor: const Color(0xFF059669),
                          onChanged: (useLive) {
                            if (useLive) {
                              AppConfig.instance.isDemoMode = false;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Switched to Live Cloud Mode (Supabase) ☁️",
                                  ),
                                  backgroundColor: Color(0xFF059669),
                                ),
                              );
                            } else {
                              AppConfig.instance.loginDemoUser();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Switched to Offline Demo Mode ⚡",
                                  ),
                                  backgroundColor: Color(0xFFD97706),
                                ),
                              );
                            }
                            _loadProfile();
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 6. Presentation / Demo Settings Section
                Material(
                  color: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.restart_alt_rounded,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      title: const Text(
                        "Reset Demo Presentation Data",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        "Restores initial demo products, chats, and profiles for instant clean re-presentation.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF92400E),
                      ),
                      onTap: _resetDemoData,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 7. Logout Button
                Material(
                  color: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFFEE2E2)),
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    leading: const Icon(
                      Icons.logout_rounded,
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
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String val, String label, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String val) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryIris, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  val,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
