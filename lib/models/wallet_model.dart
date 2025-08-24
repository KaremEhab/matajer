import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletTypes { order, offer, withdrawal }

class WalletModel {
  late String id;
  late Timestamp createdAt;
  late String title;
  late String shopId;
  late WalletTypes walletTypes;
  late num amount;

  WalletModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.shopId,
    required this.walletTypes,
    required this.amount,
  });

  WalletModel.fromJson(Map<String, dynamic> json, this.id) {
    createdAt = json['createdAt'];
    title = json['title'];
    shopId = json['shopId'];
    walletTypes = WalletTypes.values.firstWhere(
      (e) => e.name == json['walletTypes'],
      orElse: () => WalletTypes.order,
    );
    amount = json['amount'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'title': title,
      'shopId': shopId,
      'walletTypes': walletTypes.name,
      'amount': amount,
    };
  }
}
