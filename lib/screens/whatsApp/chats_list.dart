import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/chat/chat.dart';
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/whatsApp/chat_page.dart';

class ChatsPage extends StatefulWidget {
  final String userId;

  const ChatsPage({super.key, required this.userId});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late ChatsCubit chatCubit;

  @override
  void initState() {
    super.initState();
    if (!isGuest) chatCubit = ChatsCubit.instance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: isGuest
            ? Text(
                S.of(context).inbox,
                style: TextStyle(fontWeight: FontWeight.bold),
              )
            : StreamBuilder<int>(
                stream: chatCubit.getTotalUnseenMessagesCount(
                  isSeller ? currentShopModel!.shopId : currentUserModel.uId,
                ),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;

                  return Text(
                    isGuest
                        ? S.of(context).inbox
                        : '${S.of(context).inbox} (${count > 0 ? count : 0})',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                },
              ),
      ),
      body: isGuest
          ? Center(
              child: SizedBox(
                width: 0.7.sw,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconlyLight.message, size: 150, color: primaryColor),
                    Text(
                      S.of(context).cannot_access_chat,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        navigateTo(context: context, screen: SignUp());
                      },
                      child: Chip(
                        label: Text(
                          S.of(context).create_an_account,
                          style: TextStyle(color: Colors.white),
                        ),
                        side: BorderSide.none,
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : FutureBuilder<List<String>>(
              future: chatCubit.getPinnedChats(),
              builder: (context, pinnedSnapshot) {
                if (!pinnedSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final pinnedChatsIds = pinnedSnapshot.data!;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where(
                        isSeller ? 'shopId' : 'userId',
                        isEqualTo: widget.userId,
                      )
                      .where(
                        'visibleTo',
                        arrayContains: widget.userId,
                      ) // 👈 filter only visible chats
                      .orderBy('lastMessageTime', descending: true)
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(S.of(context).error));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final chats = snapshot.data!.docs
                        .where(
                          (doc) =>
                              (doc.data()
                                  as Map<String, dynamic>)['lastMessageTime'] !=
                              null,
                        )
                        .map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return {
                            'model': ChatModel.fromJson(data),
                            'raw': data,
                          };
                        })
                        .toList();

                    // ✅ ترتيب الشاتات: المثبت الأول
                    chats.sort((a, b) {
                      final aId = (a['model'] as ChatModel).chatId;
                      final bId = (b['model'] as ChatModel).chatId;

                      final aPinned = pinnedChatsIds.contains(aId);
                      final bPinned = pinnedChatsIds.contains(bId);

                      if (aPinned && !bPinned) return -1;
                      if (!aPinned && bPinned) return 1;
                      return 0;
                    });

                    if (chats.isEmpty) {
                      return Center(child: Text(S.of(context).no_chats));
                    }

                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chatData = chats[index];
                        final chat = chatData['model'] as ChatModel;
                        final raw = chatData['raw'] as Map<String, dynamic>;

                        final isCustomer = currentUserModel.uId == chat.userId;
                        final receiverId = isCustomer
                            ? chat.shopId
                            : chat.userId;

                        final sentByMe = isSeller
                            ? chat.sentBy == currentShopModel!.shopId
                            : chat.sentBy == currentUserModel.uId;

                        final receiverCollection = isCustomer
                            ? 'shops'
                            : 'users';

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection(receiverCollection)
                              .doc(receiverId)
                              .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: textColor.withOpacity(0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.all(1),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: shimmerPlaceholder(
                                        width: double.infinity,
                                        height: double.infinity,
                                        radius: 100,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Padding(
                                  padding: const EdgeInsets.only(right: 100),
                                  child: shimmerPlaceholder(
                                    width: 120,
                                    height: 15,
                                    radius: 5,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(right: 150),
                                  child: shimmerPlaceholder(
                                    width: 120,
                                    height: 10,
                                    radius: 5,
                                  ),
                                ),
                              );
                            }

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;

                            final receiverName = isCustomer
                                ? data['shopName']
                                : data['username'] ?? S.of(context).unknown;
                            final receiverImage = isCustomer
                                ? data['shopLogoUrl']
                                : data['profilePicture'] ?? '';

                            final senderName = isSeller
                                ? currentShopModel!.shopName
                                : currentUserModel.username ??
                                      S.of(context).unknown;
                            final senderImage = isSeller
                                ? currentShopModel!.shopLogoUrl
                                : currentUserModel.profilePicture ?? '';

                            final myId = isSeller
                                ? currentShopModel!.shopId
                                : currentUserModel.uId;

                            final previewText = chat.lastMessage[myId] ?? '';

                            final ids = chat.chatId.split('_');
                            final otherId = ids.first == myId
                                ? ids.last
                                : ids.first;
                            final isOnline =
                                (chatData['raw']
                                    as Map<
                                      String,
                                      dynamic
                                    >?)?['${otherId}_online'] ??
                                false;

                            return Column(
                              children: [
                                Slidable(
                                  key: ValueKey(index),
                                  startActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (c) async {
                                          // Backup chat before deleting
                                          final previousChat = await chatCubit
                                              .getChatById(chat.chatId);

                                          // Delete for me
                                          await chatCubit.deleteChatForMe(
                                            chat.chatId,
                                            myId,
                                          );
                                          log("Deleting chat...");
                                        },
                                        backgroundColor:
                                            CupertinoColors.systemRed,
                                        foregroundColor: Colors.white,
                                        icon: CupertinoIcons.delete,
                                        label: S.of(context).delete_chat,
                                      ),
                                    ],
                                  ),
                                  endActionPane: ActionPane(
                                    motion: const ScrollMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (context) async {
                                          // pin chat locally
                                          await chatCubit.togglePinChat(
                                            chat.chatId,
                                          );
                                          setState(() {});
                                        },
                                        backgroundColor:
                                            pinnedChatsIds.contains(chat.chatId)
                                            ? CupertinoColors.systemGrey
                                            : CupertinoColors.systemGreen,
                                        foregroundColor: Colors.white,
                                        icon: Icons.push_pin,
                                        label:
                                            pinnedChatsIds.contains(chat.chatId)
                                            ? '${S.of(context).unpin} $receiverName'
                                            : '${S.of(context).pin} $receiverName',
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    onTap: () async {
                                      log(
                                        "message: ${chat.shopId},${chat.userId}",
                                      );
                                      // if (currentShopModel == null) {
                                      //   "isSeller: $isSeller";
                                      //
                                      //   // Now it's safe to update
                                      //   await UserCubit.get(
                                      //     context,
                                      //   ).getShopById(chat.shopId);
                                      //
                                      //   isSeller = true;
                                      // }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatDetailPage(
                                            chatId: chat.chatId,
                                            receiverName: receiverName,
                                            receiverImage: receiverImage,
                                            senderName: senderName,
                                            senderImage: senderImage,
                                            receiverId: receiverId,
                                            lastDeletedAt:
                                                chat.lastDeletedAt[myId],
                                          ),
                                        ),
                                      );
                                    },
                                    leading: Hero(
                                      tag: 'receiver-image-$receiverId',
                                      child: Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: textColor
                                                .withOpacity(0.1),
                                            child: Padding(
                                              padding: const EdgeInsets.all(1),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                child: receiverImage != ''
                                                    ? CachedNetworkImage(
                                                        imageUrl: receiverImage
                                                            .toString(),
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        fit: BoxFit.cover,
                                                        placeholder:
                                                            (context, url) =>
                                                                shimmerPlaceholder(
                                                                  width: double
                                                                      .infinity,
                                                                  height: double
                                                                      .infinity,
                                                                  radius: 100,
                                                                ),
                                                        errorWidget:
                                                            (
                                                              context,
                                                              url,
                                                              error,
                                                            ) => const Icon(
                                                              Icons.error,
                                                            ),
                                                      )
                                                    : const Icon(
                                                        IconlyBold.profile,
                                                        color: Colors.white,
                                                      ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 35,
                                            bottom: 2,
                                            child: CircleAvatar(
                                              radius: 7,
                                              backgroundColor: textColor
                                                  .withOpacity(0.1),
                                              child: CircleAvatar(
                                                radius: 5,
                                                backgroundColor: isOnline
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Hero(
                                          tag: 'receiver-name-$receiverId',
                                          child: Material(
                                            type: MaterialType.transparency,
                                            child: Text(
                                              receiverName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color:
                                                    (!sentByMe &&
                                                        !chat.lastMessageSeen)
                                                    ? CupertinoColors.systemBlue
                                                    : textColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTime(chat.lastMessageTime),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                (!sentByMe &&
                                                    !chat.lastMessageSeen)
                                                ? CupertinoColors.systemBlue
                                                : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),

                                    subtitle:
                                        raw['${receiverId}_typing'] ?? false
                                        ? Text(
                                            S.of(context).typing,
                                            style: TextStyle(
                                              color: CupertinoColors.systemBlue,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (sentByMe)
                                                Text(
                                                  "${S.of(context).you}: ",
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              if (chat.lastMessageType ==
                                                  LastMessageType.text) ...[
                                                Expanded(
                                                  child: Text(
                                                    previewText,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          (!sentByMe &&
                                                              !chat
                                                                  .lastMessageSeen)
                                                          ? CupertinoColors
                                                                .systemBlue
                                                          : textColor,
                                                    ),
                                                  ),
                                                ),
                                              ] else if (chat.lastMessageType ==
                                                  LastMessageType.image) ...[
                                                Icon(
                                                  (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? IconlyBold.image
                                                      : IconlyLight.image,
                                                  size: 16,
                                                  color:
                                                      (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? CupertinoColors
                                                            .systemBlue
                                                      : textColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    S.of(context).image,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          (!sentByMe &&
                                                              !chat
                                                                  .lastMessageSeen)
                                                          ? CupertinoColors
                                                                .systemBlue
                                                          : textColor,
                                                    ),
                                                  ),
                                                ),
                                              ] else if (chat.lastMessageType ==
                                                  LastMessageType.video) ...[
                                                Icon(
                                                  (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? IconlyBold.video
                                                      : IconlyLight.video,
                                                  size: 16,
                                                  color:
                                                      (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? CupertinoColors
                                                            .systemBlue
                                                      : textColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    S.of(context).video,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          (!sentByMe &&
                                                              !chat
                                                                  .lastMessageSeen)
                                                          ? CupertinoColors
                                                                .systemBlue
                                                          : textColor,
                                                    ),
                                                  ),
                                                ),
                                              ] else if (chat.lastMessageType ==
                                                  LastMessageType.audio) ...[
                                                Icon(
                                                  (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? IconlyBold.voice
                                                      : IconlyLight.voice,
                                                  size: 16,
                                                  color:
                                                      (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? CupertinoColors
                                                            .systemBlue
                                                      : textColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    S.of(context).voice_note,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          (!sentByMe &&
                                                              !chat
                                                                  .lastMessageSeen)
                                                          ? CupertinoColors
                                                                .systemBlue
                                                          : textColor,
                                                    ),
                                                  ),
                                                ),
                                              ] else if (chat.lastMessageType ==
                                                  LastMessageType
                                                      .productMention) ...[
                                                Icon(
                                                  (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? IconlyBold.bag
                                                      : IconlyLight.bag,
                                                  size: 16,
                                                  color:
                                                      (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? CupertinoColors
                                                            .systemBlue
                                                      : textColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    S
                                                        .of(context)
                                                        .product_mention,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          (!sentByMe &&
                                                              !chat
                                                                  .lastMessageSeen)
                                                          ? CupertinoColors
                                                                .systemBlue
                                                          : textColor,
                                                    ),
                                                  ),
                                                ),
                                              ] else if (chat.lastMessageType ==
                                                  LastMessageType.offer) ...[
                                                Icon(
                                                  (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? IconlyBold.ticket
                                                      : IconlyLight.ticket,
                                                  size: 16,
                                                  color:
                                                      (!sentByMe &&
                                                          !chat.lastMessageSeen)
                                                      ? CupertinoColors
                                                            .systemBlue
                                                      : textColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    S.of(context).offer,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color:
                                                          (!sentByMe &&
                                                              !chat
                                                                  .lastMessageSeen)
                                                          ? CupertinoColors
                                                                .systemBlue
                                                          : textColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (sentByMe) ...[
                                                Icon(
                                                  raw['lastMessageSeen'] == true
                                                      ? Icons.done_all
                                                      : Icons.done,
                                                  size: 16,
                                                  color:
                                                      raw['lastMessageSeen'] ==
                                                          true
                                                      ? Colors.blue
                                                      : Colors.grey,
                                                ),
                                              ],
                                              if (pinnedChatsIds.contains(
                                                chat.chatId,
                                              )) ...[
                                                const Icon(
                                                  Icons.push_pin_rounded,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                                SizedBox(width: 2),
                                              ],
                                              if (!sentByMe)
                                                StreamBuilder<int>(
                                                  stream: ChatsCubit.instance
                                                      .getUnseenMessageCountStream(
                                                        chat.chatId,
                                                        myId,
                                                      ),
                                                  builder: (context, snapshot) {
                                                    if (!snapshot.hasData ||
                                                        snapshot.data == 0) {
                                                      return const SizedBox.shrink();
                                                    }

                                                    return Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 7,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: CupertinoColors
                                                            .systemBlue,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        snapshot.data! <= 99
                                                            ? '${snapshot.data}'
                                                            : '+99',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(time.year, time.month, time.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) {
      return DateFormat('hh:mm a').format(time);
    }
    if (diff == 1) return S.of(context).yesterday;
    if (diff < 7) return DateFormat.EEEE().format(time); // eg. Monday, Tuesday
    return DateFormat('d MMMM yyyy').format(time); // eg. 12 June 2025
  }
}
