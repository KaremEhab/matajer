import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/models/notification_model.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit._privateConstructor() : super(NotificationInitialState());

  static final NotificationCubit _instance =
      NotificationCubit._privateConstructor();

  factory NotificationCubit() => _instance;

  static NotificationCubit get instance => _instance;

  Future<void> createNotification({
    required String receiverId,
    required String title,
    required String body,
    required String receiverType, // "user" or "shop"
    required NotificationTypes type,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final notification = {
        'receiverId': receiverId,
        'title': title,
        'body': body,
        'isRead': false,
        'notificationType': type.name,
        'payload': payload ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 📂 Choose collection based on receiverType
      final parentCollection = receiverType.toLowerCase() == 'user'
          ? 'users'
          : 'shops';

      await FirebaseFirestore.instance
          .collection(parentCollection)
          .doc(receiverId)
          .collection('notifications')
          .add(notification);

      log("✅ Notification created successfully for $receiverType $receiverId");
    } catch (e) {
      log("❌ Error creating notification: $e");
    }
  }

  List<NotificationModel> notifications = [];

  Future<void> getNotifications({
    required String receiverId,
    required String receiverType, // "user" or "shop"
  }) async {
    notifications = [];
    emit(NotificationGetNotificationsLoadingState());

    try {
      final parentCollection = receiverType.toLowerCase() == 'user'
          ? 'users'
          : 'shops';

      final docs = await FirebaseFirestore.instance
          .collection(parentCollection)
          .doc(receiverId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      notifications = docs.docs
          .map(
            (doc) => NotificationModel.fromJson({...doc.data(), 'id': doc.id}),
          )
          .toList();

      emit(NotificationGetNotificationsSuccessState());
    } catch (e) {
      log("❌ Error getting notifications: $e");
      emit(NotificationGetNotificationsErrorState(e.toString()));
    }
  }

  Future<void> markNotificationAsRead({
    required String receiverId,
    required String receiverType, // "user" or "shop"
    required String notificationId,
    required List<NotificationModel> localNotifications,
    required void Function(List<NotificationModel>) updateLocalList,
  }) async {
    try {
      final parentCollection = receiverType.toLowerCase() == 'user'
          ? 'users'
          : 'shops';

      // Update Firestore
      await FirebaseFirestore.instance
          .collection(parentCollection)
          .doc(receiverId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update locally
      final updatedList = localNotifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      updateLocalList(updatedList);

      log(
        "✅ Notification $notificationId marked as read for $receiverType $receiverId",
      );
    } catch (e) {
      log("❌ Error marking notification as read: $e");
    }
  }

  final Dio _dio = Dio();

  static const _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/matajr-40a00/messages:send';

  Future<void> sendNotification({
    required String title,
    required String body,
    required String userId,
    required NotificationTypes notificationType,
    String? imageUrl,
    String? payload,
  }) async {
    emit(SendNotificationLoadingState());

    try {
      if (userId ==
          (isSeller ? currentShopModel?.shopId : currentUserModel.uId)) {
        log('🛑 Skipping notification: trying to send to self');
        return;
      }

      // 👇 Try getting user first
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(userId)
          .get();

      Map<String, dynamic>? data = snapshot.data();

      bool newProductsNotification = false;
      bool commentsNotification = false;
      bool reviewsNotification = false;
      bool ordersNotification = false;
      bool messagesNotification = false;

      if (data != null) {
        newProductsNotification = data['newProductsNotification'];
        commentsNotification = data['commentsNotification'];
        reviewsNotification = data['reviewsNotification'];
        ordersNotification = data['ordersNotification'];
        messagesNotification = data['messagesNotification'];
      }

      // 👇 If not found in users, try shops
      if (data == null || data['fcmTokens'] == null) {
        snapshot = await FirebaseFirestore.instance
            .collection('shops')
            .doc(userId)
            .get();
        data = snapshot.data();

        Map<String, dynamic>? userData = snapshot.data();

        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(data!['sellerId'])
                .get();
        userData = userSnapshot.data();

        newProductsNotification = userData!['newProductsNotification'];
        commentsNotification = userData['commentsNotification'];
        reviewsNotification = userData['reviewsNotification'];
        ordersNotification = userData['ordersNotification'];
        messagesNotification = userData['messagesNotification'];

        log(
          '🔕🔕🔕 Product notification: ${userData['newProductsNotification']}',
        );
        log('🔕🔕🔕 Comment notification: ${userData['commentsNotification']}');
        log('🔕🔕🔕 Review notification: ${userData['reviewsNotification']}');
        log('🔕🔕🔕 Order notification: ${userData['ordersNotification']}');
        log('🔕🔕🔕 Chat notification: ${userData['messagesNotification']}');
      }

      // ❌ Exit if still not found
      if (data['fcmTokens'] == null) {
        emit(SendNotificationErrorState('No tokens found for user/shop'));
        return;
      }

      // ✅ Check if messagesNotification is enabled
      if (newProductsNotification == false &&
          notificationType == NotificationTypes.newProduct) {
        log('🔕 Skipping notification: newProductsNotification is false');
        return;
      }
      if (commentsNotification == false &&
          notificationType == NotificationTypes.comment) {
        log('🔕 Skipping notification: commentsNotification is false');
        return;
      }
      if (reviewsNotification == false &&
          notificationType == NotificationTypes.review) {
        log('🔕 Skipping notification: reviewsNotification is false');
        return;
      }
      if (ordersNotification == false &&
          notificationType == NotificationTypes.newOrder) {
        log('🔕 Skipping notification: ordersNotification is false');
        return;
      }
      if (messagesNotification == false &&
          notificationType == NotificationTypes.chat) {
        log('🔕 Skipping notification: messagesNotification is false');
        return;
      }

      final List<String> fcmTokens = List<String>.from(
        data['fcmTokens'],
      ).toSet().toList();

      log(
        "📤 Sending notification from [Sender: $fcmDeviceToken] → [Receiver: ${fcmTokens.first}]",
      );

      for (final token in fcmTokens) {
        try {

          log(
            "📤 Sending notification from [Sender: $fcmDeviceToken] → [Receiver: $token]",
          );

          final response = await _dio.post(
            _fcmEndpoint,
            options: Options(
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
              },
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
            data: {
              "message": {
                "token": token,
                "notification": {
                  "title": title,
                  "body": body,
                  if (imageUrl != null) "image": imageUrl,
                },
                if (payload != null) "data": {"payload": payload},
              },
            },
          );

          log("✅ Notification sent to $token: ${response.statusCode}");
        } catch (e) {
          log("⚠️ Error sending to $token: $e");
        }
      }

      emit(SendNotificationSuccessState());
    } catch (e, stackTrace) {
      log('❌ sendNotification Error: $e\n$stackTrace');
      emit(SendNotificationErrorState(e.toString()));
    }
  }
}
