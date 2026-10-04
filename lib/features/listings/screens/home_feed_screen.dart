import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/empty_view.dart';
import '../../../core/widget/error_view.dart';
import '../../../core/widget/offline_banner.dart';
import '../../ai_assistant/screens/ai_shopping_copilot_screen.dart';
import '../../colleges/services/college_service.dart';
import '../services/listings_service.dart';
import '../widgets/item_card.dart';
import 'item_detail_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final ListingsService _listingsService = ListingsService();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _listingsFuture;
  Timer? _debounce;
  String _selectedCategory = "All";

  final List<Map<String, dynamic>> _categories = [
    {"label": "All", "icon": Icons.apps_rounded},
    {"label": "Textbooks", "icon": Icons.menu_book_rounded},
    {"label": "Electronics", "icon": Icons.devices_rounded},
    {"label": "Dorm & Furniture", "icon": Icons.chair_rounded},
    {"label": "Lab Gear", "icon": Icons.biotech_rounded},
  ];

  String _collegeName = "Dharmsinh Desai University";
  final CollegeService _collegeService = CollegeService();

  @override
  void initState() {
    super.initState();
    _loadCollege();
    _fetchData();
  }

  void _loadCollege() async {
    final profile = await _collegeService.getCurrentUserProfile();
    if (profile != null && profile['colleges'] != null && profile['colleges']['name'] != null) {
      if (mounted) {
        setState(() => _collegeName = profile['colleges']['name']);
      }
    }
  }

  void _fetchData({String query = ''}) {
    setState(() {
      if (_selectedCategory == "All") {
        _listingsFuture = query.isEmpty
            ? _listingsService.getListings()
            : _listingsService.searchListings(query);
      } else {
        _listingsFuture = _listingsService.filterListings(
          query: query,
          category: _selectedCategory,
        );
      }
    });
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        _fetchData(query: query);
      }
    });
  }

  void _onCategorySelected(String cat) {
    setState(() {
      _selectedCategory = cat;
    });
    _fetchData(query: _searchController.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final collegeName = _collegeName;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              "CampusCart 🛒",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryIris,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "CAMPUS",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryIris,
                ),
              ),
            ),
          ],
        ),
        actions: [
          const ConnectionStatusChip(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Refresh Feed",
            onPressed: () {
              _searchController.clear();
              _selectedCategory = "All";
              _fetchData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Campus Identity Banner
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryIris.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  collegeName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.greenAccent,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Verified Campus Network • Safe Peer Trades",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 🤖 CartAI Copilot Spark Banner
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AiShoppingCopilotScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: AppTheme.aiContainerDecoration(
                      borderRadius: BorderRadius.circular(16),
                      isGlowing: true,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: AppTheme.aiGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Need textbooks or dorm gear? Ask CartAI Copilot ✨",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              Text(
                                "AI analyzes prices, checks condition & finds semester bundles",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: AppTheme.primaryIris,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search textbooks, calculators, dorm gear...",
                      hintStyle: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryIris,
                        size: 21,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                _fetchData();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryIndigo,
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 4. Quick Category Filter Pills
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final label = cat['label'] as String;
                    final icon = cat['icon'] as IconData;
                    final isSelected = _selectedCategory == label;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        avatar: Icon(
                          icon,
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.primaryIris,
                        ),
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryIris,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 12,
                        ),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primaryIris
                                : AppTheme.borderLight,
                          ),
                        ),
                        onSelected: (_) => _onCategorySelected(label),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),

              // 5. Dynamic Responsive Grid Results
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryIris,
                  onRefresh: () async =>
                      _fetchData(query: _searchController.text),
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _listingsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryIris,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return ErrorView(
                          error: snapshot.error,
                          onRetry: () =>
                              _fetchData(query: _searchController.text),
                        );
                      }

                      final items = snapshot.data ?? [];

                      if (items.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.55,
                            alignment: Alignment.center,
                            child: EmptyView(
                              icon: Icons.search_off_rounded,
                              title: "No Items Found",
                              message: _searchController.text.isEmpty
                                  ? "There are currently no listings in $_selectedCategory on your campus."
                                  : "No items match \"${_searchController.text}\".",
                              actionLabel:
                                  _searchController.text.isNotEmpty ||
                                      _selectedCategory != "All"
                                  ? "Reset Filters"
                                  : null,
                              onAction: () {
                                _searchController.clear();
                                setState(() => _selectedCategory = "All");
                                _fetchData();
                              },
                            ),
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = _calculateCrossAxisCount(
                            constraints.maxWidth,
                          );

                          return GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: items.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ItemCard(
                                id: item['id']?.toString(),
                                title: item['title'] ?? 'No Title',
                                price: item['price']?.toString() ?? '0',
                                courseCode: item['course_code'] ?? 'GENERAL',
                                condition: item['condition'] ?? 'Good',
                                imageUrl: item['image_url'],
                                sellerName: item['seller_name'],
                                status: item['status'],
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ItemDetailScreen(item: item),
                                    ),
                                  );
                                  if (mounted) {
                                    _fetchData(query: _searchController.text);
                                  }
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
);
  }
}
