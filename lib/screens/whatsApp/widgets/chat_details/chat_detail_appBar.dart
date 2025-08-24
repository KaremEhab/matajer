import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/screens/whatsApp/widgets/chat_details/typing_indicator.dart';

class ChatDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String chatId;
  final String receiverName;
  final String receiverImage;
  final String receiverId;
  final bool? isFromNotification;
  final bool clearSendMessage;
  final String? senderId;

  const ChatDetailAppBar({
    super.key,
    required this.chatId,
    required this.receiverName,
    required this.receiverImage,
    required this.receiverId,
    this.isFromNotification,
    this.clearSendMessage = false,
    this.senderId,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: scaffoldColor,
      toolbarHeight: 60,
      forceMaterialTransparency: true,
      titleSpacing: 0,
      title: _AppBarTitle(
        chatId: chatId,
        receiverName: receiverName,
        receiverImage: receiverImage,
        clearSendMessage: clearSendMessage,
        receiverId: receiverId,
        isFromNotification: isFromNotification,
        senderId: senderId,
      ),
      actions: const [
        IconButton(onPressed: null, icon: Icon(Icons.call)),
        IconButton(onPressed: null, icon: Icon(Icons.videocam)),
        IconButton(onPressed: null, icon: Icon(Icons.more_vert)),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _AppBarTitle extends StatelessWidget {
  final String chatId;
  final String receiverName;
  final String receiverImage;
  final String receiverId;
  final bool? isFromNotification;
  final bool clearSendMessage;
  final String? senderId;

  _AppBarTitle({
    required this.chatId,
    required this.receiverName,
    required this.receiverImage,
    required this.receiverId,
    this.isFromNotification,
    this.clearSendMessage = false,
    this.senderId,
  });

  final GlobalKey<LayoutState> layoutKey = GlobalKey<LayoutState>();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 7),
        InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: () {
            if (clearSendMessage) {
              // isSeller = false; // reset your flag if needed
              // layoutKey.currentState?.setPages();

              Navigator.of(context).pop(); // first pop
              Navigator.of(context).pop(); // second pop
            } else {
              Navigator.of(context).pop(); // normal single back
            }
          },

          child: Row(
            children: [
              Icon(backIcon(), size: 30, color: textColor),
              _AvatarWithStatus(
                receiverImage: receiverImage,
                chatId: chatId,
                receiverId: receiverId,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'receiver-name-$receiverId',
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  receiverName,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            TypingIndicator(
              chatId: chatId,
              receiverTypingPath: '${receiverId}_typing',
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarWithStatus extends StatelessWidget {
  final String receiverImage;
  final String chatId;
  final String receiverId;

  const _AvatarWithStatus({
    required this.receiverImage,
    required this.chatId,
    required this.receiverId,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'receiver-image-$receiverId',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: textColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(1),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: receiverImage != ''
                    ? CachedNetworkImage(
                        imageUrl: receiverImage.toString(),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => shimmerPlaceholder(
                          width: double.infinity,
                          height: double.infinity,
                          radius: 100,
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.error),
                      )
                    : const Icon(IconlyBold.profile, color: Colors.white),
              ),
            ),
          ),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(chatId)
                .snapshots(),
            builder: (context, snapshot) {
              final isOnline = snapshot.hasData
                  ? (snapshot.data!.data()
                            as Map<String, dynamic>)['${receiverId}_online'] ??
                        false
                  : false;

              return Positioned(
                left: 27,
                bottom: 2,
                child: CircleAvatar(
                  radius: 7,
                  backgroundColor: textColor.withOpacity(0.1),
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: isOnline ? Colors.green : Colors.red,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
