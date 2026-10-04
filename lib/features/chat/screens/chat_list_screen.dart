import 'package:flutter/material.dart';

import '../../../core/widget/empty_view.dart';
import '../../../core/widget/error_view.dart';
import '../../../core/widget/offline_banner.dart';
import '../../../core/widget/safe_item_image.dart';
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
    _loadRooms();
  }

  void _loadRooms() {
    setState(() {
      _roomsFuture = _chatService.getUserChatRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Campus Chats 💬",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: const [ConnectionStatusChip()],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: RefreshIndicator(
                  color: const Color(0xFF1D4ED8),
                  onRefresh: () async => _loadRooms(),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _roomsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1D4ED8)),
                  );
                }

                if (snapshot.hasError) {
                  return ErrorView(error: snapshot.error, onRetry: _loadRooms);
                }

                final rooms = snapshot.data ?? [];

                if (rooms.isEmpty) {
                  return EmptyView(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: "No Active Chats",
                    message: "When you message campus sellers or students inquire about your items, your direct conversations will appear here.",
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: rooms.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final listing = (room['listings'] is Map<String, dynamic>)
                        ? room['listings'] as Map<String, dynamic>
                        : <String, dynamic>{};

                    final title =
                        listing['title']?.toString() ?? 'Item Inquiry';
                    final price = listing['price']?.toString() ?? '0';
                    final imageUrl = listing['image_url'] as String?;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          mouseCursor: SystemMouseCursors.click,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  chatRoomId: room['id']?.toString() ?? '',
                                  itemTitle: title,
                                  listingItem: listing,
                                ),
                              ),
                            );
                            if (mounted) _loadRooms();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 58,
                                    height: 58,
                                    child: SafeItemImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholderIcon:
                                          Icons.chat_bubble_outline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title and Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1D4ED8)
                                                  .withValues(alpha: 0.08),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "\$$price",
                                              style: const TextStyle(
                                                color: Color(0xFF1D4ED8),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Active buyer inquiry",
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    ),
  ],
),
);
  }
}
