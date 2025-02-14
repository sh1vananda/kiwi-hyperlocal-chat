import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatBubble extends StatelessWidget {
  final String senderId;
  final String messageText;
  final DateTime timestamp;
  final dynamic location; // Expected to be a GeoPoint

  const ChatBubble({
    super.key,
    required this.senderId,
    required this.messageText,
    required this.timestamp,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isMe = currentUser != null && currentUser.uid == senderId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              messageText,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                  fontSize: 10, color: isMe ? Colors.white70 : Colors.black54),
            ),
            if (location != null)
              Text(
                'Location: ${location.latitude}, ${location.longitude}',
                style: const TextStyle(fontSize: 10, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
