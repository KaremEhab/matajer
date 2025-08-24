import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/chat/chat_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/product_list_screen.dart';
import 'package:matajer/widgets/pick_image_source.dart';

class ChatDetailInput extends StatelessWidget {
  final TextEditingController messageController;
  final ValueNotifier<bool> isTextEmpty;
  final String chatId;
  final String receiverId;
  final String receiverName;
  final String receiverImage;
  final String senderName;
  final String senderImage;
  final VoidCallback onSend;
  final VoidCallback onDeleteSelectedMessages;
  final FocusNode focusNode;

  const ChatDetailInput({
    super.key,
    required this.messageController,
    required this.isTextEmpty,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
    required this.receiverImage,
    required this.senderName,
    required this.senderImage,
    required this.onSend,
    required this.onDeleteSelectedMessages,
    required this.focusNode, // ⬅️ Add this
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _BuildMoreOptionsButton(
                chatId,
                receiverId,
                receiverName,
                receiverImage,
                senderName,
                senderImage,
                focusNode,
              ),
              Expanded(
                child: _ChatTextField(
                  messageController,
                  isTextEmpty,
                  onSend,
                  focusNode,
                  onDelete: onDeleteSelectedMessages,
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isTextEmpty,
                builder: (context, empty, _) {
                  return Visibility(
                    visible: !empty,
                    child: IconButton(
                      icon: const Icon(
                        IconlyBold.send,
                        color: primaryColor,
                        size: 30,
                      ),
                      onPressed: onSend,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BuildMoreOptionsButton extends StatelessWidget {
  final String chatId,
      receiverId,
      receiverName,
      receiverImage,
      senderName,
      senderImage;
  final FocusNode focusNode;

  const _BuildMoreOptionsButton(
    this.chatId,
    this.receiverId,
    this.receiverName,
    this.receiverImage,
    this.senderName,
    this.senderImage,
    this.focusNode,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatsCubit, ChatsStates>(
      builder: (context, state) {
        final cubit = ChatsCubit.instance;
        final hasSelection = cubit.selectedMessages.isNotEmpty;

        return Padding(
          padding: EdgeInsets.only(
            right: lang == 'en' ? 10 : 0,
            left: lang == 'ar' ? 10 : 0,
          ),
          child: Material(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: hasSelection
                  ? () => cubit.clearSelectedMessages()
                  : () {
                      focusNode.unfocus(); // ⬅️ Dismiss the keyboard
                      _showAttachmentSheet(context);
                    },

              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  hasSelection ? Icons.close : Icons.more_horiz_rounded,
                  color: hasSelection ? Colors.black : primaryColor,
                  size: 28,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentSheet(BuildContext context) {
    final cubit = ChatsCubit.instance;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: scaffoldColor,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSeller)
                ListTile(
                  leading: const Icon(
                    Icons.discount,
                    color: primaryColor,
                    size: 30,
                  ),
                  title: Text(S.of(context).create_proposition),
                  subtitle: Text(S.of(context).send_discount_offer),
                  trailing: Icon(
                    Icons.keyboard_arrow_right,
                    color: primaryColor.withOpacity(0.7),
                  ),
                  onTap: () {
                    slideAnimation(
                      context: context,
                      destination: ProductListScreen(
                        shopModel: currentShopModel!,
                        chatId: chatId,
                        receiverId: receiverId,
                      ),
                    );
                  },
                ),
              PickImageSource(
                galleryButton: () async {
                  cubit.pickAndSendImage(
                    chatId: chatId,
                    receiverName: receiverName,
                    receiverImage: receiverImage,
                    senderName: senderName,
                    senderImage: senderImage,
                    context: context,
                  );
                  Navigator.pop(context);
                },
                cameraButton: () async {
                  cubit.pickAndSendImage(
                    chatId: chatId,
                    receiverName: receiverName,
                    receiverImage: receiverImage,
                    senderName: senderName,
                    senderImage: senderImage,
                    context: context,
                  );
                  Navigator.pop(context);
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.image, color: primaryColor, size: 30),
              //   title: Text(S.of(context).pick_image),
              //   subtitle: Text(S.of(context).send_image_to_customer),
              //   trailing: Icon(
              //     forwardIcon(),
              //     color: primaryColor.withOpacity(0.7),
              //   ),
              //   onTap: () {
              //     cubit.pickAndSendImage(chatId: chatId);
              //     Navigator.pop(context);
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}

class _ChatTextField extends StatelessWidget {
  final TextEditingController controller;
  final ValueNotifier<bool> isTextEmpty;
  final VoidCallback onSend;
  final VoidCallback onDelete; // 👈 ADD THIS
  final FocusNode focusNode;

  const _ChatTextField(
    this.controller,
    this.isTextEmpty,
    this.onSend,
    this.focusNode, {
    required this.onDelete, // 👈 ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatsCubit, ChatsStates>(
      builder: (context, state) {
        final cubit = ChatsCubit.instance;
        final hasSelection = cubit.selectedMessages.isNotEmpty;

        if (hasSelection) {
          return TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyBold.delete, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  S.of(context).delete,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: S.of(context).write_message,
            contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            border: OutlineInputBorder(borderSide: BorderSide.none),
            filled: true,
            fillColor: Color(0xFFF2F2F2),
          ),
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => onSend(),
        );
      },
    );
  }
}
