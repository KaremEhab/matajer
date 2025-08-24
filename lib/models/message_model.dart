import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  String? id;
  String? toId;
  String? fromId;
  String? message;
  String? read;
  String? type;
  Timestamp? createdAt;

  MessageModel({
    required this.id,
    required this.toId,
    required this.fromId,
    required this.message,
    required this.read,
    required this.type,
    required this.createdAt,
  });

  MessageModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? '';
    toId = json['toId'] ?? '';
    fromId = json['fromId'] ?? '';
    message = json['message'] ?? '';
    read = json['read'] ?? '';
    type = json['type'] ?? '';
    createdAt = json['createdAt'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toId': toId,
      'fromId': fromId,
      'message': message,
      'read': read,
      'type': type,
      'createdAt': createdAt,
    };
  }
}
