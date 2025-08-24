import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matajer/models/product_model.dart';

enum MessageType { text, image, offer }

class MessageModel {
  String? id;
  String? message;
  String? senderId;
  String? receiverId;
  Timestamp? dateTime;
  String? image;
  late MessageType messageType;
  OfferModel? offer;

  MessageModel({
    this.id,
    this.message,
    this.senderId,
    this.receiverId,
    this.dateTime,
    this.image,
    required this.messageType,
    this.offer,
  });

  MessageModel.fromJson(Map<String, dynamic>? json, this.id) {
    message = json!['message'];
    senderId = json['senderId'];
    receiverId = json['receiverId'];
    dateTime = json['dateTime'];
    image = json['image'];
    messageType = MessageType.values[json['messageType'] ?? 0];
    if (json['messageType'] == 2) {
      offer = OfferModel.fromJson(json['offer']);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'senderId': senderId,
      'receiverId': receiverId,
      'dateTime': dateTime,
      'image': image,
      'messageType': messageType.index,
      'offer': offer?.toMap(),
    };
  }

  // timestamp to date
  DateTime get dateTimeToDate => dateTime!.toDate();
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
