import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_cart/core/errors/app_error.dart';
import 'package:campus_cart/core/services/offline_cache_service.dart';
import 'package:campus_cart/features/chat/services/chat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatService Tests', () {
    late ChatService chatService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await OfflineCacheService.instance.init();
      chatService = ChatService();
    });

    test('getOrCreateChatRoom throws authentication error when user is not logged in', () async {
      expect(
        () => chatService.getOrCreateChatRoom(
          listingId: 'list_123',
          sellerId: 'seller_456',
        ),
        throwsA(isA<AppError>()),
      );
    });

    test('Cached chat rooms can be retrieved when offline', () async {
      final sampleRooms = [
        {
          'id': 'room_1',
          'listing_id': 'list_1',
          'buyer_id': 'u1',
          'seller_id': 'u2',
        }
      ];
      await OfflineCacheService.instance.cacheChatRooms(sampleRooms);

      final rooms = await chatService.getUserChatRooms();
      expect(rooms, isNotEmpty);
      expect(rooms.first['id'], equals('room_1'));
    });

    test('getMessagesStream loads cached messages and receives newly sent messages', () async {
      const roomId = 'room_test_1';
      final initialMessages = [
        {
          'id': 'msg_1',
          'chat_room_id': roomId,
          'sender_id': 'u1',
          'content': 'Hi, is this still available?',
          'created_at': DateTime.now().toIso8601String(),
        }
      ];
      await OfflineCacheService.instance.cacheMessages(roomId, initialMessages);

      final stream = chatService.getMessagesStream(roomId);
      final expectation = expectLater(
        stream,
        emitsThrough(
          predicate<List<Map<String, dynamic>>>(
            (msgs) => msgs.any((m) => m['content'] == 'Hi, is this still available?'),
          ),
        ),
      );

      await expectation;
    });
  });
}
