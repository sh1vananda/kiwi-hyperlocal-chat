import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Chat rooms are stored under the "rooms" collection.
  final String roomsCollection = 'rooms';
  // Set your deployed REST API endpoint here.
  final String h3ApiUrl = 'https://h3-api.vercel.app/api/h3';

  /// Compute the room ID by calling the REST API.
  Future<String> getRoomId(Position pos, {int resolution = 7}) async {
    final url = Uri.parse(
      '$h3ApiUrl?lat=${pos.latitude}&lng=${pos.longitude}&resolution=$resolution',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('h3Index')) {
        return data['h3Index'].toString();
      } else {
        throw Exception('Response does not contain h3Index');
      }
    } else {
      throw Exception(
          'Failed to fetch H3 index from API: ${response.statusCode}');
    }
  }

  /// Retrieve the current location with low accuracy and a timeout.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// Send a message: compute the room ID using the current location and add the message to Firestore.
  Future<void> sendMessage({
    required String text,
    required Position location,
    required String senderId,
  }) async {
    String roomId = await getRoomId(location, resolution: 7);
    final messageData = {
      'senderId': senderId,
      'messageText': text,
      'timestamp': FieldValue.serverTimestamp(),
      'location': GeoPoint(location.latitude, location.longitude),
    };
    await _firestore
        .collection(roomsCollection)
        .doc(roomId)
        .collection('messages')
        .add(messageData);
  }

  /// Get a stream of messages for a specific room.
  Stream<QuerySnapshot> getMessagesStream(String roomId) {
    return _firestore
        .collection(roomsCollection)
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
