import 'package:cloud_firestore/cloud_firestore.dart';

class CommentsModel {
  final String comment;
  final Timestamp createdAt;
  final double rating;
  final String userId;

  CommentsModel({
    required this.comment,
    required this.createdAt,
    required this.rating,
    required this.userId,
  });

  factory CommentsModel.fromJson(Map<String, dynamic> json) {
    return CommentsModel(
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      rating: (json['rating'] ?? 0).toDouble(),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comment': comment,
      'createdAt': createdAt,
      'rating': rating,
      'userId': userId,
    };
  }
}
