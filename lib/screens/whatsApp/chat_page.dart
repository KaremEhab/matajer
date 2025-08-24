import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/chat/message.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/screens/whatsApp/widgets/chat_details/chat_detail_appBar.dart';
import 'package:matajer/screens/whatsApp/widgets/chat_details/chat_detail_input.dart';
import 'package:matajer/screens/whatsApp/widgets/messages/chat_messages_widget.dart';

class ChatDetailPage extends StatefulWidget {
  final String chatId;
  final bool? isFromNotification;
  final bool clearSendMessage;
  final String? receiverName;
  final String? receiverImage;
  final String? senderName;
  final String? senderImage;
  final String receiverId;
  final String? senderId;
  final DateTime? lastDeletedAt;

  const ChatDetailPage({
    super.key,
    required this.chatId,
    this.isFromNotification = false,
    this.clearSendMessage = false,
    this.receiverName,
    this.receiverImage,
    this.senderName,
    this.senderImage,
    this.senderId,
    this.lastDeletedAt,
    required this.receiverId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage>
    with WidgetsBindingObserver {
  final TextEditingController messageController = TextEditingController();
  final ValueNotifier<bool> isTextEmpty = ValueNotifier(true);
  final GlobalKey<LayoutState> layoutKey = GlobalKey<LayoutState>();
  final FocusNode focusNode = FocusNode();
  Timer? _typingTimer;
  Stream<List<ChatMessageModel>>? messageStream;
  StreamSubscription<List<ChatMessageModel>>? _messageSubscription;
  StreamSubscription<DocumentSnapshot>? _chatDocSubscription;
  late final ChatsCubit chatCubit;
  String? myId;
  late String otherId;

  Future<void>? _initFuture; // 👈 track initialization

  @override
  void initState() {
    super.initState();
    chatCubit = ChatsCubit.instance;
    chatCubit.initRecorderAndPlayer();

    _initFuture = _initialize(); // start async init
  }

  Future<void> _initialize() async {
    log("ReceiverId: ${widget.receiverId}");
    log("SenderId: ${widget.senderId}");

    if (widget.isFromNotification == true &&
        widget.senderId != null &&
        widget.senderId != uId) {
      log("isSeller: $isSeller");

      // Wait for shop model to load
      await UserCubit.get(context).getShopById(widget.senderId!);
      isSeller = true;
    }

    // Now it's safe to assign myId
    myId = isSeller ? currentShopModel!.shopId : currentUserModel.uId;

    final ids = widget.chatId.split('_');
    otherId = ids.first == myId ? ids.last : ids.first;

    // build stream
    messageStream = chatCubit.getMessagesAfterDeletion(
      chatId: widget.chatId,
      lastDeletedAt: widget.lastDeletedAt,
    );

    // Listen for online/seen updates
    _chatDocSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .snapshots()
        .listen(_handleChatDoc);

    _messageSubscription = messageStream!.listen(_handleMessages);

    messageController.addListener(_handleTyping);

    WidgetsBinding.instance.addObserver(this);
  }

  // handlers...
  void _handleChatDoc(DocumentSnapshot doc) async {
    if (!shopStatus) return;
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;

    final isOnlineNow = data['${myId}_online'] == true;
    final isInChatPage =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    if (isOnlineNow && isInChatPage) {
      final allMessages = await chatCubit.getMessagesOnce(widget.chatId);
      final unseenMessages = allMessages
          .where((m) => !m.isSeen && m.receiverId == myId && m.senderId != myId)
          .toList();

      if (unseenMessages.isNotEmpty) {
        chatCubit.markMessagesAsSeen(
          chatId: widget.chatId,
          messages: unseenMessages,
        );
      }
    }
  }

  void _handleMessages(List<ChatMessageModel> messages) {
    final unseenMessages = messages
        .where((m) => !m.isSeen && m.receiverId == myId && m.senderId != myId)
        .toList();

    if (unseenMessages.isNotEmpty) {
      chatCubit.markMessagesAsSeen(
        chatId: widget.chatId,
        messages: unseenMessages,
      );
    }
  }

  void _handleTyping() {
    final text = messageController.text.trim();
    isTextEmpty.value = text.isEmpty;

    _typingTimer?.cancel();
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      '${myId}_typing': true,
    });

    _typingTimer = Timer(const Duration(seconds: 1), () {
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
        '${myId}_typing': false,
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingTimer?.cancel();
    _messageSubscription?.cancel();
    _chatDocSubscription?.cancel();
    messageController.dispose();
    isTextEmpty.dispose();
    chatCubit.setTyping(false, chatId: widget.chatId);

    chatCubit.recorder?.closeRecorder();
    chatCubit.player?.closePlayer();
    chatCubit.audioPlayer.closePlayer();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.clearSendMessage) {
          Navigator.of(context).pop(); // first pop
          Navigator.of(context).pop(); // second pop
          return false; // stop further pop since we already handled it
        }
        return true; // normal back
      },
      child: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text("Error loading chat: ${snapshot.error}"),
              ),
            );
          }

          return Scaffold(
            appBar: ChatDetailAppBar(
              chatId: widget.chatId,
              receiverId: widget.receiverId,
              receiverImage: widget.receiverImage!,
              receiverName: widget.receiverName!,
              isFromNotification: widget.isFromNotification,
              clearSendMessage: widget.clearSendMessage,
              senderId: widget.senderId,
            ),
            body: ChatMessagesWidget(
              receiverName: widget.receiverName!,
              receiverImage: widget.receiverImage!,
              messageStream: messageStream!,
              chatId: widget.chatId,
              receiverId: widget.isFromNotification!
                  ? widget.senderId!
                  : widget.receiverId,
            ),
            bottomNavigationBar: ChatDetailInput(
              messageController: messageController,
              isTextEmpty: isTextEmpty,
              chatId: widget.chatId,
              receiverId: widget.receiverId,
              receiverName: widget.receiverName!,
              receiverImage: widget.receiverImage!,
              senderName: widget.senderName ?? "",
              senderImage: widget.senderImage ?? "",
              focusNode: focusNode,
              onSend: _handleSendMessage,
              onDeleteSelectedMessages: handleDeleteSelectedMessages,
            ),
          );
        },
      ),
    );
  }

  void _handleSendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    chatCubit.sendNewTextMessage(
      text: text,
      chatId: widget.chatId,
      senderId: widget.isFromNotification!
          ? isSeller
                ? currentShopModel!.shopId
                : uId
          : null,
      receiverId: widget.receiverId,
      receiverName: widget.receiverName!,
      receiverImage: widget.receiverImage!,
      senderName: widget.senderName ?? widget.receiverName,
      senderImage: widget.senderImage ?? widget.receiverImage,
    );

    messageController.clear();
  }

  void handleDeleteSelectedMessages() async {
    final selectedIds = chatCubit.selectedMessages.toList();
    if (selectedIds.isEmpty) return;

    final previousMessages = await chatCubit.getMessagesByIds(
      widget.chatId,
      selectedIds,
    );

    await chatCubit.deleteMessagesForMe(widget.chatId, selectedIds, myId!);
    chatCubit.clearSelectedMessages();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${selectedIds.length} ${selectedIds.length == 1 ? S.of(context).message : S.of(context).messages} ${S.of(context).deleted}",
        ),
        action: SnackBarAction(
          label: S.of(context).undo,
          onPressed: () async {
            await chatCubit.undoDeleteMessages(
              widget.chatId,
              previousMessages,
              myId!,
            );
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
