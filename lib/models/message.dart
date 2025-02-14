import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String messageText;
  final DateTime timestamp;
  final GeoPoint location;

  Message({
    required this.senderId,
    required this.messageText,
    required this.timestamp,
    required this.location,
  });

  factory Message.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      senderId: data['senderId'] ?? '',
      messageText: data['messageText'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'messageText': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'location': location,
    };
  }
}
