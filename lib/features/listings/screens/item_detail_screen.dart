import 'package:flutter/material.dart';
import '../../../core/widget/custom_button.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title'] ?? 'Item Details';
    final price = item['price']?.toString() ?? '0';
    final courseCode = item['course_code'] ?? 'N/A';
    final condition = item['condition'] ?? 'N/A';
    final category = item['category'] ?? 'General';
    final imageUrl = item['image_url'];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Container
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              )
                  : const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("\$$price", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F52BA))),
                Chip(
                  label: Text(courseCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  backgroundColor: const Color(0xFF0F52BA),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            const Divider(),
            const SizedBox(height: 12),

            // Metadata Row
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Category: $category", style: const TextStyle(fontSize: 14)),
                const Spacer(),
                const Icon(Icons.verified_outlined, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text("Condition: $condition", style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: "Message Seller 💬",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Messaging feature managed by partner Auth/Chat scope.")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}