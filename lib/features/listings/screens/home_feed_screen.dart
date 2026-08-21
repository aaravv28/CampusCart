import 'package:flutter/material.dart';
import '../widgets/item_card.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final List<String> _categories = ["All", "Textbooks", "Electronics", "Dorm & Furniture", "Lab Gear"];
  int _selectedCategoryIndex = 0;

  final List<Map<String, String>> _mockItems = [
    {"title": "Data Structures & Algos", "price": "45", "courseCode": "CS201", "condition": "Like New"},
    {"title": "TI-84 Plus Calculator", "price": "60", "courseCode": "MATH102", "condition": "Good"},
    {"title": "Organic Chemistry 8th Ed", "price": "30", "courseCode": "CHEM210", "condition": "Fair"},
    {"title": "Mini Fridge 3.2 Cu. Ft.", "price": "85", "courseCode": "DORM", "condition": "Good"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Cart 🎓", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {})],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search textbooks, CS101...",
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _selectedCategoryIndex = index),
                    selectedColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                itemCount: _mockItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final item = _mockItems[index];
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