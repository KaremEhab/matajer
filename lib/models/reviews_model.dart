import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewsModel {
  final String comment;
  final Timestamp createdAt;
  final String image;
  final double rating;
  final String userId;

  ReviewsModel({
    required this.comment,
    required this.createdAt,
    required this.image,
    required this.rating,
    required this.userId,
  });

  factory ReviewsModel.fromJson(Map<String, dynamic> json) {
    return ReviewsModel(
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] ?? Timestamp.now(),
      image: json['image'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comment': comment,
      'createdAt': createdAt,
      'image': image,
      'rating': rating,
      'userId': userId,
    };
  }
}
