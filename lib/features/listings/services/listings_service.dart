import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ListingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Advanced filter query for dedicated Search Screen
  Future<List<Map<String, dynamic>>> filterListings({
    String? query,
    String? category,
    String? condition,
    double? maxPrice,
    String sortBy = 'newest',
  }) async {
    var request = _supabase.from('listings').select();

    // Search keyword filter
    if (query != null && query.trim().isNotEmpty) {
      request = request.or('title.ilike.%$query%,course_code.ilike.%$query%');
    }

    // Category filter
    if (category != null && category != 'All') {
      request = request.eq('category', category);
    }

    // Condition filter
    if (condition != null && condition != 'All') {
      request = request.eq('condition', condition);
    }

    // Price cap filter
    if (maxPrice != null) {
      request = request.lte('price', maxPrice);
    }

    // Sorting
    if (sortBy == 'price_low') {
      return List<Map<String, dynamic>>.from(
        await request.order('price', ascending: true),
      );
    } else if (sortBy == 'price_high') {
      return List<Map<String, dynamic>>.from(
        await request.order('price', ascending: false),
      );
    } else {
      return List<Map<String, dynamic>>.from(
        await request.order('created_at', ascending: false),
      );
    }
  }

  // Add search functionality targeting title and course_code
  Future<List<Map<String, dynamic>>> searchListings(String query) async {
    if (query.trim().isEmpty) {
      return getListings();
    }

    final response = await _supabase
        .from('listings')
        .select()
        .or('title.ilike.%$query%,course_code.ilike.%$query%')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

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