import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  Position? _currentPosition;
  String? _currentRoomId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _determinePositionAndRoom();
  }

  /// Get the current location and compute the chat room (H3 index) using the REST API.
  Future<void> _determinePositionAndRoom() async {
    try {
      Position pos = await _chatService.getCurrentLocation();
      String roomId = await _chatService.getRoomId(pos, resolution: 7);
      if (mounted) {
        setState(() {
          _currentPosition = pos;
          _currentRoomId = roomId;
        });
      }
      debugPrint('Obtained position: $_currentPosition');
      debugPrint('Computed room ID (hex grid): $_currentRoomId');
    } catch (e) {
      debugPrint('Failed to obtain location or room ID: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error obtaining location: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    String text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_currentPosition == null || _currentRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location not available. Please refresh.')),
      );
      return;
    }
    try {
      await _chatService.sendMessage(
        text: text,
        location: _currentPosition!,
        senderId: FirebaseAuth.instance.currentUser!.uid,
      );
      _messageController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRoomId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Room ($_currentRoomId)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _determinePositionAndRoom,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(_currentRoomId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages in this area.'));
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    DateTime timestamp = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();
                    return ChatBubble(
                      senderId: data['senderId'] as String,
                      messageText: data['messageText'] as String,
                      timestamp: timestamp,
                      location: data['location'],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.grey[200],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter message...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
