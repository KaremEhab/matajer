import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/generated/l10n.dart';

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
  late List<Map<String, dynamic>> deliveryOptions;
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
    required this.deliveryOptions,
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
    deliveryOptions =
        (json['deliveryOptions'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];
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
      'deliveryOptions': deliveryOptions,
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
    num? avgResponseTime,
    num? sumOfRating,
    List<String>? subcategories,
    List<String>? usersSetAsFavorite,
    bool? autoAcceptOrders,
    ShopActivityStatus? activityStatus,
    List<Map<String, dynamic>>? deliveryOptions, // ✅ الجديد
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
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
      sumOfRating: sumOfRating ?? this.sumOfRating,
      subcategories: subcategories ?? List<String>.from(this.subcategories),
      usersSetAsFavorite:
          usersSetAsFavorite ?? List<String>.from(this.usersSetAsFavorite),
      autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
      activityStatus: activityStatus ?? this.activityStatus,
      deliveryOptions:
          deliveryOptions ??
          List<Map<String, dynamic>>.from(this.deliveryOptions),
    );
  }
}

extension ShopModelX on ShopModel {
  void updateFrom(ShopModel other) {
    shopName = other.shopName;
    shopCategory = other.shopCategory;
    shopDescription = other.shopDescription;
    avgResponseTime = other.avgResponseTime;
    sellerLicenseNumber = other.sellerLicenseNumber;
    autoAcceptOrders = other.autoAcceptOrders;
    shopLogoUrl = other.shopLogoUrl;
    shopBannerUrl = other.shopBannerUrl;
    sellerLicenseImageUrl = other.sellerLicenseImageUrl;
    deliveryOptions = List<Map<String, dynamic>>.from(
      other.deliveryOptions,
    ); // ✅ الجديد
  }
}

extension ShopModelFormatting on ShopModel {
  String get formattedAvgResponseTime {
    double ms = avgResponseTime.toDouble();
    Duration duration = Duration(milliseconds: ms.round());

    if (duration.inSeconds < 60) {
      return '${duration.inSeconds} ${S.current.second(duration.inSeconds)}';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} ${S.current.minute(duration.inMinutes)}';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} ${S.current.hour(duration.inHours)}';
    } else if (duration.inDays < 7) {
      return '${duration.inDays} ${S.current.day(duration.inDays)}';
    } else if (duration.inDays < 30) {
      int weeks = (duration.inDays / 7).floor();
      return '$weeks ${S.current.week(weeks)}';
    } else {
      int months = (duration.inDays / 30).floor();
      return '$months ${S.current.month(months)}';
    }
  }
}
