import 'package:flutter/material.dart';

import '../../../core/widget/demo_badge.dart';
import '../../../core/widget/error_view.dart';
import '../../../core/widget/safe_item_image.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatRoomId;
  final String itemTitle;
  final Map<String, dynamic>? listingItem;

  final String? initialDraft;

  const ChatDetailScreen({
    super.key,
    required this.chatRoomId,
    required this.itemTitle,
    this.listingItem,
    this.initialDraft,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _quickReplies = [
    "Is this still available?",
    "📍 Can we meet at the University Library?",
    "📍 Meet at the Student Center?",
    "Would you accept a slight offer?",
    "What time works best for you?",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialDraft != null && widget.initialDraft!.isNotEmpty) {
      _messageController.text = widget.initialDraft!;
    }
  }

  void _sendMessage([String? presetText]) async {
    final text = presetText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _messageController.clear();
    }

    try {
      await _chatService.sendMessage(
        chatRoomId: widget.chatRoomId,
        content: text,
      );
      // Auto-scroll to bottom after message
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to send message. Please try again."),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(dynamic rawTime) {
    if (rawTime == null) return '';
    try {
      final dt = DateTime.parse(rawTime.toString()).toLocal();
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [DemoBadge()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // 1. Top Item Banner
              if (widget.listingItem != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: SafeItemImage(
                            imageUrl:
                                widget.listingItem!['image_url'] as String?,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.listingItem!['title']?.toString() ??
                                  widget.itemTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "\$${widget.listingItem!['price'] ?? 0} • Inquire with student seller",
                              style: const TextStyle(
                                color: Color(0xFF1D4ED8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 2. Real-time Messages List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _chatService.getMessagesStream(widget.chatRoomId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1D4ED8),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return ErrorView(
                        error: snapshot.error,
                        customMessage: "Unable to load messages right now.",
                      );
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: Color(0xFF94A3B8),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "No messages yet. Say hi 👋!",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == currentUserId;
                        final timeStr = _formatTime(msg['created_at']);

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF1D4ED8)
                                  : Colors.white,
                              border: isMe
                                  ? null
                                  : Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg['content']?.toString() ?? '',
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                                if (timeStr.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    timeStr,
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : Colors.grey.shade500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 3. Quick Suggestions Bar
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _quickReplies.length,
                  itemBuilder: (context, index) {
                    final reply = _quickReplies[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ActionChip(
                        label: Text(
                          reply,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        onPressed: () => _sendMessage(reply),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),

              // 4. Message Input Bar
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF1D4ED8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
