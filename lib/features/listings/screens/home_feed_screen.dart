import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData({String query = ''}) {
    setState(() {
      _listingsFuture = query.isEmpty
          ? _listingsService.getListings()
          : _listingsService.searchListings(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "CampusCart 🛒",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F52BA)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              _fetchData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _fetchData(query: value),
              decoration: InputDecoration(
                hintText: "Search title or course (e.g. CHEM210)...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0F52BA)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _fetchData();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Dynamic Grid Results
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _fetchData(query: _searchController.text),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _listingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Search failed: ${snapshot.error}"));
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        alignment: Alignment.center,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text("No items match your search", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.builder(
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
                          title: item['title'] ?? 'No Title',
                          price: item['price']?.toString() ?? '0',
                          courseCode: item['course_code'] ?? 'GENERAL',
                          condition: item['condition'] ?? 'Good',
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
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}