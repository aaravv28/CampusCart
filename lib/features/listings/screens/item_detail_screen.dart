import 'package:flutter/material.dart';
import '../../../core/widget/custom_button.dart';

class ItemDetailScreen extends StatelessWidget {
  final String title;
  final String price;
  final String courseCode;
  final String condition;

  const ItemDetailScreen({
    super.key,
    required this.title,
    required this.price,
    required this.courseCode,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(courseCode)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.book, size: 80, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("\$$price", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F52BA))),
                      Chip(label: Text(condition, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    "Gently used textbook for $courseCode. Minimal highlighting on initial chapters. Available for campus pickup near the library.",
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: CustomButton(
              text: "Message Seller",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Chat feature handled by partner branch!")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}