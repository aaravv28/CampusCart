import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ListingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'items/$fileName';

      // Upload binary bytes to 'listing-images' bucket
      await _supabase.storage.from('listing-images').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );

      // Get public URL of the uploaded image
      final imageUrl = _supabase.storage.from('listing-images').getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      rethrow;
    }
  }


  // 1. Fetch all listings from Supabase ordered by newest first
  Future<List<Map<String, dynamic>>> getListings() async {
    final response = await _supabase
        .from('listings')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Create a new listing record in Supabase
  Future<void> createListing({
    required String title,
    required double price,
    required String courseCode,
    required String category,
    required String condition,
    String? imageUrl,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    await _supabase.from('listings').insert({
      'title': title,
      'price': price,
      'course_code': courseCode,
      'category': category,
      'condition': condition,
      'image_url': imageUrl,
      'seller_id': userId,
    });
  }
}