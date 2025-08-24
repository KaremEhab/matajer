import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matajer/constants/vars.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final NotificationTypes notificationType;
  final Timestamp createdAt;
  final Map<String, dynamic> payload;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.notificationType,
    required this.createdAt,
    required this.payload,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] ?? false,
      notificationType: NotificationTypes.values.firstWhere(
        (e) => e.name == json['notificationType'],
        orElse: () => NotificationTypes.comment,
      ),
      createdAt: (json['createdAt'] ?? Timestamp.now()) as Timestamp,
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'isRead': isRead,
      'notificationType': notificationType.name,
      'createdAt': createdAt,
      'payload': payload,
    };
  }

  /// Allows cloning with updated fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    NotificationTypes? notificationType,
    Timestamp? createdAt,
    Map<String, dynamic>? payload,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      notificationType: notificationType ?? this.notificationType,
      createdAt: createdAt ?? this.createdAt,
      payload: payload ?? this.payload,
    );
  }
}
