import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matajer/constants/functions.dart';

enum ShopActivityStatus { online, offline }

class ShopModel {
  late String sellerId;
  late String shopId;
  late String shopName;
  late String shopCategory;
  late String shopDescription;
  late String shopLogoUrl;
  late String shopBannerUrl;
  late num sellerLicenseNumber;
  late String sellerLicenseImageUrl;
  late String emirate;
  late Timestamp sellerCreatedAt;
  late num numberOfRating;
  late num deliveryDays;
  late num avgResponseTime;
  late num sumOfRating;
  late List<String> subcategories;
  late List<String> usersSetAsFavorite;
  late bool autoAcceptOrders;
  late ShopActivityStatus activityStatus;

  ShopModel({
    required this.sellerId,
    required this.shopId,
    required this.shopName,
    required this.shopCategory,
    required this.shopDescription,
    required this.shopLogoUrl,
    required this.shopBannerUrl,
    required this.sellerLicenseNumber,
    required this.sellerLicenseImageUrl,
    required this.emirate,
    required this.sellerCreatedAt,
    required this.numberOfRating,
    required this.sumOfRating,
    required this.deliveryDays,
    required this.avgResponseTime,
    required this.autoAcceptOrders,
    required this.activityStatus,
    required this.subcategories,
    required this.usersSetAsFavorite,
  });

  ShopModel.fromJson(Map<String, dynamic> json) {
    sellerId = json['sellerId'] ?? '';
    shopId = json['shopId'] ?? '';
    shopName = json['shopName'] ?? '';
    shopCategory = json['shopCategory'] ?? '';
    shopDescription = json['shopDescription'] ?? '';
    shopLogoUrl = json['shopLogoUrl'] ?? '';
    shopBannerUrl = json['shopBannerUrl'] ?? '';
    sellerLicenseNumber = _toNum(json['sellerLicenseNumber']);
    sellerLicenseImageUrl = json['sellerLicenseImageUrl'] ?? '';
    emirate = json['emirate'] ?? '';
    sellerCreatedAt = json['sellerCreatedAt'] is Timestamp
        ? json['sellerCreatedAt']
        : Timestamp.fromDate(DateTime.parse(json['sellerCreatedAt']));
    deliveryDays = _toNum(json['deliveryDays']);
    avgResponseTime = _toNum(json['avgResponseTime']);
    numberOfRating = _toNum(json['numberOfRating']);
    sumOfRating = _toNum(json['sumOfRating']);
    subcategories = List<String>.from(json['subcategories'] ?? []);
    usersSetAsFavorite = List<String>.from(json['usersSetAsFavorite'] ?? []);
    activityStatus = json['activityStatus'] == 'online'
        ? ShopActivityStatus.online
        : ShopActivityStatus.offline;
    autoAcceptOrders = json['autoAcceptOrders'] ?? false;
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'shopId': shopId,
      'shopName': shopName,
      'shopCategory': shopCategory,
      'shopDescription': shopDescription,
      'shopLogoUrl': shopLogoUrl,
      'shopBannerUrl': shopBannerUrl,
      'sellerLicenseNumber': sellerLicenseNumber,
      'sellerLicenseImageUrl': sellerLicenseImageUrl,
      'emirate': emirate,
      'sellerCreatedAt': sellerCreatedAt.toDate().toIso8601String(),
      'deliveryDays': deliveryDays,
      'avgResponseTime': avgResponseTime,
      'numberOfRating': numberOfRating,
      'sumOfRating': sumOfRating,
      'subcategories': subcategories,
      'usersSetAsFavorite': usersSetAsFavorite,
      'activityStatus': activityStatus.name,
      'autoAcceptOrders': autoAcceptOrders,
      'searchKeywords': generateSearchKeywords(shopName),
    };
  }

  /// Helper to safely convert string/num/null to num
  num _toNum(dynamic value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}

extension ShopModelCopyWith on ShopModel {
  ShopModel copyWith({
    String? sellerId,
    String? shopId,
    String? shopName,
    String? shopCategory,
    String? shopDescription,
    String? shopLogoUrl,
    String? shopBannerUrl,
    num? sellerLicenseNumber,
    String? sellerLicenseImageUrl,
    String? emirate,
    Timestamp? sellerCreatedAt,
    num? numberOfRating,
    num? deliveryDays,
    num? avgResponseTime,
    num? sumOfRating,
    List<String>? subcategories,
    List<String>? usersSetAsFavorite,
    bool? autoAcceptOrders,
    ShopActivityStatus? activityStatus,
  }) {
    return ShopModel(
      sellerId: sellerId ?? this.sellerId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopCategory: shopCategory ?? this.shopCategory,
      shopDescription: shopDescription ?? this.shopDescription,
      shopLogoUrl: shopLogoUrl ?? this.shopLogoUrl,
      shopBannerUrl: shopBannerUrl ?? this.shopBannerUrl,
      sellerLicenseNumber: sellerLicenseNumber ?? this.sellerLicenseNumber,
      sellerLicenseImageUrl:
          sellerLicenseImageUrl ?? this.sellerLicenseImageUrl,
      emirate: emirate ?? this.emirate,
      sellerCreatedAt: sellerCreatedAt ?? this.sellerCreatedAt,
      numberOfRating: numberOfRating ?? this.numberOfRating,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      sumOfRating: sumOfRating ?? this.sumOfRating,
      subcategories: subcategories ?? List<String>.from(this.subcategories),
      usersSetAsFavorite:
          usersSetAsFavorite ?? List<String>.from(this.usersSetAsFavorite),
      autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
      activityStatus: activityStatus ?? this.activityStatus,
    );
  }
}

extension ShopModelX on ShopModel {
  void updateFrom(ShopModel other) {
    shopName = other.shopName;
    shopCategory = other.shopCategory;
    shopDescription = other.shopDescription;
    deliveryDays = other.deliveryDays;
    avgResponseTime = other.avgResponseTime;
    sellerLicenseNumber = other.sellerLicenseNumber;
    autoAcceptOrders = other.autoAcceptOrders;
    shopLogoUrl = other.shopLogoUrl;
    shopBannerUrl = other.shopBannerUrl;
    sellerLicenseImageUrl = other.sellerLicenseImageUrl;
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:matajer/constants/functions.dart';
//
// enum ShopActivityStatus { online, offline }
//
// class ShopModel {
//   late String sellerId;
//   late String shopId;
//   late String shopName;
//   late String shopCategory;
//   late String shopDescription;
//   late String shopLogoUrl;
//   late String shopBannerUrl;
//   late num sellerLicenseNumber;
//   late String sellerLicenseImageUrl;
//   late String emirate;
//   late num numberOfRating;
//   late num deliveryDays;
//   late num avgResponseTime;
//   late num sumOfRating;
//   late List<String> subcategories;
//   late List<String> usersSetAsFavorite;
//   late bool autoAcceptOrders;
//   late ShopActivityStatus activityStatus;
//   late Timestamp? autoAcceptEnabledAt;
//   late Timestamp sellerCreatedAt;
//
//   ShopModel({
//     required this.sellerId,
//     required this.shopId,
//     required this.shopName,
//     required this.shopCategory,
//     required this.shopDescription,
//     required this.shopLogoUrl,
//     required this.shopBannerUrl,
//     required this.sellerLicenseNumber,
//     required this.sellerLicenseImageUrl,
//     required this.emirate,
//     required this.numberOfRating,
//     required this.sumOfRating,
//     required this.deliveryDays,
//     required this.avgResponseTime,
//     required this.autoAcceptOrders,
//     required this.activityStatus,
//     required this.subcategories,
//     required this.usersSetAsFavorite,
//     required this.autoAcceptEnabledAt,
//     required this.sellerCreatedAt,
//   });
//
//   ShopModel.fromJson(Map<String, dynamic> json) {
//     sellerId = json['sellerId'] ?? '';
//     shopId = json['shopId'] ?? '';
//     shopName = json['shopName'] ?? '';
//     shopCategory = json['shopCategory'] ?? '';
//     shopDescription = json['shopDescription'] ?? '';
//     shopLogoUrl = json['shopLogoUrl'] ?? '';
//     shopBannerUrl = json['shopBannerUrl'] ?? '';
//     sellerLicenseNumber = _toNum(json['sellerLicenseNumber']);
//     sellerLicenseImageUrl = json['sellerLicenseImageUrl'] ?? '';
//     emirate = json['emirate'] ?? '';
//
//     deliveryDays = _toNum(json['deliveryDays']);
//     avgResponseTime = _toNum(json['avgResponseTime']);
//     numberOfRating = _toNum(json['numberOfRating']);
//     sumOfRating = _toNum(json['sumOfRating']);
//     subcategories = List<String>.from(json['subcategories'] ?? []);
//     if (json['usersSetAsFavorite'] != null) {
//       usersSetAsFavorite = List<String>.from(json['usersSetAsFavorite'] ?? []);
//     }
//     activityStatus = json['activityStatus'] == 'online'
//         ? ShopActivityStatus.online
//         : ShopActivityStatus.offline;
//     autoAcceptOrders = json['autoAcceptOrders'] ?? false;
//
//     autoAcceptEnabledAt = json['autoAcceptEnabledAt'] is Timestamp
//         ? json['autoAcceptEnabledAt']
//         : Timestamp.fromDate(DateTime.parse(json['autoAcceptEnabledAt']));
//
//     sellerCreatedAt = json['sellerCreatedAt'] is Timestamp
//         ? json['sellerCreatedAt']
//         : Timestamp.fromDate(DateTime.parse(json['sellerCreatedAt']));
//   }
//
//   Map<String, dynamic> toMap() {
//     return {
//       'sellerId': sellerId,
//       'shopId': shopId,
//       'shopName': shopName,
//       'shopCategory': shopCategory,
//       'shopDescription': shopDescription,
//       'shopLogoUrl': shopLogoUrl,
//       'shopBannerUrl': shopBannerUrl,
//       'sellerLicenseNumber': sellerLicenseNumber,
//       'sellerLicenseImageUrl': sellerLicenseImageUrl,
//       'emirate': emirate,
//       'deliveryDays': deliveryDays,
//       'avgResponseTime': avgResponseTime,
//       'numberOfRating': numberOfRating,
//       'sumOfRating': sumOfRating,
//       'subcategories': subcategories,
//       'usersSetAsFavorite': usersSetAsFavorite,
//       'activityStatus': activityStatus.name,
//       'autoAcceptOrders': autoAcceptOrders,
//       'searchKeywords': generateSearchKeywords(shopName),
//       'autoAcceptEnabledAt': autoAcceptEnabledAt!.toDate().toIso8601String(),
//       'sellerCreatedAt': sellerCreatedAt.toDate().toIso8601String(),
//     };
//   }
//
//   /// Helper to safely convert string/num/null to num
//   num _toNum(dynamic value) {
//     if (value is num) return value;
//     if (value is String) return num.tryParse(value) ?? 0;
//     return 0;
//   }
// }
//
// extension ShopModelCopyWith on ShopModel {
//   ShopModel copyWith({
//     String? sellerId,
//     String? shopId,
//     String? shopName,
//     String? shopCategory,
//     String? shopDescription,
//     String? shopLogoUrl,
//     String? shopBannerUrl,
//     num? sellerLicenseNumber,
//     String? sellerLicenseImageUrl,
//     String? emirate,
//     num? numberOfRating,
//     num? deliveryDays,
//     num? avgResponseTime,
//     num? sumOfRating,
//     List<String>? subcategories,
//     List<String>? usersSetAsFavorite,
//     bool? autoAcceptOrders,
//     ShopActivityStatus? activityStatus,
//     Timestamp? autoAcceptEnabledAt,
//     Timestamp? sellerCreatedAt,
//   }) {
//     return ShopModel(
//       sellerId: sellerId ?? this.sellerId,
//       shopId: shopId ?? this.shopId,
//       shopName: shopName ?? this.shopName,
//       shopCategory: shopCategory ?? this.shopCategory,
//       shopDescription: shopDescription ?? this.shopDescription,
//       shopLogoUrl: shopLogoUrl ?? this.shopLogoUrl,
//       shopBannerUrl: shopBannerUrl ?? this.shopBannerUrl,
//       sellerLicenseNumber: sellerLicenseNumber ?? this.sellerLicenseNumber,
//       sellerLicenseImageUrl:
//           sellerLicenseImageUrl ?? this.sellerLicenseImageUrl,
//       emirate: emirate ?? this.emirate,
//       numberOfRating: numberOfRating ?? this.numberOfRating,
//       deliveryDays: deliveryDays ?? this.deliveryDays,
//       avgResponseTime: avgResponseTime ?? this.avgResponseTime,
//       sumOfRating: sumOfRating ?? this.sumOfRating,
//       subcategories: subcategories ?? List<String>.from(this.subcategories),
//       usersSetAsFavorite:
//           usersSetAsFavorite ?? List<String>.from(this.usersSetAsFavorite),
//       autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
//       activityStatus: activityStatus ?? this.activityStatus,
//       autoAcceptEnabledAt: autoAcceptEnabledAt ?? this.autoAcceptEnabledAt,
//       sellerCreatedAt: sellerCreatedAt ?? this.sellerCreatedAt,
//     );
//   }
// }
