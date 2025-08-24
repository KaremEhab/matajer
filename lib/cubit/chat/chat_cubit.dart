// 3. ChatCubit logic (partial)

// chat_cubit/chat_cubit.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_state.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/chat/chat.dart';
import 'package:matajer/models/chat/message.dart';
import 'package:matajer/models/product_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum RecordingState { notRecording, recording, recordingLocked, idle }

// Map<String, dynamic> chatMessageToMap(ChatMessageModel message) {
//   return message.toMap();
// }
//
// ChatMessageModel chatMessageFromMap(Map<String, dynamic> map) {
//   return ChatMessageModel.fromJson(map);
// }

class ChatsCubit extends Cubit<ChatsStates> {
  ChatsCubit._privateConstructor() : super(ChatsInitialState());

  static final ChatsCubit _instance = ChatsCubit._privateConstructor();

  factory ChatsCubit() => _instance;

  static ChatsCubit get instance => _instance;

  final TextEditingController messageController = TextEditingController();
  bool isTextFieldEmpty = true;
  bool isTyping = false;
  Timer? typingTimer;
  List<String> selectedMessages = [];

  final _soundRecorder = FlutterSoundRecorder();
  StreamSubscription? _recordingStream;
  RecordingState _recordingState = RecordingState.notRecording;
  final List<double> _recordingSamples = [];

  RecordingState get recordingState => _recordingState;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createChatRoom({
    required String userId,
    // required String userName,
    // required String userImage,
    required String shopId,
    // required String shopName,
    // required String shopImage,
  }) async {
    final chatId = '${userId}_$shopId';
    final chatDoc = FirebaseFirestore.instance.collection('chats').doc(chatId);

    final docSnapshot = await chatDoc.get();

    if (!docSnapshot.exists) {
      await chatDoc.set({
        'chatId': chatId,
        'participants': [userId, shopId],
        'userId': userId,
        // 'userImage': userImage,
        // 'userName': userName,
        'shopId': shopId,
        // 'shopImage': shopImage,
        // 'shopName': shopName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': {},
        'lastMessageTime': FieldValue.serverTimestamp(),
        'receiverOnline': true,
        'visibleTo': [userId, shopId],
        'lastDeletedAt': {userId: null, shopId: null},
      });
    }
  }

  Future<void> sendNewTextMessage({
    required String text,
    required String chatId,
    String? senderId,
    required String receiverId,
    required String receiverName,
    required String receiverImage,
    String? senderName,
    String? senderImage,
  }) async {
    try {
      if (text.trim().isEmpty) return;
      final String messageId = const Uuid().v4();

      senderId = isSeller ? currentShopModel?.shopId : currentUserModel.uId;
      log("Now Sender Id is: $senderId");

      if (senderId == null) {
        print('❗Sender ID is null. Cannot send message.');
        return;
      }

      final message = ChatMessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        text: text.trim(),
        receiverId: receiverId,
        type: MessageType.text,
        timestamp: Timestamp.now(),
        deleteFor: [],
        isLastMessage: true,
      );

      sendMessage(message);
      print('👤 Sender: $senderId');
      print('📬 Receiver: $receiverId');

      await NotificationCubit.instance.sendNotification(
        title:
            '${currentUserModel.username} ${lang == 'en' ? "Sent you a message" : "ارسل لك رسالة"}',
        body: text.trim(),
        userId: receiverId,
        notificationType: NotificationTypes.chat,
        payload: jsonEncode({
          'type': NotificationTypes.chat.name,
          'chatId': chatId,
          'senderId': senderId,
          'receiverId': receiverId,
          'receiverName': senderName,
          'receiverImage': senderImage,
        }),
      );

      // Remove UI interactions like clear() and setTyping() when called from notification
      isTextFieldEmpty = true;

      if (chatId.isNotEmpty) {
        setTyping(false, chatId: chatId);
      }
    } catch (e, st) {
      print('❌ Error sending message: $e\n$st');
    }
  }

  void onTyping({required String chatId}) {
    if (!isTyping) {
      setTyping(true, chatId: chatId);
    }
    typingTimer?.cancel();
    typingTimer = Timer(const Duration(seconds: 2), () {
      setTyping(false, chatId: chatId);
    });
  }

  void setTyping(bool isTyping, {required String chatId}) {
    final myId = currentUserModel.uId;

    // استخرج الطرف التاني من chatId
    final ids = chatId.split('_');
    final isFirst = ids.first == myId;
    final otherId = isFirst ? ids.last : ids.first;

    // سجل حالة الكتابة لحسابي أنا
    FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      '${isSeller ? otherId : myId}_typing': isTyping,
    });
  }

  Future<void> sendMessage(ChatMessageModel message) async {
    final chatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(message.chatId);

    final lastMessage = {
      message.senderId: message.text, // sender sees nothing
      message.receiverId: message.text, // receiver sees the text
    };

    // update chat metadata
    await chatRef.set({
      'chatId': message.chatId,
      'sentBy': message.senderId,
      'lastMessage': lastMessage,
      'lastMessageSeen': false,
      'lastMessageType': 'text',
      'lastMessageTime': message.timestamp,
      'visibleTo': FieldValue.arrayUnion([message.receiverId]),
    }, SetOptions(merge: true));

    // save message
    await chatRef.collection('messages').doc(message.id).set(message.toMap());
  }

  final FlutterSoundPlayer audioPlayer = FlutterSoundPlayer();
  Map<String, bool> isPlayingMap = {};
  List<UploadingAudio> uploadingAudios = [];
  Map<String, bool> isLoadingMap = {};
  String? currentlyPlayingMessageId;
  FlutterSoundRecorder? recorder;
  bool isRecording = false;
  FlutterSoundPlayer? player;
  bool isPlaying = false;

  Future<void> initRecorderAndPlayer() async {
    recorder = FlutterSoundRecorder();
    player = FlutterSoundPlayer();
    await recorder!.openRecorder();
    await player!.openPlayer();

    // ✅ Open _audioPlayer (used for playback)
    await audioPlayer.openPlayer();
  }

  Future<String> getTempPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/temp.aac';
  }

  Future<void> startRecording() async {
    await Permission.microphone.request();
    final path = await getTempPath();
    await recorder!.startRecorder(toFile: path);
    isRecording = true;
  }

  Future<void> stopRecordingAndSend({
    required String chatId,
    required String receiverId,
  }) async {
    final path = await recorder!.stopRecorder();
    isRecording = false;

    if (path != null) {
      // Add temporary uploading message to list
      final uploading = UploadingAudio(localPath: path, progress: 0.0);

      uploadingAudios.add(uploading);

      // Upload and update progress
      final audioUrl = await uploadAudioToStorage(
        path,
        onProgress: (progress) {
          uploading.progress = progress;
        },
      );

      final tempMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: chatId,
        senderId: currentUserModel.uId,
        mediaUrl: null,
        receiverId: receiverId,
        type: MessageType.audio,
        timestamp: Timestamp.now(),
        deleteFor: [],
        isLastMessage: true,
      );

      // Add temporary message to the UI optimistically
      insertTemporaryMessage(tempMessage);

      // Upload and update progress
      // final audioUrls = await uploadAudioToStorage(
      //   path,
      //   onProgress: (progress) {
      //     uploading.progress = progress;
      //   },
      // );

      final String messageId = const Uuid().v4();

      // Replace the temp message with the real one
      final realMessage = tempMessage.copyWith(
        id: messageId,
        mediaUrl: audioUrl,
      );

      replaceMessage(tempMessage.id, realMessage);

      // setState(() {
      //   _uploadingAudios.remove(uploading);
      // });

      final message = realMessage;

      sendMessage(message);
    }
  }

  void handlePlayPause(String messageId, String audioUrl, context) async {
    final isPlaying = isPlayingMap[messageId] ?? false;

    if (currentlyPlayingMessageId != null &&
        currentlyPlayingMessageId != messageId) {
      await audioPlayer.stopPlayer();
      isPlayingMap[currentlyPlayingMessageId!] = false;
    }

    if (isPlaying) {
      await audioPlayer.stopPlayer();
      isPlayingMap[messageId] = false;
      currentlyPlayingMessageId = null;
    } else {
      try {
        isLoadingMap[messageId] = true;

        await audioPlayer.startPlayer(
          fromURI: audioUrl,
          whenFinished: () {
            isPlayingMap[messageId] = false;
            currentlyPlayingMessageId = null;
            isLoadingMap[messageId] = false;
          },
        );

        isPlayingMap[messageId] = true;
        currentlyPlayingMessageId = messageId;
        isLoadingMap[messageId] = false;
      } catch (e) {
        debugPrint('Error playing audio: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to play audio')));
        isLoadingMap[messageId] = false;
      }
    }
  }

  final List<ChatMessageModel> _uploadingMessages = [];

  void addUploadingImageMessage(ChatMessageModel message) {
    _uploadingMessages.add(message);
    emit(ChatImageMessageLoadingState(message.id));
  }

  void removeUploadingImageMessage(String id) {
    _uploadingMessages.removeWhere((m) => m.id == id);
    emit(ChatImageMessageLoadingState(id));
  }

  List<ChatMessageModel> get uploadingMessages => _uploadingMessages;

  Future<List<ChatMessageModel>> getMessagesOnce(String chatId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp') // adjust if needed
        .get();

    return snapshot.docs
        .map((doc) => ChatMessageModel.fromFirestore(doc))
        .toList();
  }

  Future<List<ChatMessageModel>> getMessagesByIds(
    String chatId,
    List<String> ids,
  ) async {
    final futures = ids.map((id) async {
      final doc = await FirebaseFirestore.instance
          .doc('chats/$chatId/messages/$id')
          .get();

      if (doc.exists) {
        return ChatMessageModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    });

    final results = await Future.wait(futures);
    return results.whereType<ChatMessageModel>().toList();
  }

  Future<void> undoDeleteMessages(
    String chatId,
    List<ChatMessageModel> messages,
    String myId,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final message in messages) {
      final ref = FirebaseFirestore.instance.doc(
        'chats/$chatId/messages/${message.id}',
      );

      final updatedList = List<String>.from(message.deleteFor);
      updatedList.remove(myId);

      batch.update(ref, {'deleteFor': updatedList});
    }

    await batch.commit();
  }

  Stream<List<ChatMessageModel>> getMessagesAfterDeletion({
    required String chatId,
    DateTime? lastDeletedAt,
  }) {
    final myId = isSeller ? currentShopModel!.shopId : currentUserModel.uId;

    Query query = FirebaseFirestore.instance
        .collection('chats/$chatId/messages')
        .orderBy('timestamp', descending: false);

    if (lastDeletedAt != null) {
      query = query.where(
        'timestamp',
        isGreaterThan: Timestamp.fromDate(lastDeletedAt),
      );
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                ChatMessageModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .where(
            (message) => !(message.deleteFor.contains(myId)),
          ) // 👈 فلترة الرسائل المحذوفة فقط
          .toList();
    });
  }

  Stream<int> getUnseenMessageCountStream(String chatId, String myId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('isSeen', isEqualTo: false)
        .where('receiverId', isEqualTo: myId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalUnseenMessagesCount(String myId) {
    return FirebaseFirestore.instance
        .collectionGroup('messages') // ✅ يجيب من كل الشاتات
        .where('receiverId', isEqualTo: myId)
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalUnseenMessagesForMultipleShops(List<String> shopIds) {
    final streams = shopIds.map(
      (shopId) => getTotalUnseenMessagesCount(shopId),
    );
    return Rx.combineLatestList<int>(
      streams,
    ).map((counts) => counts.fold(0, (a, b) => a + b));
  }

  Future<void> pickAndSendImage({
    required String chatId,
    required String receiverName,
    required String receiverImage,
    String? senderName,
    String? senderImage,
    required BuildContext context,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final String messageId = const Uuid().v4();

        // استخراج الـ sender والـ receiver بناءً على chatId
        final ids = chatId.split('_');
        final senderId = isSeller
            ? currentShopModel!.shopId
            : currentUserModel.uId;
        final receiverId = ids.first == senderId ? ids.last : ids.first;

        // Temporary uploading message
        final tempMessage = ChatMessageModel(
          id: messageId,
          chatId: chatId,
          senderId: senderId,
          receiverId: receiverId,
          mediaUrl: null,
          type: MessageType.image,
          timestamp: Timestamp.now(),
          deleteFor: [],
          isLastMessage: true,
        );

        addUploadingImageMessage(tempMessage);

        final imageUrl = await uploadImageToStorage(pickedFile, (progress) {
          uploadProgress[messageId] = progress;
          emit(ChatImageMessageLoadingState(messageId));
        });

        final sentMessage = tempMessage.copyWith(mediaUrl: imageUrl);

        // 1. Send the actual message
        sendMessage(sentMessage);
        await NotificationCubit.instance.sendNotification(
          title: '${currentUserModel.username} ${S.of(context).sent_new_image}',
          body: S.of(context).sent_new_image,
          imageUrl: imageUrl,
          userId: receiverId,
          notificationType: NotificationTypes.chat,
          payload: jsonEncode({
            'type': NotificationTypes.chat.name,
            'chatId': chatId,
            'receiverId': receiverId,
            'receiverName': receiverName, // Or wherever you get name from
            'receiverImage': receiverImage, // Same here
          }),
        );

        final lastMessage = {
          senderId: senderId, // sender sees nothing
          receiverId: senderId, // receiver sees the text
        };

        // 2. Update the chat document
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .update({
              'lastMessage': lastMessage,
              'lastMessageSeen': false,
              'lastMessageType': 'image',
              'lastMessageTime': FieldValue.serverTimestamp(),
            });

        // 3. Remove the temporary uploading state
        removeUploadingImageMessage(messageId);
      }
    } catch (e) {
      emit(ChatImageMessageErrorState(e.toString()));
    }
  }

  Future<void> sendInBackground({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    required ProductModel product,
  }) async {
    await compute(sendMessageWorker, {
      'chatId': chatId,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'product': product
          .toMap(), // pass map since isolates can’t take complex objects
    });
  }

  Future<void> sendMessageWorker(Map<String, dynamic> data) async {
    final product = ProductModel.fromJson(data['product']);
    await sendProductMentionMessage(
      chatId: data['chatId'],
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      message: data['message'],
      product: product,
    );
  }

  Future<void> sendProductMentionMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
    required ProductModel product,
  }) async {
    final String messageId = const Uuid().v4();
    final Timestamp now = Timestamp.now();

    final ChatMessageModel productMentionMessage = ChatMessageModel(
      id: messageId,
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: message,
      productMentionId: product.id,
      type: MessageType.productMention,
      timestamp: now,
      deleteFor: [],
      isLastMessage: true,
    );

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set(productMentionMessage.toMap());

    // Optionally update last message info
    await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
      'lastMessage': {
        senderId: 'Product Mention',
        receiverId: 'Product Mention',
      },
      'lastMessageTime': now,
      'sentBy': senderId,
      'lastMessageType': 'productMention',
      'lastMessageSeen': false,
    });
  }

  Future<void> sendOfferMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required ProductModel product,
    required num newPrice,
    required String description,
    required Timestamp? expireDate,
  }) async {
    try {
      emit(OfferMessageLoadingState());
      final String messageId = const Uuid().v4();
      final Timestamp now = Timestamp.now();

      final ChatMessageModel offerMessage = ChatMessageModel(
        id: messageId,
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        offer: OfferModel(
          product: product,
          newPrice: newPrice,
          description: description,
          expireDate: expireDate,
        ),
        type: MessageType.offer,
        text: "New offer is here !!",
        timestamp: now,
        deleteFor: [],
        isLastMessage: true,
      );

      // Save message in chat messages
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .set(offerMessage.toMap());

      // Update last message info in chat
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessage': {
          senderId: 'New offer is here !!',
          receiverId: 'New offer is here !!',
        },
        'lastMessageTime': now,
        'sentBy': senderId,
        'lastMessageType': 'offer',
        'lastMessageSeen': false,
      });

      // Generate a new random ID for the offer in the user's collection
      final String offerId = const Uuid().v4();

      // Save offer inside receiver's "offers" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .collection('offers')
          .doc(offerId)
          .set({
            'product': product.toMap(),
            'newPrice': newPrice,
            'description': description,
            'expireDate': expireDate,
            'chatId': chatId,
            'senderId': senderId,
            'timestamp': now,
            'status': 'sent', // optional: track if accepted, declined, pending
          });

      emit(OfferMessageSentSuccessfullyState());
    } catch (e) {
      emit(OfferMessageErrorState(e.toString()));
    }
  }

  Future<void> expireOffer({
    required String receiverId,
    required ChatMessageModel message,
  }) async {
    emit(ChatDeleteLoadingState());
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserModel.uId)
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .doc(message.id)
        .set({
          'offer': {'expireDate': Timestamp.now()},
        }, SetOptions(merge: true))
        .then((value) {
          emit(ChatDeleteSuccessState());
        })
        .catchError((error) {
          emit(ChatDeleteErrorState(error.toString()));
        });
  }

  Future<String> uploadVideoToStorage(XFile file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_videos')
        .child('${DateTime.now().millisecondsSinceEpoch}.mp4');

    await ref.putFile(File(file.path));
    return await ref.getDownloadURL();
  }

  final Map<String, double> uploadProgress = {};

  Future<String> uploadImageToStorage(
    XFile file,
    void Function(double) onProgress,
  ) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = ref.putFile(File(file.path));

    // Listen to progress
    uploadTask.snapshotEvents.listen((event) {
      final progress = event.bytesTransferred / event.totalBytes;
      onProgress(progress);
    });

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  final uploadProgressStream = StreamController<double>();

  Future<String> uploadAudioToStorage(
    String localPath, {
    Function(double)? onProgress,
  }) async {
    final file = File(localPath);
    final storageRef = FirebaseStorage.instance.ref().child(
      'chat_audios/${DateTime.now().millisecondsSinceEpoch}.aac',
    );

    final uploadTask = storageRef.putFile(file);

    uploadTask.snapshotEvents.listen((event) {
      final progress = (event.bytesTransferred / event.totalBytes);
      if (onProgress != null) {
        onProgress(progress);
      }
    });

    await uploadTask;
    return await storageRef.getDownloadURL();
  }

  final List<ChatMessageModel> _tempMessages = [];

  // final StreamController<List<ChatMessageModel>> _messageController =
  //     StreamController.broadcast();

  Stream<List<ChatMessageModel>> getMessages(
    String chatId,
    String userId,
  ) async* {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final lastDeletedAt = (chatDoc.data()?['lastDeletedAt'] ?? {})[userId];

    final baseQuery = _firestore
        .collection('chats/$chatId/messages')
        .orderBy('timestamp', descending: false);

    final query = lastDeletedAt != null
        ? baseQuery.where('timestamp', isGreaterThan: lastDeletedAt)
        : baseQuery;

    yield* query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => ChatMessageModel.fromJson(doc.data()))
          .toList(),
    );
  }

  void toggleMessageSelection(String messageId) {
    HapticFeedback.lightImpact();
    if (selectedMessages.contains(messageId)) {
      selectedMessages.remove(messageId);
    } else {
      selectedMessages.add(messageId);
    }
    emit(ChatSelectionUpdated()); // 🔥 عشان يعيد البناء
  }

  void clearSelectedMessages() {
    HapticFeedback.lightImpact();
    selectedMessages.clear();
    emit(ChatSelectionCleared()); // 🔥 برضو نحتاج نعيد البناء
  }

  Future<void> markMessagesAsSeen({
    required String chatId,
    required List<ChatMessageModel> messages,
  }) async {
    final batch = FirebaseFirestore.instance.batch();

    final myId = isSeller ? currentShopModel!.shopId : currentUserModel.uId;

    // 🛑 Check if the user (receiver) is online first
    // final chatDoc =
    // await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    // final chatData = chatDoc.data();
    //
    // if (chatData == null) return;
    //
    // final isUserOnline = chatData['${myId}_online'] == true;
    //
    // if (!isUserOnline) {
    //   print("⚠️ User is offline. Messages won't be marked as seen.");
    //   return;
    // }

    for (var message in messages) {
      if (!message.isSeen && message.senderId != myId) {
        final docRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(message.id);

        final chatDocRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId);

        batch.update(docRef, {'isSeen': true});
        batch.update(chatDocRef, {'lastMessageSeen': true});
      }
    }

    try {
      await batch.commit();
    } catch (e) {
      print('Error marking messages as seen: $e');
    }
  }

  void insertTemporaryMessage(ChatMessageModel message) {
    _tempMessages.insert(0, message);
  }

  void replaceMessage(String tempId, ChatMessageModel updatedMessage) {
    _tempMessages.removeWhere((msg) => msg.id == tempId);
    // Optional: push to Firestore here if not done already
  }

  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore.doc('chats/$chatId/messages/$messageId').delete();
  }

  Future<void> deleteMessagesForMe(
    String chatId,
    List<String> messageIds,
    String myId,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    // 1️⃣ Mark messages as deleted for me
    for (final messageId in messageIds) {
      final ref = FirebaseFirestore.instance.doc(
        'chats/$chatId/messages/$messageId',
      );

      final snapshot = await ref.get();
      if (!snapshot.exists) continue;

      final data = snapshot.data() as Map<String, dynamic>;
      final currentDeletedFor = List<String>.from(data['deleteFor'] ?? []);

      if (!currentDeletedFor.contains(myId)) {
        currentDeletedFor.add(myId);
        batch.update(ref, {'deleteFor': currentDeletedFor});
      }
    }

    await batch.commit();

    // 2️⃣ Find the latest visible message (for me only)
    final query = await FirebaseFirestore.instance
        .collection('chats/$chatId/messages')
        .orderBy('timestamp', descending: true)
        .get();

    ChatMessageModel? lastVisibleMessage;

    for (final doc in query.docs) {
      final msg = ChatMessageModel.fromFirestore(doc);
      if (!msg.deleteFor.contains(myId)) {
        lastVisibleMessage = msg;
        break;
      }
    }

    final chatRef = FirebaseFirestore.instance.doc('chats/$chatId');
    final chatSnap = await chatRef.get();
    if (!chatSnap.exists) return;

    final chatData = chatSnap.data() as Map<String, dynamic>;

    // Ensure we always have a map for lastMessage
    final Map<String, dynamic> lastMessageMap = Map<String, dynamic>.from(
      chatData['lastMessage'] ?? {},
    );

    if (lastVisibleMessage != null) {
      // 3️⃣ Update only *my* view of lastMessage
      lastMessageMap[myId] = lastVisibleMessage.text ?? 'Media';

      await chatRef.update({
        'lastMessage': lastMessageMap,
        'lastMessageType': lastVisibleMessage.type.name,
        'lastMessageTime': lastVisibleMessage.timestamp,
        'sentBy': lastVisibleMessage.senderId,
        'lastMessageSeen': lastVisibleMessage.senderId == myId ? false : true,
      });
    } else {
      // 4️⃣ No visible messages left → clear only my entry
      lastMessageMap[myId] = '';

      await chatRef.update({
        'lastMessage': lastMessageMap,
        'lastMessageType': LastMessageType.text.name,
        'lastMessageTime': Timestamp.now(),
        'sentBy': '',
        'lastMessageSeen': true,
      });
    }
  }

  Future<void> deleteChatForMe(String chatId, String userId) async {
    emit(ChatDeletedForMeLoadingState());
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);

      await chatRef.update({
        'visibleTo': FieldValue.arrayRemove([userId]),
        'lastDeletedAt.$userId': FieldValue.serverTimestamp(),
      });

      emit(ChatDeletedForMeSuccessState());
    } catch (e) {
      emit(ChatDeletedForMeErrorState(e.toString()));
    }
  }

  Future<Map<String, dynamic>?> getChatById(String chatId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();
    return snapshot.data();
  }

  Future<void> undoDeleteChat(
    String chatId,
    Map<String, dynamic>? previousChat,
    String myId,
  ) async {
    if (previousChat == null) return;

    // Just re-add myId back to visibleTo
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      ...previousChat,
      'lastDeletedAt': {myId: null},
      'visibleTo': FieldValue.arrayUnion([myId]),
    }, SetOptions(merge: true));
  }

  Future<void> togglePinChat(String chatId) async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final pinnedChats = prefs.getStringList('pinnedChats') ?? [];

    if (pinnedChats.contains(chatId)) {
      pinnedChats.remove(chatId);
    } else {
      pinnedChats.add(chatId);
    }

    await prefs.setStringList('pinnedChats', pinnedChats);
  }

  Future<List<String>> getPinnedChats() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('pinnedChats') ?? [];
  }

  // Future<void> startRecording() async {
  //   final micStatus = await Permission.microphone.request();
  //   if (!micStatus.isGranted) {
  //     print("Microphone permission not granted");
  //     return;
  //   }
  //
  //   await _soundRecorder.openRecorder();
  //
  //   final dir = await getTemporaryDirectory();
  //   final path =
  //       '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
  //
  //   await _soundRecorder.startRecorder(
  //     toFile: path,
  //     codec: Codec.aacADTS,
  //     sampleRate: 44100,
  //     bitRate: 48000,
  //   );
  //
  //   _recordingSamples.clear();
  //   _recordingStream = _soundRecorder.onProgress?.listen((event) {
  //     _recordingSamples.add(event.decibels ?? 0.0);
  //   });
  //
  //   _recordingState = RecordingState.recording;
  // }

  Future<void> onMicDragLeft(double dx, double deviceWidth) async {
    if (dx > deviceWidth * 0.6) return;

    await _soundRecorder.stopRecorder();
    _recordingStream?.cancel();
    _recordingStream = null;
    _recordingState = RecordingState.notRecording;
  }

  Future<void> onMicDragUp(double dy, double deviceHeight) async {
    if (dy > deviceHeight - 100 ||
        _recordingState == RecordingState.recordingLocked) {
      return;
    }

    // Do NOT stop the recorder here
    _recordingState = RecordingState.recordingLocked;
    print("Dragging up...");
  }

  // Future<void> stopRecordingAndSend({
  //   required String senderId,
  //   required String receiverId,
  //   required String chatId,
  // }) async {
  //   String? path;
  //
  //   try {
  //     path = await _soundRecorder.stopRecorder();
  //   } catch (e) {
  //     print("Error stopping recorder: $e");
  //     return; // Exit early if something went wrong
  //   }
  //
  //   _recordingStream?.cancel();
  //   _recordingStream = null;
  //
  //   if (path == null || !(await File(path).exists())) {
  //     print("Recording file doesn't exist");
  //     return;
  //   }
  //
  //   final recordedFile = File(path);
  //   final url = await uploadAudioToStorage(path);
  //
  //   final message = ChatMessageModel(
  //     id: DateTime.now().millisecondsSinceEpoch.toString(),
  //     senderId: senderId,
  //     receiverId: receiverId,
  //     chatId: chatId,
  //     timestamp: Timestamp.now(),
  //     type: MessageType.audio,
  //     mediaUrl: url,
  //     deleteFor: [],
  //   );
  //
  //   await sendMessage(message); // Don't forget await!
  //   _recordingSamples.clear();
  //   _recordingState = RecordingState.notRecording;
  //   print("Stopping and sending...");
  // }
  //
  void cancelRecording() async {
    await _soundRecorder.stopRecorder();
    await _soundRecorder.closeRecorder();

    _recordingStream?.cancel();
    _recordingSamples.clear();
    _recordingState = RecordingState.idle;
  }

  // Future<void> deleteChat(String chatId) async {
  //   await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();
  //
  //   // احذف كمان الرسائل المرتبطة لو محتاج:
  //   final messages =
  //       await FirebaseFirestore.instance
  //           .collection('chats')
  //           .doc(chatId)
  //           .collection('messages')
  //           .get();
  //
  //   for (var doc in messages.docs) {
  //     await doc.reference.delete();
  //   }
  // }
}

class UploadingAudio {
  final String localPath;
  double progress;

  UploadingAudio({required this.localPath, this.progress = 0.0});
}
