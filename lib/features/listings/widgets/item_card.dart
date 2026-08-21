import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final String title;
  final String price;
  final String courseCode;
  final String condition;

  const ItemCard({
    super.key,
    required this.title,
    required this.price,
    required this.courseCode,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              width: double.infinity,
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.book_outlined, size: 48, color: Colors.grey)),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                      child: Text(courseCode, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("\$$price", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F52BA))),
                    Text(condition, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}