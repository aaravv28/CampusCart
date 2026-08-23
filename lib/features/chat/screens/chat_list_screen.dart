import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  late Future<List<Map<String, dynamic>>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _chatService.getUserChatRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campus Chats 💬", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data ?? [];

          if (rooms.isEmpty) {
            return const Center(
              child: Text("No active chats found.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final listing = room['listings'] ?? {};

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0F52BA).withOpacity(0.1),
                  backgroundImage: listing['image_url'] != null ? NetworkImage(listing['image_url']) : null,
                  child: listing['image_url'] == null ? const Icon(Icons.shopping_bag, color: Color(0xFF0F52BA)) : null,
                ),
                title: Text(listing['title'] ?? 'Item Chat', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Price: \$${listing['price'] ?? '0'}"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        chatRoomId: room['id'],
                        itemTitle: listing['title'] ?? 'Chat',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}