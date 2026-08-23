import 'package:flutter/material.dart';
import '../../listings/services/listings_service.dart';
import '../../listings/widgets/item_card.dart';
import '../../listings/screens/item_detail_screen.dart';

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
  String _sortBy = "newest";
  double _maxPrice = 500;

  final List<String> _categories = ["All", "Textbooks", "Electronics", "Dorm & Furniture", "Lab Gear"];
  final List<String> _conditions = ["All", "New", "Like New", "Good", "Fair"];

  late Future<List<Map<String, dynamic>>> _resultsFuture;

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _resultsFuture = _listingsService.filterListings(
        query: _searchController.text,
        category: _selectedCategory,
        condition: _selectedCondition,
        maxPrice: _maxPrice,
        sortBy: _sortBy,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore & Filter 🔍", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // 1. Keyword Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: "Search title or course...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0F52BA)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () => _showFilterBottomSheet(),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Category Selection Chips
          SizedBox(
            height: 48,
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
                    selectedColor: const Color(0xFF0F52BA),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          const Divider(),

          // 3. Dynamic Filtered Results
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _resultsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error filtering: ${snapshot.error}"));
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child: Text("No products match your criteria.", style: TextStyle(color: Colors.grey)),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ItemCard(
                      title: item['title'] ?? '',
                      price: item['price']?.toString() ?? '0',
                      courseCode: item['course_code'] ?? '',
                      condition: item['condition'] ?? '',
                      imageUrl: item['image_url'],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(item: item),
                          ),
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
    );
  }

  // Filter & Sort Bottom Sheet
  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter & Sort", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Max Price Slider
                  Text("Max Price: \$${_maxPrice.round()}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: _maxPrice,
                    min: 10,
                    max: 100000,
                    divisions: 99,
                    activeColor: const Color(0xFF0F52BA),
                    onChanged: (val) {
                      setModalState(() => _maxPrice = val);
                      setState(() => _maxPrice = val);
                    },
                  ),

                  // Sort Order Dropdown
                  const Text("Sort By", style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    value: _sortBy,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: "newest", child: Text("Newest First")),
                      DropdownMenuItem(value: "price_low", child: Text("Price: Low to High")),
                      DropdownMenuItem(value: "price_high", child: Text("Price: High to Low")),
                    ],
                    onChanged: (val) {
                      setModalState(() => _sortBy = val!);
                      setState(() => _sortBy = val!);
                    },
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F52BA),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: const Text("Apply Filters", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}