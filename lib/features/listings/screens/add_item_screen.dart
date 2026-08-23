import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';
import '../services/listings_service.dart';

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
  XFile? _selectedImage;
  bool _isLoading = false;

  final ListingsService _listingsService = ListingsService();
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ["Textbooks", "Electronics", "Dorm & Furniture", "Lab Gear"];
  final List<String> _conditions = ["New", "Like New", "Good", "Fair"];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compresses image for faster upload
      );
      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open camera/gallery: $e")),
        );
      }
    }
  }
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Photo Source",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF0F52BA)),
              title: const Text("Take Photo with Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF0F52BA)),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitListing() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an item photo first!")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        // 1. Upload photo to Storage
        final imageUrl = await _listingsService.uploadImage(_selectedImage!);

        // 2. Insert record into Database
        await _listingsService.createListing(
          title: _titleController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          courseCode: _courseCodeController.text.trim(),
          category: _selectedCategory,
          condition: _selectedCondition,
          imageUrl: imageUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item posted successfully with photo! 🎉")),
          );
          _titleController.clear();
          _priceController.clear();
          _courseCodeController.clear();
          setState(() => _selectedImage = null);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Upload failed: ${e.toString()}")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sell an Item 🏷️", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Interactive Image Picker Box
              GestureDetector(
                onTap: _showImageSourceDialog, // 👈 Updated here
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "Tap to Add Photo",
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
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