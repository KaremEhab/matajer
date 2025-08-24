import 'package:cloud_firestore/cloud_firestore.dart';

enum LastMessageType { text, image, video, audio, productMention, offer }

class ChatModel {
  final String chatId;
  final String userId;
  // final String userName;
  // final String userImage;
  final String shopId;
  // final String shopName;
  // final String shopImage;
  final String sentBy;
  final Map<String, String> lastMessage;
  final bool lastMessageSeen;
  final LastMessageType lastMessageType;
  final DateTime lastMessageTime;
  final List<String> visibleTo;
  final Map<String, DateTime> lastDeletedAt; // ✅ NEW FIELD

  ChatModel({
    required this.chatId,
    required this.userId,
    // required this.userName,
    // required this.userImage,
    required this.shopId,
    // required this.shopName,
    // required this.shopImage,
    required this.sentBy,
    required this.lastMessage,
    required this.lastMessageSeen,
    required this.lastMessageType,
    required this.lastMessageTime,
    required this.visibleTo,
    required this.lastDeletedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    // Parse lastDeletedAt safely
    final Map<String, dynamic> rawDeletedAt = json['lastDeletedAt'] ?? {};
    final Map<String, DateTime> parsedDeletedAt = {
      for (var key in rawDeletedAt.keys)
        if (rawDeletedAt[key] is Timestamp)
          key: (rawDeletedAt[key] as Timestamp).toDate(),
    };

    return ChatModel(
      chatId: json['chatId'] ?? '',
      userId: json['userId'] ?? '',
      // userName: json['userName'] ?? '',
      // userImage: json['userImage'] ?? '',
      shopId: json['shopId'] ?? '',
      // shopName: json['shopName'] ?? '',
      // shopImage: json['shopImage'] ?? '',
      sentBy: json['sentBy'] ?? '',
      lastMessage: Map<String, String>.from(json['lastMessage'] ?? {}),
      lastMessageSeen: json['lastMessageSeen'] ?? false,
      lastMessageType: LastMessageType.values.firstWhere(
        (e) => e.name == json['lastMessageType'],
        orElse: () => LastMessageType.text,
      ),
      lastMessageTime: (json['lastMessageTime'] as Timestamp).toDate(),
      visibleTo: List<String>.from(json['visibleTo'] ?? []),
      lastDeletedAt: parsedDeletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    // Convert lastDeletedAt (Map<String, DateTime>) → Map<String, Timestamp>
    final Map<String, Timestamp> convertedDeletedAt = {
      for (var key in lastDeletedAt.keys)
        key: Timestamp.fromDate(lastDeletedAt[key]!),
    };

    return {
      'chatId': chatId,
      'userId': userId,
      // 'userName': userName,
      // 'userImage': userImage,
      'shopId': shopId,
      // 'shopName': shopName,
      // 'shopImage': shopImage,
      'sentBy': sentBy,
      'lastMessage': lastMessage,
      'lastMessageSeen': lastMessageSeen,
      'lastMessageType': lastMessageType.name,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'visibleTo': visibleTo,
      'lastDeletedAt': convertedDeletedAt,
    };
  }
}
