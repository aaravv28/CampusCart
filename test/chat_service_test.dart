import 'package:flutter_test/flutter_test.dart';
import 'package:campus_cart/core/config/app_config.dart';
import 'package:campus_cart/features/chat/services/chat_service.dart';

void main() {
  group('ChatService Offline Messaging Tests', () {
    late ChatService chatService;

    setUp(() {
      AppConfig.instance.resetDemoData();
      chatService = ChatService();
    });

    test('getUserChatRooms returns active user conversations', () async {
      final rooms = await chatService.getUserChatRooms();
      expect(rooms, isNotEmpty);
      expect(rooms.length, greaterThanOrEqualTo(2));
      expect(rooms.first['listing_id'], isNotNull);
    });

    test(
      'getOrCreateChatRoom returns existing room or creates new one',
      () async {
        // Existing room for list_1
        final room1 = await chatService.getOrCreateChatRoom(
          listingId: 'list_1',
          sellerId: 'seller_101',
        );
        expect(room1['id'], equals('room_1'));

        // New room for list_4
        final newRoom = await chatService.getOrCreateChatRoom(
          listingId: 'list_4',
          sellerId: 'seller_103',
        );
        expect(newRoom['id'], isNotNull);
        expect(newRoom['listing_id'], equals('list_4'));
      },
    );

    test('sendMessage adds message and updates messages stream', () async {
      final stream = chatService.getMessagesStream('room_1');
      final expectation = expectLater(
        stream,
        emitsThrough(
          predicate<List<Map<String, dynamic>>>(
            (msgs) => msgs.any(
              (m) => m['content'] == 'Can we meet at the campus center?',
            ),
          ),
        ),
      );

      await chatService.sendMessage(
        chatRoomId: 'room_1',
        content: 'Can we meet at the campus center?',
      );

      await expectation;
    });
  });
}
