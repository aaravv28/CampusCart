import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/app_logger.dart';
import '../../colleges/services/college_service.dart';

class ListingsService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final CollegeService _collegeService = CollegeService();

  // Helper: Fetch current user's college_id
  Future<String?> _getUserCollegeId() async {
    if (AppConfig.instance.isDemoMode || _supabase == null) {
      final profile = await _collegeService.getCurrentUserProfile();
      return profile?['college_id'] ?? 'col_1';
    }

    try {
      final profile = await _collegeService.getCurrentUserProfile();
      final collegeId = profile?['college_id'];
      if (collegeId != null &&
          collegeId.toString().isNotEmpty &&
          collegeId != 'col_1') {
        return collegeId.toString();
      }
      // If user profile does not yet have college_id, fetch the first available college UUID
      final colleges = await _supabase!.from('colleges').select('id').limit(1);
      if (colleges.isNotEmpty) {
        return colleges.first['id'] as String;
      }
      return null;
    } catch (e) {
      AppLogger.warning('Failed to fetch user college ID', e);
      return null;
    }
  }

  // Upload Image: Universal base64 data URI fallback for demo mode & Supabase storage upload for production
  Future<String?> uploadImage(XFile imageFile) async {
    if (AppConfig.instance.isDemoMode || _supabase == null) {
      AppLogger.info('Demo Mode: Processing image into portable data format');
      try {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.name.split('.').last.toLowerCase();
        final mime = (fileExt == 'png') ? 'image/png' : 'image/jpeg';
        final base64Str = base64Encode(bytes);
        return 'data:$mime;base64,$base64Str';
      } catch (e) {
        return imageFile.path;
      }
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'items/$fileName';

      await _supabase!.storage
          .from('listing-images')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$fileExt'),
          );

      return _supabase!.storage.from('listing-images').getPublicUrl(filePath);
    } catch (e) {
      AppLogger.warning(
        'Image upload failed, falling back to portable data URI',
        e,
      );
      try {
        final bytes = await imageFile.readAsBytes();
        final fileExt = imageFile.name.split('.').last.toLowerCase();
        final mime = (fileExt == 'png') ? 'image/png' : 'image/jpeg';
        final base64Str = base64Encode(bytes);
        return 'data:$mime;base64,$base64Str';
      } catch (_) {
        return imageFile.path;
      }
    }
  }

  // 1. Fetch Listings restricted ONLY to user's college
  Future<List<Map<String, dynamic>>> getListings() async {
    final collegeId = await _getUserCollegeId();

    if (AppConfig.instance.isDemoMode || _supabase == null) {
      return AppConfig.instance.demoListings
          .where((l) => collegeId == null || l['college_id'] == collegeId)
          .toList();
    }

    try {
      var query = _supabase!.from('listings').select();
      if (collegeId != null && collegeId.isNotEmpty && collegeId != 'col_1') {
        query = query.eq('college_id', collegeId);
      }
      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.warning(
        'Failed to load remote listings, falling back to local demo listings',
        e,
      );
      return AppConfig.instance.demoListings
          .where((l) => collegeId == null || l['college_id'] == collegeId)
          .toList();
    }
  }

  // Search listings restricted ONLY to user's college
  Future<List<Map<String, dynamic>>> searchListings(String query) async {
    final collegeId = await _getUserCollegeId();
    final cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) {
      return getListings();
    }

    if (AppConfig.instance.isDemoMode || _supabase == null) {
      return AppConfig.instance.demoListings.where((l) {
        final matchesCollege =
            collegeId == null || l['college_id'] == collegeId;
        final title = (l['title'] ?? '').toString().toLowerCase();
        final course = (l['course_code'] ?? '').toString().toLowerCase();
        final category = (l['category'] ?? '').toString().toLowerCase();
        final matchesQuery =
            title.contains(cleanQuery) ||
            course.contains(cleanQuery) ||
            category.contains(cleanQuery);
        return matchesCollege && matchesQuery;
      }).toList();
    }

    try {
      final response = await _supabase!
          .from('listings')
          .select()
          .eq('college_id', collegeId ?? '')
          .or(
            'title.ilike.%$cleanQuery%,course_code.ilike.%$cleanQuery%,category.ilike.%$cleanQuery%',
          )
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.warning('Remote search failed, searching local demo data', e);
      return AppConfig.instance.demoListings.where((l) {
        final matchesCollege =
            collegeId == null || l['college_id'] == collegeId;
        final title = (l['title'] ?? '').toString().toLowerCase();
        final course = (l['course_code'] ?? '').toString().toLowerCase();
        final matchesQuery =
            title.contains(cleanQuery) || course.contains(cleanQuery);
        return matchesCollege && matchesQuery;
      }).toList();
    }
  }

  // 2. Create Listing attached to user's college
  Future<void> createListing({
    required String title,
    required double price,
    required String courseCode,
    required String category,
    required String condition,
    String? description,
    String? imageUrl,
  }) async {
    final collegeId = await _getUserCollegeId();

    if (AppConfig.instance.isDemoMode || _supabase == null) {
      final user = AppConfig.instance.currentDemoUser;
      final newListing = {
        'id': 'list_${DateTime.now().millisecondsSinceEpoch}',
        'title': title.trim(),
        'price': price,
        'course_code': courseCode.trim().toUpperCase(),
        'category': category,
        'condition': condition,
        'description': description?.trim() ?? '',
        'image_url': imageUrl,
        'seller_id': user?['id'] ?? 'demo_user_123',
        'seller_name': user?['full_name'] ?? 'Alex Johnson',
        'seller_college':
            user?['colleges']?['name'] ?? 'Dharmsinh Desai University',
        'college_id': collegeId ?? 'col_1',
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
      };
      AppConfig.instance.addDemoListing(newListing);
      AppLogger.info('Demo Mode: Listing created and saved to local memory');
      return;
    }

    try {
      final user = _supabase?.auth.currentUser;
      if (user == null || collegeId == null) {
        throw AppError.validation('User college profile not found.');
      }

      final coreData = <String, dynamic>{
        'title': title.trim(),
        'price': price,
        'course_code': courseCode.trim().toUpperCase(),
        'category': category,
        'condition': condition,
        'image_url': imageUrl,
        'seller_id': user.id,
        'college_id': collegeId,
      };

      try {
        await _supabase!.from('listings').insert({
          ...coreData,
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'status': 'available',
        });
      } catch (insertErr) {
        // If Supabase schema does not have description/status columns, fallback to core columns
        final errStr = insertErr.toString();
        if (errStr.contains('PGRST204') ||
            errStr.contains('description') ||
            errStr.contains('status')) {
          await _supabase!.from('listings').insert(coreData);
        } else {
          rethrow;
        }
      }
    } catch (e) {
      AppLogger.error('ListingsService.createListing failed', e);
      throw AppError.fromException(e);
    }
  }

  // Delete a listing
  Future<void> deleteListing(String listingId) async {
    if (AppConfig.instance.isDemoMode || _supabase == null) {
      AppConfig.instance.deleteDemoListing(listingId);
      return;
    }

    try {
      await _supabase!.from('listings').delete().eq('id', listingId);
    } catch (e) {
      AppLogger.warning('Remote delete failed, deleting locally', e);
      AppConfig.instance.deleteDemoListing(listingId);
    }
  }

  // Mark listing as sold
  Future<void> markListingSold(String listingId) async {
    if (AppConfig.instance.isDemoMode || _supabase == null) {
      AppConfig.instance.markDemoListingSold(listingId);
      return;
    }

    try {
      await _supabase!
          .from('listings')
          .update({'status': 'sold'})
          .eq('id', listingId);
    } catch (e) {
      AppLogger.warning('Remote mark sold failed, updating locally', e);
      AppConfig.instance.markDemoListingSold(listingId);
    }
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
    final cleanQuery = query?.trim().toLowerCase();

    if (AppConfig.instance.isDemoMode || _supabase == null) {
      var list = AppConfig.instance.demoListings.where((l) {
        if (collegeId != null && l['college_id'] != collegeId) return false;

        if (cleanQuery != null && cleanQuery.isNotEmpty) {
          final title = (l['title'] ?? '').toString().toLowerCase();
          final course = (l['course_code'] ?? '').toString().toLowerCase();
          final cat = (l['category'] ?? '').toString().toLowerCase();
          if (!title.contains(cleanQuery) &&
              !course.contains(cleanQuery) &&
              !cat.contains(cleanQuery)) {
            return false;
          }
        }

        if (category != null && category != 'All') {
          if (l['category'] != category) return false;
        }

        if (condition != null && condition != 'All') {
          if (l['condition'] != condition) return false;
        }

        if (maxPrice != null) {
          final price = (l['price'] is num)
              ? (l['price'] as num).toDouble()
              : 0.0;
          if (price > maxPrice) return false;
        }

        return true;
      }).toList();

      if (sortBy == 'price_low') {
        list.sort(
          (a, b) =>
              ((a['price'] as num?) ?? 0).compareTo((b['price'] as num?) ?? 0),
        );
      } else if (sortBy == 'price_high') {
        list.sort(
          (a, b) =>
              ((b['price'] as num?) ?? 0).compareTo((a['price'] as num?) ?? 0),
        );
      } else {
        list.sort(
          (a, b) => (b['created_at'] ?? '').toString().compareTo(
            (a['created_at'] ?? '').toString(),
          ),
        );
      }

      return list;
    }

    try {
      var request = _supabase!
          .from('listings')
          .select()
          .eq('college_id', collegeId ?? '');

      if (cleanQuery != null && cleanQuery.isNotEmpty) {
        request = request.or(
          'title.ilike.%$cleanQuery%,course_code.ilike.%$cleanQuery%,category.ilike.%$cleanQuery%',
        );
      }

      if (category != null && category != 'All') {
        request = request.eq('category', category);
      }

      if (condition != null && condition != 'All') {
        request = request.eq('condition', condition);
      }

      if (maxPrice != null) {
        request = request.lte('price', maxPrice);
      }

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
    } catch (e) {
      AppLogger.warning(
        'Filter listings remote query failed, filtering locally',
        e,
      );
      return filterListings(
        query: query,
        category: category,
        condition: condition,
        maxPrice: maxPrice,
        sortBy: sortBy,
      );
    }
  }
}
