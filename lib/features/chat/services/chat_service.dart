import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_error.dart';
import '../../../core/services/offline_cache_service.dart';
import '../../../core/utils/app_logger.dart';

class ChatService {
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser {
    try {
      return _supabase?.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  // In-memory stream controllers for smooth offline transitions
  final Map<String, StreamController<List<Map<String, dynamic>>>>
      _roomStreamControllers = {};

  StreamController<List<Map<String, dynamic>>> _getController(String roomId) {
    if (!_roomStreamControllers.containsKey(roomId) ||
        _roomStreamControllers[roomId]!.isClosed) {
      _roomStreamControllers[roomId] =
          StreamController<List<Map<String, dynamic>>>.broadcast();
    }
    return _roomStreamControllers[roomId]!;
  }

  /// Gets existing or creates new chat room between buyer and seller for a listing
  Future<Map<String, dynamic>> getOrCreateChatRoom({
    required String listingId,
    required String sellerId,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw AppError.authentication('You must be logged in to chat with sellers.');
    }

    final client = _supabase;
    if (client != null && OfflineCacheService.instance.isOnline) {
      try {
        // Query existing room
        final existingRoom = await client
            .from('chat_rooms')
            .select()
            .eq('listing_id', listingId)
            .eq('buyer_id', user.id)
            .maybeSingle();

        if (existingRoom != null) {
          final room = Map<String, dynamic>.from(existingRoom);
          _saveRoomToLocalCache(room);
          return room;
        }

        // Insert new room (exact columns: listing_id, buyer_id, seller_id)
        final newRoom = await client
            .from('chat_rooms')
            .insert({
              'listing_id': listingId,
              'buyer_id': user.id,
              'seller_id': sellerId,
            })
            .select()
            .single();

        final room = Map<String, dynamic>.from(newRoom);
        _saveRoomToLocalCache(room);
        OfflineCacheService.instance.isOnline = true;
        return room;
      } catch (e) {
        AppLogger.warning('Failed to query or create remote chat room: $e');
        OfflineCacheService.instance.isOnline = false;
      }
    }

    // Local / Offline fallback room
    final localRoom = {
      'id': 'room_${listingId}_${user.id}',
      'listing_id': listingId,
      'buyer_id': user.id,
      'seller_id': sellerId,
      'created_at': DateTime.now().toIso8601String(),
    };
    _saveRoomToLocalCache(localRoom);
    return localRoom;
  }

  Future<void> _saveRoomToLocalCache(Map<String, dynamic> room) async {
    final rooms = await OfflineCacheService.instance.getCachedChatRooms();
    final index = rooms.indexWhere((r) => r['id'] == room['id']);
    if (index >= 0) {
      rooms[index] = room;
    } else {
      rooms.insert(0, room);
    }
    await OfflineCacheService.instance.cacheChatRooms(rooms);
  }

  /// Streams real-time messages for a room, updating offline cache automatically
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatRoomId) {
    final client = _supabase;
    final controller = _getController(chatRoomId);

    // Initial load from offline cache
    OfflineCacheService.instance.getCachedMessages(chatRoomId).then((cached) {
      if (!controller.isClosed) {
        controller.add(cached);
      }
    });

    if (client != null && OfflineCacheService.instance.isOnline) {
      try {
        final stream = client
            .from('messages')
            .stream(primaryKey: ['id'])
            .eq('chat_room_id', chatRoomId)
            .order('created_at', ascending: true);

        stream.listen(
          (messages) {
            final list = List<Map<String, dynamic>>.from(messages);
            OfflineCacheService.instance.cacheMessages(chatRoomId, list);
            if (!controller.isClosed) {
              controller.add(list);
            }
          },
          onError: (e) {
            AppLogger.warning('Supabase message stream error: $e');
          },
        );
      } catch (e) {
        AppLogger.warning('Could not initiate realtime message stream: $e');
      }
    }

    return controller.stream;
  }

  /// Sends a message into a chat room
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

    final localMsg = {
      'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
      'chat_room_id': chatRoomId,
      'sender_id': user.id,
      'content': cleanContent,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Immediately append to local cache and emit to stream
    final cached = await OfflineCacheService.instance.getCachedMessages(chatRoomId);
    cached.add(localMsg);
    await OfflineCacheService.instance.cacheMessages(chatRoomId, cached);

    final controller = _getController(chatRoomId);
    if (!controller.isClosed) {
      controller.add(cached);
    }

    final client = _supabase;
    if (client != null && OfflineCacheService.instance.isOnline) {
      try {
        await client.from('messages').insert({
          'chat_room_id': chatRoomId,
          'sender_id': user.id,
          'content': cleanContent,
        });
        OfflineCacheService.instance.isOnline = true;
      } catch (e) {
        AppLogger.warning('Failed to send remote message, preserved in local cache: $e');
        OfflineCacheService.instance.isOnline = false;
      }
    }
  }

  /// Fetches all active conversations for the user
  Future<List<Map<String, dynamic>>> getUserChatRooms() async {
    final user = currentUser;
    if (user == null) {
      return OfflineCacheService.instance.getCachedChatRooms();
    }

    final client = _supabase;
    if (client != null) {
      try {
        final response = await client
            .from('chat_rooms')
            .select('*, listings(title, image_url, price)')
            .or('buyer_id.eq.${user.id},seller_id.eq.${user.id}')
            .order('created_at', ascending: false);

        final rooms = List<Map<String, dynamic>>.from(response);
        await OfflineCacheService.instance.cacheChatRooms(rooms);
        OfflineCacheService.instance.isOnline = true;
        return rooms;
      } catch (e) {
        AppLogger.warning('Failed to load remote chat rooms, using offline cache: $e');
        OfflineCacheService.instance.isOnline = false;
      }
    }

    return OfflineCacheService.instance.getCachedChatRooms();
  }
}
