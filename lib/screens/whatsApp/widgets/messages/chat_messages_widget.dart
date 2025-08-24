import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/chat/chat_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/chat/message.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/whatsApp/widgets/messages/build_message_card.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/screens/whatsApp/widgets/messages/date_header_card.dart';

class ChatMessagesWidget extends StatefulWidget {
  final String? receiverName;
  final String? receiverImage;
  final String? senderName;
  final String? senderImage;
  final String chatId;
  final String receiverId;
  final Stream<List<ChatMessageModel>> messageStream;

  const ChatMessagesWidget({
    super.key,
    required this.chatId,
    required this.receiverId,
    this.receiverName,
    this.receiverImage,
    this.senderName,
    this.senderImage,
    required this.messageStream,
  });

  @override
  State<ChatMessagesWidget> createState() => _ChatMessagesWidgetState();
}

class _ChatMessagesWidgetState extends State<ChatMessagesWidget>
    with AutomaticKeepAliveClientMixin {
  late final String myId;
  late final String otherId;
  late final cubit;

  @override
  void initState() {
    super.initState();
    cubit = ChatsCubit.instance;
    myId = isSeller ? currentShopModel!.shopId : currentUserModel.uId;

    final ids = widget.chatId.split('_');
    otherId = ids.first == myId ? ids.last : ids.first;
  }

  bool get isSelecting => cubit.selectedMessages.isNotEmpty;

  void toggleSelection(String id) {
    cubit.toggleMessageSelection(id); // ← بدل setState
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<ChatsCubit, ChatsStates>(
      builder: (context, state) {
        return StreamBuilder<List<ChatMessageModel>>(
          stream: widget.messageStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                itemCount: 8,
                itemBuilder: (context, index) {
                  final bool isMe = index.isEven; // Right if even, left if odd

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: 0.7.sw),
                      decoration: BoxDecoration(
                        color: isMe ? senderColor : receiverColor,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                      ),
                      child: Column(
                        spacing: 5,
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          shimmerPlaceholder(
                            height: 15,
                            width: double.infinity,
                            radius: 8,
                          ),
                          shimmerPlaceholder(
                            height: 15,
                            width: 0.6.sw,
                            radius: 8,
                          ),
                          shimmerPlaceholder(
                            height: 15,
                            width: 0.4.sw,
                            radius: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            final firebaseMessages = snapshot.data ?? [];

            // دمج الرسائل المؤقتة + firebase
            final allMessages = [
              ...firebaseMessages,
              ...cubit.uploadingMessages,
            ];

            // ترتيب حسب التاريخ
            allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            if (allMessages.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${S.of(context).start_talking_to} ${widget.receiverName}",
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async => await cubit.sendNewTextMessage(
                        text: S.of(context).hello,
                        chatId: widget.chatId,
                        receiverId: widget.receiverId,
                        receiverName: widget.receiverName!,
                        receiverImage: widget.receiverImage!,
                        senderName: widget.senderName ?? widget.receiverName,
                        senderImage: widget.senderImage ?? widget.receiverImage,
                      ),
                      child: Text(S.of(context).say_hello),
                    ),
                  ],
                ),
              );
            }
            return RepaintBoundary(
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: allMessages.length,
                itemBuilder: (context, index) {
                  final message = allMessages[index];
                  final isMe = message.senderId == myId;

                  final messageDate = message.timestamp.toDate();
                  final prevDate = index + 1 < allMessages.length
                      ? allMessages[index + 1].timestamp.toDate()
                      : null;

                  final showDateHeader =
                      prevDate == null ||
                      messageDate.day != prevDate.day ||
                      messageDate.month != prevDate.month ||
                      messageDate.year != prevDate.year;

                  return Column(
                    children: [
                      if (showDateHeader)
                        DateHeaderCard(messageDate: messageDate),
                      KeyedSubtree(
                        key: ValueKey(message.id),
                        child: BuildMessageCard(
                          message: message,
                          isMe: isMe,
                          isSelected: cubit.selectedMessages.contains(
                            message.id,
                          ),
                          isSelecting: isSelecting,
                          onSelect: toggleSelection,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
