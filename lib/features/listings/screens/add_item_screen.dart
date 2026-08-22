import 'package:flutter/material.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _courseCodeController = TextEditingController();

  String _selectedCategory = "Textbooks";
  String _selectedCondition = "Good";

  final List<String> _categories = ["Textbooks", "Electronics", "Dorm & Furniture", "Lab Gear"];
  final List<String> _conditions = ["New", "Like New", "Good", "Fair"];

  void _submitListing() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item listed on Campus Cart! 🎉")),
      );
      _titleController.clear();
      _priceController.clear();
      _courseCodeController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sell an Item 🏷️", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Upload Box Placeholder
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Upload Photo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              CustomTextField(
                label: "Item Title",
                hint: "e.g., Organic Chemistry 8th Ed",
                controller: _titleController,
                validator: (val) => val == null || val.isEmpty ? "Title required" : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: "Price (\$)",
                      hint: "45",
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? "Price required" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: "Course Code",
                      hint: "CHEM210",
                      controller: _courseCodeController,
                      validator: (val) => val == null || val.isEmpty ? "Course required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              const Text("Condition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCondition = val!),
              ),
              const SizedBox(height: 28),

              CustomButton(text: "Post Listing", onPressed: _submitListing),
            ],
          ),
        ),
      ),
    );
  }
}