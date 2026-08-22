import 'package:flutter/material.dart';

import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversations =
    <Map<String, String>>[
      {
        "name": "Rohan Shah",
        "item":
        "Engineering Mathematics Book",
        "message":
        "Is this still available?",
      },
      {
        "name": "Priya Patel",
        "item": "Scientific Calculator",
        "message": "Can you do ₹700?",
      },
      {
        "name": "Dev Mehta",
        "item": "Lab Coat",
        "message":
        "Where can I pick it up?",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
      ),
      body: conversations.isEmpty
          ? const Center(
        child: Text(
          "No conversations yet",
        ),
      )
          : ListView.separated(
        itemCount: conversations.length,
        separatorBuilder:
            (context, index) =>
        const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation =
          conversations[index];

          final name =
              conversation["name"] ?? "";
          final item =
              conversation["item"] ?? "";
          final message =
              conversation["message"] ?? "";

          return ListTile(
            leading: CircleAvatar(
              child: Text(
                name.isNotEmpty
                    ? name[0]
                    : "?",
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  item,
                  style: const TextStyle(
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
                Text(
                  message,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(
                        sellerName: name,
                        itemName: item,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}