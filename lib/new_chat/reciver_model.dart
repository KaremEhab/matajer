import 'package:cloud_firestore/cloud_firestore.dart';

class ReciverModel {
  late String uId;
  late String username;
  late String? imageUrl;
  late String lastMessage;
  late Timestamp? lastMessageDate;
  late bool isPinned = false;

  ReciverModel({
    required this.uId,
    required this.username,
    required this.imageUrl,
    required this.lastMessage,
    required this.lastMessageDate,
  });

  ReciverModel.fromJson(Map<String, dynamic>? json, this.uId, this.isPinned) {
    username = json!['username'];
    imageUrl = json['imageUrl'];
    lastMessage = json['lastMessage']??'';
    lastMessageDate = json['lastMessageDate']??Timestamp.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'imageUrl': imageUrl,
      'lastMessage': lastMessage,
      'lastMessageDate': lastMessageDate,
    };
  }
}