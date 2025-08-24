import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  String? id;
  List? members;
  String? lastMessage;
  Map<String, dynamic>? username;
  Map<String, dynamic>? profilePic;
  Map<String, dynamic>? online;
  Timestamp? lastMessageTime;
  Timestamp? createdAt;

  ChatRoomModel({
    required this.id,
    required this.members,
    required this.username,
    required this.profilePic,
    required this.lastMessage,
    required this.online,
    required this.lastMessageTime,
    required this.createdAt,
  });

  ChatRoomModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? '';
    members = json['members'] ?? [];
    username = json['username'];
    profilePic = json['profilePic'];
    lastMessage = json['lastMessage'] ?? '';
    online = json['online'];
    lastMessageTime = json['lastMessageTime'];
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'members': members,
      'lastMessage': lastMessage,
      'username': username,
      'online': online,
      'profilePic': profilePic,
      'lastMessageTime': lastMessageTime,
      'createdAt': createdAt,
    };
  }
}
