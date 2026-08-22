import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String sellerName;
  final String itemName;

  const ChatScreen({
    super.key,
    required this.sellerName,
    required this.itemName,
  });

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController =
  TextEditingController();

  final List<Map<String, dynamic>> _messages = [
    {
      "text":
      "Hi! Is this item still available?",
      "isMe": true,
    },
    {
      "text":
      "Yes, it is still available.",
      "isMe": false,
    },
  ];

  void _sendMessage() {
    final message =
    _messageController.text.trim();

    if (message.isEmpty) {
      return;
    }

    setState(() {
      _messages.add({
        "text": message,
        "isMe": true,
      });
    });

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(widget.sellerName),
            Text(
              widget.itemName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message =
                _messages[index];

                final isMe =
                message["isMe"] as bool;

                final text =
                message["text"] as String;

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                      MediaQuery.of(context)
                          .size
                          .width *
                          0.75,
                    ),
                    margin:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          : Colors.grey.shade200,
                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Text(text),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      _messageController,
                      textInputAction:
                      TextInputAction.send,
                      decoration:
                      InputDecoration(
                        hintText:
                        "Type a message...",
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            24,
                          ),
                        ),
                      ),
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(
                      Icons.send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}