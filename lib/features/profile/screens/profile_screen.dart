import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/offline_cache_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widget/offline_banner.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../colleges/services/college_service.dart';
import '../../listings/screens/item_detail_screen.dart';
import '../../listings/services/listings_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final CollegeService _collegeService = CollegeService();
  final ListingsService _listingsService = ListingsService();

  String name = "Campus Student";
  String email = "student@ddu.ac.in";
  String collegeName = "Dharmsinh Desai University";
  String department = "Computer Science & Engineering";
  String graduationYear = "2027";
  String contactPreference = "In-App Messaging";

  List<Map<String, dynamic>> _userListings = [];
  List<Map<String, dynamic>> _offlineDrafts = [];
  int _savedCount = 0;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final profile = await _collegeService.getCurrentUserProfile();
      final user = _authService.currentUser;

      if (profile != null) {
        name = profile['full_name'] ?? user?.userMetadata?['full_name'] ?? name;
        email = profile['email'] ?? user?.email ?? email;
        if (profile['colleges'] != null && profile['colleges']['name'] != null) {
          collegeName = profile['colleges']['name'];
        }
      } else if (user != null) {
        email = user.email ?? email;
        name = user.userMetadata?['full_name'] ?? email.split('@').first;
      }

      // Load user's listings and drafts
      final listings = await _listingsService.getUserListings();
      final drafts = await OfflineCacheService.instance.getOfflineDrafts();
      final favorites = await OfflineCacheService.instance.getFavorites();

      if (mounted) {
        setState(() {
          _userListings = listings;
          _offlineDrafts = drafts;
          _savedCount = favorites.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.warning('Error loading user profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncDrafts() async {
    setState(() => _isSyncing = true);
    final count = await _listingsService.syncOfflineDrafts();
    if (!mounted) return;
    setState(() => _isSyncing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? "Successfully synced $count listing(s) to cloud! ☁️"
              : "No pending drafts or already up to date.",
        ),
        backgroundColor: const Color(0xFF059669),
      ),
    );
    await _loadProfile();
  }

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

    final updatedName = result["name"] ?? name;
    setState(() {
      name = updatedName;
      department = result["department"] ?? department;
      graduationYear = result["graduationYear"] ?? graduationYear;
      contactPreference = result["contactPreference"] ?? contactPreference;
    });

    // Update in Supabase and offline cache
    try {
      final user = _authService.currentUser;
      final client = Supabase.instance.client;
      if (user != null) {
        await client.from('profiles').update({'full_name': updatedName}).eq('id', user.id);
      }
      final cached = await OfflineCacheService.instance.getCachedProfile() ?? {};
      cached['full_name'] = updatedName;
      await OfflineCacheService.instance.cacheProfile(cached);
    } catch (e) {
      AppLogger.warning('Failed to update remote profile, cached locally: $e');
    }
  }

  Future<void> _deleteListing(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Listing?"),
        content: const Text("Are you sure you want to remove this item?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _listingsService.deleteListing(id);
      await _loadProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing deleted.")),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out of CampusCart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Log Out"),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile 👤",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          const ConnectionStatusChip(),
          IconButton(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined),
            tooltip: "Edit Profile",
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadProfile,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        children: [
                          // 1. Profile Header Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppTheme.heroGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryIris.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryIris,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        collegeName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 2. Overview Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  "My Listings",
                                  "${_userListings.length}",
                                  Icons.storefront_rounded,
                                  AppTheme.primaryIris,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  "Saved Items",
                                  "$_savedCount",
                                  Icons.bookmark_rounded,
                                  const Color(0xFFD97706),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildStatCard(
                                  "Offline Drafts",
                                  "${_offlineDrafts.length}",
                                  Icons.cloud_upload_outlined,
                                  const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Offline Sync Status Banner
                          if (_offlineDrafts.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFF59E0B)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${_offlineDrafts.length} listing(s) pending sync",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                        const Text(
                                          "These items were saved offline and will publish when connected.",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _isSyncing ? null : _syncDrafts,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD97706),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    child: _isSyncing
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text("Sync Now", style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // 4. My Listings Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "My Listings",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                "${_userListings.length} items",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (_userListings.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "You haven't listed any items yet.",
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _userListings.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = _userListings[index];
                                final isDraft = item['is_offline_draft'] == true;

                                return Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ItemDetailScreen(item: item),
                                        ),
                                      );
                                    },
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryIris.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        color: AppTheme.primaryIris,
                                      ),
                                    ),
                                    title: Text(
                                      item['title'] ?? 'Listing',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          "\$${item['price']}",
                                          style: const TextStyle(
                                            color: AppTheme.primaryIris,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isDraft)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              "Draft",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.brown,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _deleteListing(item['id'].toString()),
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 24),

                          // 5. Account Actions Section
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.edit_outlined,
                                    color: AppTheme.primaryIris,
                                  ),
                                  title: const Text("Edit Profile Details"),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                  ),
                                  onTap: _editProfile,
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                                  title: const Text(
                                    "Log Out",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.red,
                                  ),
                                  onTap: _handleLogout,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
