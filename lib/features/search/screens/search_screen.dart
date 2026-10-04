import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widget/empty_view.dart';
import '../../../core/widget/error_view.dart';
import '../../../core/widget/offline_banner.dart';
import '../../listings/screens/item_detail_screen.dart';
import '../../listings/services/listings_service.dart';
import '../../listings/widgets/item_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ListingsService _listingsService = ListingsService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = "All";
  String _selectedCondition = "All";
  String _selectedCourseCode = "All";
  String _sortBy = "newest";
  double _maxPrice = 150;

  final List<String> _categories = [
    "All",
    "Textbooks",
    "Electronics",
    "Dorm & Furniture",
    "Lab Gear",
  ];
  final List<String> _conditions = ["All", "New", "Like New", "Good", "Fair"];
  final List<String> _courseCodes = [
    "All",
    "CS101",
    "MATH150",
    "CHEM210",
    "ME201",
    "EE204",
  ];

  late Future<List<Map<String, dynamic>>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _resultsFuture = _listingsService.filterListings(
        query: _selectedCourseCode != "All" && _searchController.text.isEmpty
            ? _selectedCourseCode
            : _searchController.text,
        category: _selectedCategory,
        condition: _selectedCondition,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
      );
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = "All";
      _selectedCondition = "All";
      _selectedCourseCode = "All";
      _maxPrice = 150;
      _sortBy = "newest";
    });
    _applyFilters();
  }

  int _calculateCrossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveCustomFilters =
        _selectedCategory != "All" ||
        _selectedCondition != "All" ||
        _selectedCourseCode != "All" ||
        _maxPrice != 150 ||
        _sortBy != "newest";

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          "Explore & Filter 🔍",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 21,
            letterSpacing: -0.4,
          ),
        ),
        actions: const [ConnectionStatusChip()],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
            children: [
              // 1. Keyword Search Input & Filter Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A)
                                  .withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => _applyFilters(),
                          onChanged: (_) => _applyFilters(),
                          decoration: InputDecoration(
                            hintText:
                                "Search title, course code (CS101, ME201)...",
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
                                    icon: const Icon(
                                      Icons.clear_rounded,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applyFilters();
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
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: hasActiveCustomFilters,
                      backgroundColor: AppTheme.primaryIris,
                      smallSize: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasActiveCustomFilters
                              ? AppTheme.primaryIris
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: hasActiveCustomFilters
                                ? AppTheme.primaryIris
                                : AppTheme.borderLight,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: hasActiveCustomFilters
                                ? Colors.white
                                : AppTheme.primaryIris,
                          ),
                          tooltip: "Filter options",
                          onPressed: _showFilterBottomSheet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Category Selection Chips
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryIris,
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primaryIris
                                : AppTheme.borderLight,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                            _applyFilters();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Course code quick pills
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _courseCodes.length,
                  itemBuilder: (context, index) {
                    final code = _courseCodes[index];
                    final isSelected = _selectedCourseCode == code;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionChip(
                        label: Text(
                          code == "All" ? "All Courses" : code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryIris,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? AppTheme.primaryIndigo
                            : AppTheme.primaryLight,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedCourseCode = code;
                          });
                          _applyFilters();
                        },
                      ),
                    );
                  },
                ),
              ),

              // Active Filters indicator row
              if (hasActiveCustomFilters)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Filters: ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_selectedCondition != "All")
                        _buildFilterTag("Condition: $_selectedCondition", () {
                          setState(() => _selectedCondition = "All");
                          _applyFilters();
                        }),
                      if (_selectedCourseCode != "All")
                        _buildFilterTag("Course: $_selectedCourseCode", () {
                          setState(() => _selectedCourseCode = "All");
                          _applyFilters();
                        }),
                      if (_maxPrice != 150)
                        _buildFilterTag("Max: \$${_maxPrice.round()}", () {
                          setState(() => _maxPrice = 150);
                          _applyFilters();
                        }),
                      if (_sortBy != "newest")
                        _buildFilterTag(
                          _sortBy == "price_low" ? "Price ↑" : "Price ↓",
                          () {
                            setState(() => _sortBy = "newest");
                            _applyFilters();
                          },
                        ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _resetFilters,
                        child: const Text(
                          "Reset all",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryIris,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(),

              // 3. Dynamic Filtered Results
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _resultsFuture,
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
                        onRetry: _applyFilters,
                      );
                    }

                    final items = snapshot.data ?? [];

                    if (items.isEmpty) {
                      return Center(
                        child: EmptyView(
                          icon: Icons.filter_alt_off_rounded,
                          title: "No Matching Items",
                          message: "Try relaxing your search terms, category, or price filters.",
                          actionLabel: "Reset Filters",
                          onAction: _resetFilters,
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = _calculateCrossAxisCount(
                          constraints.maxWidth,
                        );

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                              title: item['title'] ?? '',
                              price: item['price']?.toString() ?? '0',
                              courseCode: item['course_code'] ?? '',
                              condition: item['condition'] ?? '',
                              imageUrl: item['image_url'],
                              sellerName: item['seller_name'],
                              status: item['status'],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ItemDetailScreen(item: item),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
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

  Widget _buildFilterTag(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryIris,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 12,
              color: AppTheme.primaryIris,
            ),
          ),
        ],
      ),
    );
  }

  // Filter & Sort Bottom Sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter & Sort",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedCondition = "All";
                              _maxPrice = 150;
                              _sortBy = "newest";
                            });
                          },
                          child: const Text("Reset"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Max Price Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Max Price",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "\$${_maxPrice.round()}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryIris,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxPrice,
                      min: 10,
                      max: 300,
                      divisions: 29,
                      activeColor: AppTheme.primaryIris,
                      onChanged: (val) {
                        setModalState(() => _maxPrice = val);
                        setState(() => _maxPrice = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Condition Filter
                    const Text(
                      "Item Condition",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _conditions.map((c) {
                        final isSel = _selectedCondition == c;
                        return ChoiceChip(
                          label: Text(c),
                          selected: isSel,
                          selectedColor: AppTheme.primaryIris,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Colors.black87,
                            fontWeight: isSel
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (val) {
                            if (val) {
                              setModalState(() => _selectedCondition = c);
                              setState(() => _selectedCondition = c);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Sort Order Dropdown
                    const Text(
                      "Sort By",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _sortBy,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "newest",
                          child: Text("Newest First"),
                        ),
                        DropdownMenuItem(
                          value: "price_low",
                          child: Text("Price: Low to High"),
                        ),
                        DropdownMenuItem(
                          value: "price_high",
                          child: Text("Price: High to Low"),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _sortBy = val);
                          setState(() => _sortBy = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryIris,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                          _applyFilters();
                        },
                        child: const Text(
                          "Apply Filters",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
