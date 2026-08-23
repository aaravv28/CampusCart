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
  late Future<List<Map<String, dynamic>>> _listingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshListings();
  }

  void _refreshListings() {
    setState(() {
      _listingsFuture = _listingsService.getListings();
    });
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
            onPressed: _refreshListings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshListings(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _listingsFuture,
          builder: (context, snapshot) {
            // 1. Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. Error State
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Error loading items: ${snapshot.error}"),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refreshListings,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            }

            final items = snapshot.data ?? [];

            // 3. Empty State
            if (items.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text("No items listed yet!", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      SizedBox(height: 4),
                      Text("Be the first to post something to sell.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }

            // 4. Data Success State Grid
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
    );
  }
}