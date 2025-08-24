import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/new_chat/reciver_model.dart';
import 'chat_states.dart';
import 'message_model.dart';

class ChatCubit extends Cubit<ChatStates> {
  ChatCubit() : super(ChatInitialState());

  static ChatCubit get(context) => BlocProvider.of(context);

  List<ReciverModel> chatUsers = [];

  Future<void> getChatUsers() async {
    emit(ChatGetUsersLoadingState());
    try {
      final value = await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('chats')
          .orderBy('lastMessageDate', descending: true)
          .get();

      List<ReciverModel> pinnedChats = [];
      List<ReciverModel> unpinnedChats = [];

      for (var element in value.docs) {
        if (element.id != uId) {
          if (element.data()['pinned'] != null &&
              element.data()['pinned'] == true) {
            pinnedChats.add(
              ReciverModel.fromJson(element.data(), element.id, true),
            );
          } else {
            unpinnedChats.add(
              ReciverModel.fromJson(element.data(), element.id, false),
            );
          }
        }
      }

      chatUsers = [...pinnedChats, ...unpinnedChats];
      emit(ChatGetUsersSuccessState());
    } catch (error) {
      emit(ChatGetUsersErrorState(error.toString()));
    }
  }

  Future<void> registerChat({
    required ReciverModel receiver,
    required Timestamp dateTime,
    required String message,
  }) async {
    emit(ChatRegisterLoadingState());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(receiver.uId)
        .collection('chats')
        .doc(uId)
        .set({
          'uId': uId,
          'username': currentUserModel.username,
          'imageUrl': currentUserModel.profilePicture,
          'lastMessageDate': dateTime,
          'lastMessage': message,
        })
        .then((value) {
          emit(ChatRegisterSuccessState());
        })
        .catchError((error) {
          emit(ChatRegisterErrorState(error.toString()));
        });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uId)
        .collection('chats')
        .doc(receiver.uId)
        .set({
          'uId': receiver.uId,
          'username': receiver.username,
          'imageUrl': receiver.imageUrl,
          'lastMessageDate': dateTime,
          'lastMessage': message,
        })
        .then((value) {
          emit(ChatRegisterSuccessState());
        })
        .catchError((error) {
          emit(ChatRegisterErrorState(error.toString()));
        });
  }

  Future<void> pinChat({required ReciverModel receiver}) async {
    emit(ChatPinLoadingState());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uId)
        .collection('chats')
        .doc(receiver.uId)
        .set({'pinned': true}, SetOptions(merge: true))
        .then((value) {
          getChatUsers();
          emit(ChatPinSuccessState());
        })
        .catchError((error) {
          emit(ChatPinErrorState(error.toString()));
        });
  }

  Future<void> unPinChat({required ReciverModel receiver}) async {
    emit(ChatPinLoadingState());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uId)
        .collection('chats')
        .doc(receiver.uId)
        .set({'pinned': false}, SetOptions(merge: true))
        .then((value) {
          getChatUsers();
          emit(ChatPinSuccessState());
        })
        .catchError((error) {
          emit(ChatPinErrorState(error.toString()));
        });
  }

  Future<void> sendMessage({
    required String message,
    required BuildContext context,
    required ReciverModel receiver,
    required MessageType messageType,
  }) async {
    emit(ChatSendMessageLoadingState());
    Timestamp dateTime = Timestamp.now();
    try {
      await registerChat(
        receiver: receiver,
        dateTime: dateTime,
        message: message,
      );

      MessageModel messageModel = MessageModel(
        message: message,
        senderId: uId,
        receiverId: receiver.uId,
        dateTime: dateTime,
        messageType: messageType,
      );

      await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(receiver.uId)
            .collection('chats')
            .doc(uId)
            .collection('messages')
            .add(messageModel.toMap()),
        FirebaseFirestore.instance
            .collection('users')
            .doc(uId)
            .collection('chats')
            .doc(receiver.uId)
            .collection('messages')
            .add(messageModel.toMap()),
      ]);
      emit(ChatSendMessageSuccessState());
      await sendNotification(
        title: '${currentUserModel.username} ${S.of(context).sent_you_message}',
        body: message,
        uId: receiver.uId,
      );
    } catch (e) {
      emit(ChatSendMessageErrorState(e.toString()));
    }
  }

  Future<void> sendOffer({
    required ProductModel product,
    required String description,
    required num newPrice,
    Timestamp? expireDate,
    required ReciverModel receiver,
    required MessageType messageType,
  }) async {
    emit(ChatSendMessageLoadingState());
    Timestamp dateTime = Timestamp.now();
    try {
      await registerChat(
        receiver: receiver,
        dateTime: dateTime,
        message: 'New Offer Available',
      );

      MessageModel messageModel = MessageModel(
        message: 'New Offer Available',
        senderId: uId,
        receiverId: receiver.uId,
        dateTime: dateTime,
        messageType: messageType,
        offer: OfferModel(
          product: product,
          description: description,
          newPrice: newPrice,
          expireDate: expireDate,
        ),
      );

      await Future.wait([
        FirebaseFirestore.instance
            .collection('users')
            .doc(receiver.uId)
            .collection('chats')
            .doc(uId)
            .collection('messages')
            .add(messageModel.toMap()),
        FirebaseFirestore.instance
            .collection('users')
            .doc(uId)
            .collection('chats')
            .doc(receiver.uId)
            .collection('messages')
            .add(messageModel.toMap()),
      ]);
      emit(ChatSendMessageSuccessState());
      await sendNotification(
        title: '${currentUserModel.username} sent you a message',
        body: 'New Offer Available',
        uId: receiver.uId,
      );
    } catch (e) {
      emit(ChatSendMessageErrorState(e.toString()));
    }
  }

  File? image;

  void pickPhoto({
    required ImageSource source,
    required ReciverModel receiverId,
  }) {
    ImagePicker()
        .pickImage(source: source)
        .then((value) {
          image = File(value!.path);
          uploadImage(receiverId);
        })
        .catchError((error) {
          emit(SelectImageErrorState(error.toString()));
        });
  }

  Future<void> uploadImage(ReciverModel receiverId) async {
    emit(UploadImageLoadingState());
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseStorage.instance
        .ref()
        .child('chats/$fileName')
        .putFile(image!)
        .then((value) {
          value.ref
              .getDownloadURL()
              .then((value) {
                sendImage(receiverId, value);
              })
              .catchError((error) {
                emit(UploadImageErrorState(error.toString()));
              });
        })
        .catchError((error) {
          emit(UploadImageErrorState(error.toString()));
        });
  }

  Future<void> sendImage(ReciverModel receiver, String imageUrl) async {
    emit(ChatSendMessageLoadingState());

    Timestamp dateTime = Timestamp.now();

    await registerChat(
      receiver: receiver,
      dateTime: dateTime,
      message: imageUrl,
    );

    MessageModel messageModel = MessageModel(
      message: imageUrl,
      senderId: uId,
      receiverId: receiver.uId,
      dateTime: dateTime,
      messageType: MessageType.image,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(receiver.uId)
        .collection('chats')
        .doc(uId)
        .collection('messages')
        .add(messageModel.toMap())
        .then((value) async {
          emit(ChatSendMessageSuccessState());
          await sendNotification(
            title: '${currentUserModel.username} sent you a message',
            body: 'New Image',
            uId: receiver.uId,
          );
        })
        .catchError((error) {
          emit(ChatSendMessageErrorState(error.toString()));
        });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uId)
        .collection('chats')
        .doc(receiver.uId)
        .collection('messages')
        .add(messageModel.toMap())
        .then((value) {
          emit(ChatSendMessageSuccessState());
        })
        .catchError((error) {
          emit(ChatSendMessageErrorState(error.toString()));
        });
  }

  final Dio _dio = Dio();

  static const _fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/matajr-40a00/messages:send';

  Future<void> sendNotification({
    required String title,
    required String body,
    required String uId,
    String? payload,
  }) async {
    emit(SendNotificationLoadingState());

    try {
      // 1. Get fcmTokens from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .get();

      final data = snapshot.data();
      if (data == null || data['fcmTokens'] == null) {
        emit(SendNotificationErrorState('No tokens found for user'));
        return;
      }

      final List<String> fcmTokens = List<String>.from(
        data['fcmTokens'],
      ).toSet().toList(); // Remove duplicates

      // 2. Send notification to each token
      for (final token in fcmTokens) {
        try {
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
                "notification": {"title": title, "body": body},
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

  Future<void> deleteChat({required ReciverModel receiver}) async {
    emit(ChatDeleteLoadingState());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uId)
        .collection('chats')
        .doc(receiver.uId)
        .delete()
        .then((value) {
          getChatUsers();
          emit(ChatDeleteSuccessState());
        })
        .catchError((error) {
          emit(ChatDeleteErrorState(error.toString()));
        });
  }

  Future<void> expireOffer({
    required String receiverId,
    required MessageModel message,
  }) async {
    emit(ChatDeleteLoadingState());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uId)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .doc(message.id)
        .set({
          'offer': {'expireDate': Timestamp.now()},
        }, SetOptions(merge: true))
        .then((value) {
          getChatUsers();
          emit(ChatDeleteSuccessState());
        })
        .catchError((error) {
          emit(ChatDeleteErrorState(error.toString()));
        });
  }

  // Future<ReciverModel?> getReciverData(String reciverId) async {
  //   emit(ChatGetReciverDataLoadingState());
  //   ReciverModel reciverModel;
  //   await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(reciverId)
  //       .get()
  //       .then((value) {
  //     reciverModel = ReciverModel.fromJson(value.data(), value.id);
  //     emit(ChatGetReciverDataSuccessState());
  //     return reciverModel;
  //   }).catchError((error) {
  //     emit(ChatGetReciverDataErrorState(error.toString()));
  //   });
  //   return null;
  // }
}
