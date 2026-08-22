import 'package:flutter/material.dart';
import '../../listings/widgets/item_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  RangeValues _priceRange = const RangeValues(10, 150);
  String _selectedCondition = "All";

  final List<Map<String, String>> _allSearchResults = [
    {"title": "TI-84 Plus Calculator", "price": "60", "courseCode": "MATH102", "condition": "Good"},
    {"title": "Organic Chemistry 8th Ed", "price": "30", "courseCode": "CHEM210", "condition": "Fair"},
    {"title": "MacBook Air M1 2020", "price": "550", "courseCode": "TECH", "condition": "Like New"},
    {"title": "Desk Lamp & LED Bulb", "price": "15", "courseCode": "DORM", "condition": "New"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search & Filter 🔍", style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by course code, title...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
            ),
          ),

          // Filter Section
          ExpansionTile(
            title: const Text("Filter Results", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            leading: const Icon(Icons.tune),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Price Range: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}", style: const TextStyle(fontWeight: FontWeight.w600)),
                    RangeSlider(
                      values: _priceRange,
                      min: 0,
                      max: 600,
                      divisions: 20,
                      labels: RangeLabels("\$${_priceRange.start.round()}", "\$${_priceRange.end.round()}"),
                      onChanged: (values) => setState(() => _priceRange = values),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text("Condition: ", style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: _selectedCondition,
                          items: ["All", "New", "Like New", "Good", "Fair"]
                              .map((cond) => DropdownMenuItem(value: cond, child: Text(cond)))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCondition = val!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(),

          // Results Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                itemCount: _allSearchResults.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final item = _allSearchResults[index];
                  return ItemCard(
                    title: item["title"]!,
                    price: item["price"]!,
                    courseCode: item["courseCode"]!,
                    condition: item["condition"]!,
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