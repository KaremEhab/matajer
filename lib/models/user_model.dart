import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { seller, buyer, guest }

enum Gender { male, female }

enum UserActivityStatus { online, offline }

class UserModel {
  late String uId;
  String? profilePicture;
  late String username;
  late String email;
  late String phoneNumber;
  late UserType userType;
  late bool hasShop;
  late bool phoneVerified;
  late bool newProductsNotification;
  late bool commentsNotification;
  late bool reviewsNotification;
  late bool ordersNotification;
  late bool messagesNotification;
  late Timestamp accountCreatedAt;

  List<Map<String, dynamic>> shops = []; // Existing shops
  List<String> shopsVisibleToComment = []; // ✅ New field
  List<String> addresses = [];
  String currentAddress = '';

  late DateTime birthdate;
  late Gender gender;
  late int age;
  late String emirate;
  late UserActivityStatus activityStatus;

  UserModel({
    required this.uId,
    required this.username,
    required this.email,
    required this.userType,
    required this.hasShop,
    required this.phoneVerified,
    required this.accountCreatedAt,
    required this.phoneNumber,
    required this.birthdate,
    required this.gender,
    required this.age,
    required this.emirate,
    required this.activityStatus,
    required this.newProductsNotification,
    required this.commentsNotification,
    required this.reviewsNotification,
    required this.ordersNotification,
    required this.messagesNotification,
    this.profilePicture,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    uId = json['uId'];
    username = json['username'];
    email = json['email'];
    phoneNumber = json['phoneNumber'];
    userType = json['userType'] == 'seller' ? UserType.seller : UserType.buyer;
    hasShop = json['hasShop'] ?? false;
    phoneVerified = json['phoneVerified'] ?? false;
    newProductsNotification = json['newProductsNotification'] ?? false;
    commentsNotification = json['commentsNotification'] ?? false;
    reviewsNotification = json['reviewsNotification'] ?? false;
    ordersNotification = json['ordersNotification'] ?? false;
    messagesNotification = json['messagesNotification'] ?? false;

    if (json['accountCreatedAt'] is String) {
      accountCreatedAt = Timestamp.fromDate(
        DateTime.parse(json['accountCreatedAt']),
      );
    } else {
      accountCreatedAt = json['accountCreatedAt'];
    }

    if (json['birthdate'] != null) {
      if (json['birthdate'] is String) {
        birthdate = DateTime.parse(json['birthdate']);
      } else if (json['birthdate'] is Timestamp) {
        birthdate = (json['birthdate'] as Timestamp).toDate();
      }
    }

    gender = json['gender'] == 'male' ? Gender.male : Gender.female;
    age = json['age'] ?? 0;
    emirate = json['emirate'];
    profilePicture = json['profilePicture'];

    if (json['shops'] != null && json['shops'] is List) {
      shops = List<Map<String, dynamic>>.from(json['shops']);
    }

    if (json['shopsVisibleToComment'] != null &&
        json['shopsVisibleToComment'] is List) {
      shopsVisibleToComment = List<String>.from(json['shopsVisibleToComment']);
    }

    addresses = List<String>.from(json['addresses'] ?? []);
    currentAddress = json['currentAddress'] ?? '';
    activityStatus = json['activityStatus'] == 'online'
        ? UserActivityStatus.online
        : UserActivityStatus.offline;
  }

  Map<String, dynamic> toMap() {
    return {
      'uId': uId,
      'username': username,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType.name,
      'hasShop': hasShop,
      'phoneVerified': phoneVerified,
      'newProductsNotification': newProductsNotification,
      'commentsNotification': commentsNotification,
      'reviewsNotification': reviewsNotification,
      'ordersNotification': ordersNotification,
      'messagesNotification': messagesNotification,
      'accountCreatedAt': accountCreatedAt,
      'birthdate': birthdate,
      'gender': gender.name,
      'age': age,
      'emirate': emirate,
      'profilePicture': profilePicture,
      'shops': shops.map((e) => Map<String, dynamic>.from(e)).toList(),
      'shopsVisibleToComment': shopsVisibleToComment,
      'addresses': addresses,
      'currentAddress': currentAddress,
      'activityStatus': activityStatus.name,
    };
  }
}

class GuestUserModel {
  final String uId;
  final String username;
  final String email;
  final String? fcmToken;
  final UserActivityStatus activityStatus;
  final DateTime createdAt;

  GuestUserModel({
    required this.uId,
    required this.username,
    required this.email,
    required this.fcmToken,
    required this.activityStatus,
    required this.createdAt,
  });

  factory GuestUserModel.fromJson(Map<String, dynamic> json) {
    return GuestUserModel(
      uId: json['uId'],
      username: json['username'] ?? 'Guest',
      email: json['email'] ?? '',
      fcmToken: (json['fcmTokens'] as List?)?.first,
      activityStatus: json['activityStatus'] == 'online'
          ? UserActivityStatus.online
          : UserActivityStatus.offline,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uId': uId,
      'username': username,
      'email': email,
      'fcmTokens': [fcmToken],
      'activityStatus': activityStatus.name,
      'createdAt': createdAt,
      'isAnonymous': true,
    };
  }
}
