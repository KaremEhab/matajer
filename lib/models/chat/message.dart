// models/chat_message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matajer/models/product_model.dart';

enum MessageType { text, image, audio, video, productMention, offer }

class ChatMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String? text;
  final String? mediaUrl;
  final OfferModel? offer;
  final String? productMentionId;
  final MessageType type;
  final Timestamp timestamp;
  final bool isSeen;
  final bool isLastMessage;
  final List<String> deleteFor;

  ChatMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    this.text,
    this.mediaUrl,
    this.offer,
    this.productMentionId,
    required this.type,
    required this.timestamp,
    this.isSeen = false,
    required this.isLastMessage,
    required this.deleteFor,
  });

  ChatMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? text,
    String? mediaUrl,
    OfferModel? offer,
    String? productMentionId,
    MessageType? type,
    Timestamp? timestamp,
    bool? isSeen,
    bool? isLastMessage,
    List<String>? deleteFor,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      offer: offer ?? this.offer,
      productMentionId: productMentionId ?? this.productMentionId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      isLastMessage: isLastMessage ?? this.isLastMessage,
      deleteFor: deleteFor ?? this.deleteFor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'mediaUrl': mediaUrl,
      'offer': offer?.toMap(),
      'productMentionId': productMentionId,
      'type': type.name,
      'timestamp': timestamp,
      'isSeen': isSeen,
      'isLastMessage': isLastMessage,
      'deleteFor': deleteFor,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> data) {
    return ChatMessageModel(
      id: data['id'],
      chatId: data['chatId'],
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      offer: data['offer'] != null ? OfferModel.fromJson(data['offer']) : null,
      productMentionId: data['productMentionId'],
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: data['timestamp'],
      isSeen: data['isSeen'] ?? false,
      isLastMessage: data['isLastMessage'] ?? false,
      deleteFor: List<String>.from(data['deleteFor'] ?? []),
    );
  }

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      id: data['id'],
      chatId: data['chatId'],
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      offer: data['offer'] != null ? OfferModel.fromJson(data['offer']) : null,
      productMentionId: data['productMentionId'],
      type: MessageType.values.firstWhere((e) => e.name == data['type']),
      timestamp: data['timestamp'],
      isSeen: data['isSeen'] ?? false,
      isLastMessage: data['isLastMessage'] ?? false,
      deleteFor: List<String>.from(data['deleteFor'] ?? []),
    );
  }
}

class OfferModel {
  late ProductModel product;
  late String description;
  late num newPrice;
  Timestamp? expireDate;

  OfferModel({
    required this.product,
    required this.newPrice,
    required this.description,
    this.expireDate,
  });

  OfferModel.fromJson(Map<String, dynamic>? json) {
    product = ProductModel.fromJson(json!['product']);
    newPrice = json['newPrice'];
    description = json['description'];
    expireDate = json['expireDate'];
  }

  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'newPrice': newPrice,
      'description': description,
      'expireDate': expireDate,
    };
  }
}
