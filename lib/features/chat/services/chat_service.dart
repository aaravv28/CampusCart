import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_error.dart';
import '../../../core/utils/app_logger.dart';
import '../../colleges/services/college_service.dart';

class ChatService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final CollegeService _collegeService = CollegeService();

  User? get currentUser {
    if (AppConfig.instance.isDemoMode) {
      final demoUser = AppConfig.instance.currentDemoUser;
      if (demoUser == null) return null;
      return User(
        id: demoUser['id'] as String,
        appMetadata: const {},
        userMetadata: {'full_name': demoUser['full_name']},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    try {
      return _supabase?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // 1. Get or Create Chat Room for an Item
  Future<Map<String, dynamic>> getOrCreateChatRoom({
    required String listingId,
    required String sellerId,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw AppError.authentication(
        'You must be logged in to chat with sellers.',
      );
    }

    if (AppConfig.instance.isDemoMode || _supabase == null) {
      return AppConfig.instance.getOrCreateDemoChatRoom(
        listingId: listingId,
        sellerId: sellerId,
      );
    }

    try {
      final profile = await _collegeService.getCurrentUserProfile();
      final collegeId = profile?['college_id'];

      // Check if chat room already exists
      final existingRoom = await _supabase!
          .from('chat_rooms')
          .select()
          .eq('listing_id', listingId)
          .eq('buyer_id', user.id)
          .maybeSingle();

      if (existingRoom != null) {
        return existingRoom;
      }

      // Create new room if it doesn't exist
      return await _supabase!
          .from('chat_rooms')
          .insert({
            'listing_id': listingId,
            'buyer_id': user.id,
            'seller_id': sellerId,
            'college_id': collegeId,
          })
          .select()
          .single();
    } catch (e) {
      AppLogger.warning(
        'Remote chat room lookup failed, falling back to local chat room',
        e,
      );
      return AppConfig.instance.getOrCreateDemoChatRoom(
        listingId: listingId,
        sellerId: sellerId,
      );
    }
  }

  // 2. Stream Real-time Messages in a Room
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatRoomId) {
    if (AppConfig.instance.isDemoMode || _supabase == null) {
      return AppConfig.instance.getDemoMessagesStream(chatRoomId);
    }

    try {
      return _supabase!
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: true);
    } catch (e) {
      AppLogger.warning(
        'Realtime message stream failed, streaming local messages',
        e,
      );
      return AppConfig.instance.getDemoMessagesStream(chatRoomId);
    }
  }

  // 3. Send Message
  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    final user = currentUser;
    if (user == null) {
      throw AppError.authentication('You must be logged in to send messages.');
    }

    if (AppConfig.instance.isDemoMode || _supabase == null) {
      AppConfig.instance.sendDemoMessage(
        chatRoomId: chatRoomId,
        content: cleanContent,
      );
      return;
    }

    try {
      await _supabase!.from('messages').insert({
        'chat_room_id': chatRoomId,
        'sender_id': user.id,
        'content': cleanContent,
      });
    } catch (e) {
      AppLogger.warning('Failed to send remote message, storing locally', e);
      AppConfig.instance.sendDemoMessage(
        chatRoomId: chatRoomId,
        content: cleanContent,
      );
    }
  }

  // 4. Fetch All Active Conversations for User
  Future<List<Map<String, dynamic>>> getUserChatRooms() async {
    final user = currentUser;
    if (user == null) return [];

    if (AppConfig.instance.isDemoMode || _supabase == null) {
      return List<Map<String, dynamic>>.from(AppConfig.instance.demoChatRooms);
    }

    try {
      final response = await _supabase!
          .from('chat_rooms')
          .select('*, listings(title, image_url, price)')
          .or('buyer_id.eq.${user.id},seller_id.eq.${user.id}')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.warning(
        'Failed to load remote chat rooms, falling back to local chat rooms',
        e,
      );
      return List<Map<String, dynamic>>.from(AppConfig.instance.demoChatRooms);
    }
  }
}
