import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matajer/models/cart_product_item_model.dart';

enum OrderStatus { pending, accepted, rejected, shipped, delivered }

class OrderModel {
  late String id;
  late String buyerId;
  late String buyerName;
  late String buyerPhone;
  late String buyerAddress;
  late String sellerId;
  late String shopId;
  late String sellerName;
  late String sellerPhone;
  late OrderStatus orderStatus;
  late Map<String, dynamic> paypal;
  List<CartProductItemModel> products = [];
  late num deliveryTime;
  late num price;
  late Timestamp createdAt;
  bool isRated = false;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.sellerId,
    required this.shopId,
    required this.sellerName,
    required this.sellerPhone,
    required this.orderStatus,
    required this.products,
    required this.deliveryTime,
    required this.price,
    required this.createdAt,
  });

  OrderModel.fromJson(Map<String, dynamic> json, this.id) {
    buyerId = json['buyerId'];
    buyerName = json['buyerName'];
    buyerPhone = json['buyerPhone'];
    buyerAddress = json['buyerAddress'];
    sellerId = json['sellerId'];
    shopId = json['shopId'];
    sellerName = json['sellerName'];
    sellerPhone = json['sellerPhone'];
    orderStatus = OrderStatus.values[json['orderStatus']];
    paypal = json['paypal'] ?? {};
    price = json['price'];
    deliveryTime = json['deliveryTime'];
    createdAt = Timestamp.fromDate(DateTime.parse(json['createdAt']));
    isRated = json['isRated'] ?? false;

    if (json['products'] != null) {
      for (var product in json['products']) {
        products.add(
          CartProductItemModel.fromJson(
            product,
            product['product']['id'], // ✅ fix here
          ),
        );
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, // ✅ Add this line
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'sellerId': sellerId,
      'shopId': shopId,
      'sellerName': sellerName,
      'sellerPhone': sellerPhone,
      'orderStatus': orderStatus.index,
      'products': products.map((e) => e.toMap()).toList(),
      'deliveryTime': deliveryTime,
      'price': price,
      'createdAt': createdAt.toDate().toIso8601String(),
      'isRated': isRated,
    };
  }
}

extension OrderStatusParser on OrderStatus {
  static OrderStatus? fromString(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'accepted':
        return OrderStatus.accepted;
      case 'rejected':
        return OrderStatus.rejected;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      default:
        return null; // or throw ArgumentError('Invalid OrderStatus: $status');
    }
  }

  String get name => toString().split('.').last;
}
