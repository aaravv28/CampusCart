import 'package:supabase_flutter/supabase_flutter.dart';
import '../../colleges/services/college_service.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final CollegeService _collegeService = CollegeService();

  User? get currentUser => _supabase.auth.currentUser;

  // 1. Get or Create Chat Room for an Item
  Future<Map<String, dynamic>> getOrCreateChatRoom({
    required String listingId,
    required String sellerId,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception("User not logged in");

    final profile = await _collegeService.getCurrentUserProfile();
    final collegeId = profile?['college_id'];

    // Check if chat room already exists
    final existingRoom = await _supabase
        .from('chat_rooms')
        .select()
        .eq('listing_id', listingId)
        .eq('buyer_id', user.id)
        .maybeSingle();

    if (existingRoom != null) {
      return existingRoom;
    }

    // Create new room if it doesn't exist
    return await _supabase
        .from('chat_rooms')
        .insert({
      'listing_id': listingId,
      'buyer_id': user.id,
      'seller_id': sellerId,
      'college_id': collegeId,
    })
        .select()
        .single();
  }

  // 2. Stream Real-time Messages in a Room
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatRoomId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', chatRoomId)
        .order('created_at', ascending: true);
  }

  // 3. Send Message
  Future<void> sendMessage({
    required String chatRoomId,
    required String content,
  }) async {
    final user = currentUser;
    if (user == null || content.trim().isEmpty) return;

    await _supabase.from('messages').insert({
      'chat_room_id': chatRoomId,
      'sender_id': user.id,
      'content': content.trim(),
    });
  }

  // 4. Fetch All Active Conversations for User
  Future<List<Map<String, dynamic>>> getUserChatRooms() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('chat_rooms')
        .select('*, listings(title, image_url, price)')
        .or('buyer_id.eq.${user.id},seller_id.eq.${user.id}')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}