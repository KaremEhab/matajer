import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  late String id;
  late String shopId;
  late String title;
  late String description;
  late num price;
  late int discount;
  late num quantity;
  late String productCategory;
  late String sellerCategory;
  late String fullCategory; // ✅ Added fullCategory
  List<ProductSpecificationModel> specifications = [];
  List<String> images = [];
  List<String> searchKeywords = [];
  late String sellerId;
  late String shopName;
  late String sellerPhone;
  late String shopLogo;
  late num sumOfRating;
  late num numberOfRating;
  late num clicks;
  late DateTime createdAt;

  ProductModel({
    required this.id,
    required this.shopId,
    required this.title,
    required this.description,
    required this.price,
    required this.discount,
    required this.quantity,
    required this.sellerId,
    required this.shopName,
    required this.sellerPhone,
    required this.shopLogo,
    this.images = const [],
    this.searchKeywords = const [],
    this.sumOfRating = 0,
    this.numberOfRating = 0,
    this.clicks = 0,
    required this.specifications,
    required this.productCategory,
    required this.sellerCategory,
    required this.fullCategory, // ✅ Initialize fullCategory
    required this.createdAt,
  });

  ProductModel copyWith({
    String? id,
    String? shopId,
    String? title,
    String? description,
    num? price,
    int? discount,
    num? quantity,
    String? productCategory,
    String? sellerCategory,
    String? fullCategory,
    List<ProductSpecificationModel>? specifications,
    List<String>? images,
    List<String>? searchKeywords,
    String? sellerId,
    String? shopName,
    String? sellerPhone,
    String? shopLogo,
    num? sumOfRating,
    num? numberOfRating,
    num? clicks,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      quantity: quantity ?? this.quantity,
      sellerId: sellerId ?? this.sellerId,
      shopName: shopName ?? this.shopName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      shopLogo: shopLogo ?? this.shopLogo,
      images: images ?? List.from(this.images),
      searchKeywords: searchKeywords ?? List.from(this.searchKeywords),
      sumOfRating: sumOfRating ?? this.sumOfRating,
      numberOfRating: numberOfRating ?? this.numberOfRating,
      clicks: clicks ?? this.clicks,
      specifications: specifications ?? List.from(this.specifications),
      productCategory: productCategory ?? this.productCategory,
      sellerCategory: sellerCategory ?? this.sellerCategory,
      fullCategory: fullCategory ?? this.fullCategory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  ProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? '';
    shopId = json['shopId'] ?? '';
    title = json['title'] ?? '';
    description = json['description'] ?? '';
    // ✅ Force conversion to double
    price = (json['price'] is int)
        ? (json['price'] as int).toDouble()
        : (json['price'] is double)
        ? json['price']
        : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
    discount = json['discount'] ?? 0;
    quantity = json['quantity'] ?? 0;
    sellerId = json['sellerId'] ?? '';
    shopName = json['sellerName'] ?? '';
    sellerPhone = json['sellerPhone'] ?? '';
    shopLogo = json['sellerLogo'] ?? '';
    numberOfRating = json['numberOfRating'] ?? 0;
    sumOfRating = json['sumOfRating'] ?? 0;
    clicks = json['clicks'] ?? 0;
    images =
        (json['images'] as List<dynamic>?)
            ?.whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        [];

    searchKeywords =
        (json['searchKeywords'] as List<dynamic>?)
            ?.whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        [];

    if (json['specifications'] != null) {
      specifications = [];
      json['specifications'].forEach((v) {
        specifications.add(ProductSpecificationModel.fromJson(v));
      });
    }

    productCategory = json['productCategory'] ?? '';
    sellerCategory = json['sellerCategory'] ?? '';
    fullCategory =
        json['fullCategory'] ??
        '$sellerCategory > $productCategory'; // ✅ Fallback logic
    createdAt = json['createdAt'] == null
        ? DateTime.now()
        : (json['createdAt'] is Timestamp
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt']));
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'title': title,
      'description': description,
      'price': price,
      'discount': discount,
      'quantity': quantity,
      'images': images,
      'specifications': specifications.map((e) => e.toMap()).toList(),
      'sellerId': sellerId,
      'sellerName': shopName,
      'sellerPhone': sellerPhone,
      'sellerLogo': shopLogo,
      'numberOfRating': numberOfRating,
      'sumOfRating': sumOfRating,
      'clicks': clicks,
      'productCategory': productCategory,
      'sellerCategory': sellerCategory,
      'fullCategory': fullCategory,
      'createdAt': createdAt.toIso8601String(),
      'searchKeywords': searchKeywords, // ✅ ADD THIS
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'title': title,
      'description': description,
      'price': price,
      'discount': discount,
      'quantity': quantity,
      'images': images,
      'specifications': specifications.map((e) => e.toMap()).toList(),
      'sellerId': sellerId,
      'sellerName': shopName,
      'sellerPhone': sellerPhone,
      'sellerLogo': shopLogo,
      'numberOfRating': numberOfRating,
      'sumOfRating': sumOfRating,
      'clicks': clicks,
      'productCategory': productCategory,
      'sellerCategory': sellerCategory,
      'fullCategory': fullCategory, // ✅ Include in toJson
      'createdAt': createdAt.toIso8601String(),
      'searchKeywords': searchKeywords,
    };
  }
}

class ProductSpecificationModel {
  late String title;
  List<ProductSpecificationValueModel> subTitles = [];

  ProductSpecificationModel({required this.title, this.subTitles = const []});

  ProductSpecificationModel.fromJson(Map<String, dynamic> json) {
    title = json['title'] ?? '';
    subTitles = [];
    if (json['subTitle'] != null) {
      json['subTitle'].forEach((v) {
        subTitles.add(ProductSpecificationValueModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subTitle': subTitles.map((e) => e.toMap()).toList(),
    };
  }
}

class ProductSpecificationValueModel {
  late String title;
  late num price;

  ProductSpecificationValueModel({required this.title, required this.price});

  ProductSpecificationValueModel.fromJson(Map<String, dynamic> json) {
    title = json['title'] ?? '';
    price = (json['price'] is int)
        ? (json['price'] as int).toDouble()
        : (json['price'] is double)
        ? json['price']
        : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0;
  }

  Map<String, dynamic> toMap() {
    return {'title': title, 'price': price};
  }
}
