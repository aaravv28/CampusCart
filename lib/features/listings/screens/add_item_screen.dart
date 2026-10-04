import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/widget/custom_button.dart';
import '../../../core/widget/custom_text_field.dart';
import '../../../core/widget/offline_banner.dart';
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
  final _descriptionController = TextEditingController();

  String _selectedCategory = "Textbooks";
  String _selectedCondition = "Good";
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isLoading = false;

  final ListingsService _listingsService = ListingsService();
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    "Textbooks",
    "Electronics",
    "Dorm & Furniture",
    "Lab Gear",
  ];
  final List<String> _conditions = ["New", "Like New", "Good", "Fair"];

  final List<String> _quickCourseCodes = [
    "CS101",
    "MATH150",
    "CHEM210",
    "EE204",
    "ME201",
    "GENERAL",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _courseCodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1200,
      );
      if (image != null && mounted) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      AppLogger.warning("Error picking image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Could not open camera or gallery. Please check permissions.",
            ),
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (dialogCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                "Upload Product Photo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                title: const Text(
                  "Take Photo with Camera",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                title: const Text(
                  "Choose from Gallery",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(dialogCtx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedPrice = double.tryParse(_priceController.text.trim());
    if (parsedPrice == null || parsedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid positive price.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _listingsService.uploadImage(_selectedImage!);
      }

      await _listingsService.createListing(
        title: _titleController.text.trim(),
        price: parsedPrice,
        courseCode: _courseCodeController.text.trim(),
        category: _selectedCategory,
        condition: _selectedCondition,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
      );

      if (mounted) {
        final isOnline = OfflineCacheService.instance.isOnline;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline
                  ? "Item posted to campus marketplace! 🎉"
                  : "Saved to offline drafts! Will publish when connected. ⚡",
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        _titleController.clear();
        _priceController.clear();
        _courseCodeController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        final appError = AppError.fromException(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appError.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sell an Item 🏷️",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: const [ConnectionStatusChip()],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                      )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Interactive Image Picker Box (Universal Web & Android safe)
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            height: 190,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _selectedImageBytes != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: Image.memory(
                                          _selectedImageBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.black54,
                                          radius: 16,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: Colors.white,
                                            ),
                                            onPressed: () => setState(() {
                                              _selectedImage = null;
                                              _selectedImageBytes = null;
                                            }),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        right: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "Change",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1D4ED8)
                                              .withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_a_photo_rounded,
                                          size: 34,
                                          color: Color(0xFF1D4ED8),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        "Tap to Add Product Photo",
                                        style: TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Supports Camera, Gallery & Drag-and-drop on Web",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Item Title
                        CustomTextField(
                          label: "Item Title",
                          hint: "e.g., Organic Chemistry 8th Ed - Wade",
                          controller: _titleController,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return "Title is required";
                            }
                            if (val.trim().length < 3) {
                              return "Title must be at least 3 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Price and Course Code
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: "Price (\$)",
                                hint: "45",
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return "Price required";
                                  }
                                  final num = double.tryParse(val.trim());
                                  if (num == null) return "Enter valid number";
                                  if (num <= 0) return "Must be > \$0";
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: "Course Code",
                                hint: "CHEM210",
                                controller: _courseCodeController,
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? "Course code required"
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        // Quick Course Suggestions Chips
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 12),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: _quickCourseCodes.map((code) {
                              return GestureDetector(
                                onTap: () {
                                  _courseCodeController.text = code;
                                },
                                child: Chip(
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    code,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: const Color(0xFFF1F5F9),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // Category Dropdown
                        const Text(
                          "Category",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Condition Dropdown
                        const Text(
                          "Condition",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCondition,
                          decoration: InputDecoration(
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: _conditions
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCondition = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description (Optional)
                        const Text(
                          "Item Details / Description (Optional)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Add condition details, included accessories, campus pickup spots...",
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Post Button
                        CustomButton(
                          text: "Post Listing",
                          onPressed: _submitListing,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
