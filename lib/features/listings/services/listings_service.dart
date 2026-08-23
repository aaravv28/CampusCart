import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../colleges/services/college_service.dart';

class ListingsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CollegeService _collegeService = CollegeService();

  // Helper: Fetch current user's college_id
  Future<String?> _getUserCollegeId() async {
    final profile = await _collegeService.getCurrentUserProfile();
    return profile?['college_id'];
  }

  // Search listings restricted ONLY to user's college
  Future<List<Map<String, dynamic>>> searchListings(String query) async {
    final collegeId = await _getUserCollegeId();
    if (collegeId == null) return [];

    if (query.trim().isEmpty) {
      return getListings();
    }

    final response = await _supabase
        .from('listings')
        .select()
        .eq('college_id', collegeId) // 👈 Campus Isolation Filter
        .or('title.ilike.%$query%,course_code.ilike.%$query%')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }


  // Upload Image
  Future<String?> uploadImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final fileExt = imageFile.name.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'items/$fileName';

    await _supabase.storage.from('listing-images').uploadBinary(
      filePath,
      bytes,
      fileOptions: FileOptions(contentType: 'image/$fileExt'),
    );

    return _supabase.storage.from('listing-images').getPublicUrl(filePath);
  }

  // 1. Fetch Listings restricted ONLY to user's college
  Future<List<Map<String, dynamic>>> getListings() async {
    final collegeId = await _getUserCollegeId();
    if (collegeId == null) return [];

    final response = await _supabase
        .from('listings')
        .select()
        .eq('college_id', collegeId) // 👈 Campus Isolation Filter
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // 2. Create Listing attached to user's college
  Future<void> createListing({
    required String title,
    required double price,
    required String courseCode,
    required String category,
    required String condition,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    final collegeId = await _getUserCollegeId();

    if (user == null || collegeId == null) {
      throw Exception("User college profile not found.");
    }

    await _supabase.from('listings').insert({
      'title': title,
      'price': price,
      'course_code': courseCode,
      'category': category,
      'condition': condition,
      'image_url': imageUrl,
      'seller_id': user.id,
      'college_id': collegeId, // 👈 Scoped to college
    });
  }

  // Advanced filter query restricted ONLY to user's college
  Future<List<Map<String, dynamic>>> filterListings({
    String? query,
    String? category,
    String? condition,
    double? maxPrice,
    String sortBy = 'newest',
  }) async {
    final collegeId = await _getUserCollegeId();
    if (collegeId == null) return [];

    var request = _supabase
        .from('listings')
        .select()
        .eq('college_id', collegeId); // 👈 Campus Isolation Filter

    // Keyword search filter
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

    // Sort ordering
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
}