import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/new_chat/chat_cubit.dart';
import 'package:matajer/new_chat/chat_states.dart';
import 'all_sellers.dart';
import 'chat_details_screen.dart';
import 'reciver_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  TextEditingController searchController = TextEditingController();
  String formatMessageDate(DateTime lastMessageDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (lastMessageDate.isAfter(today)) {
      return 'Today';
    } else if (lastMessageDate.isAfter(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('yyyy-MM-dd').format(lastMessageDate);
    }
  }

  @override
  void initState() {
    super.initState();
    ChatCubit.get(context).getChatUsers();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 150.h,
            flexibleSpace: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Messages",
                            style: TextStyle(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Material(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15.w,
                                vertical: 3.h,
                              ),
                              child: const Text(
                                '0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: greyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () {
                            slideAnimation(
                              context: context,
                              destination: const AllSellers(),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(5.h),
                            child: Icon(
                              Icons.add,
                              color: textColor,
                              size: 27.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(
                        width: 2.w,
                        color: greyColor.withOpacity(0.3),
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: TextFormField(
                      controller: searchController,
                      onTapOutside: (focus) {
                        FocusScope.of(context).unfocus();
                      },
                      decoration: const InputDecoration(
                        fillColor: transparentColor,
                        hintText: "I'm Looking For...",
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ChatCubit.get(context).chatUsers.isNotEmpty
                    ? ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: ChatCubit.get(context).chatUsers.length,
                      itemBuilder: (context, index) {
                        ReciverModel receiver =
                            ChatCubit.get(context).chatUsers[index];
                        return Slidable(
                          key: ValueKey(index),
                          startActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  if (receiver.isPinned) {
                                    ChatCubit.get(
                                      context,
                                    ).unPinChat(receiver: receiver);
                                  } else {
                                    ChatCubit.get(
                                      context,
                                    ).pinChat(receiver: receiver);
                                  }
                                  print('Pin action');
                                },
                                backgroundColor: CupertinoColors.systemGreen,
                                foregroundColor: Colors.white,
                                icon: Icons.push_pin,
                                label:
                                    receiver.isPinned
                                        ? 'UnPin ${receiver.username}'
                                        : 'Pin ${receiver.username}',
                              ),
                            ],
                          ),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {
                                  ChatCubit.get(
                                    context,
                                  ).deleteChat(receiver: receiver);
                                  print('Delete action');
                                },
                                backgroundColor: CupertinoColors.systemRed,
                                foregroundColor: Colors.white,
                                icon: CupertinoIcons.delete,
                                label: 'Delete chat',
                              ),
                            ],
                          ),
                          child: Material(
                            color: scaffoldColor,
                            child: InkWell(
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ChatDetailsScreen(
                                          receiver: receiver,
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 20.w),
                                margin: EdgeInsets.symmetric(vertical: 13.h),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: primaryColor.withOpacity(
                                        0.2,
                                      ),
                                      radius: 29.h,
                                      child: Padding(
                                        padding: EdgeInsets.all(3.h),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            200.r,
                                          ),
                                          child:
                                              receiver.imageUrl != null
                                                  ? CachedNetworkImage(
                                                    imageUrl:
                                                        receiver.imageUrl
                                                            .toString(),
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.cover,
                                                    placeholder:
                                                        (
                                                          context,
                                                          url,
                                                        ) => const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                    errorWidget:
                                                        (context, url, error) =>
                                                            const Icon(
                                                              Icons.error,
                                                            ),
                                                  )
                                                  : Icon(
                                                    IconlyBold.profile,
                                                    size: 30.h,
                                                  ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      receiver.username,
                                                      style: TextStyle(
                                                        fontSize: 18.sp,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 6.w),
                                                    Icon(
                                                      Icons.check_circle,
                                                      color: blueColor,
                                                      size: 16.h,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                formatPostDate(
                                                  DateTime.parse(
                                                    receiver.lastMessageDate!
                                                        .toDate()
                                                        .toString(),
                                                  ),
                                                  context,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  color: Colors.black
                                                      .withOpacity(0.4),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width:
                                                    receiver.isPinned
                                                        ? 0.7.sw
                                                        : 0.75.sw,
                                                child: Row(
                                                  children: [
                                                    if (receiver.lastMessage
                                                        .contains(
                                                          'https://firebasestorage',
                                                        ))
                                                      const Icon(
                                                        IconlyBold.image,
                                                        color: primaryColor,
                                                      ),
                                                    if (receiver.lastMessage
                                                        .contains(
                                                          'https://firebasestorage',
                                                        ))
                                                      SizedBox(width: 5.w),
                                                    Text(
                                                      receiver.lastMessage == ''
                                                          ? 'Send ${receiver.username} a message'
                                                          : receiver.lastMessage
                                                              .contains(
                                                                'https://firebasestorage',
                                                              )
                                                          ? 'image'
                                                          : receiver
                                                              .lastMessage,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 15.sp,
                                                        color:
                                                            receiver.lastMessage
                                                                    .contains(
                                                                      'https://firebasestorage',
                                                                    )
                                                                ? primaryDarkColor
                                                                : Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              receiver.isPinned
                                                  ? const Icon(
                                                    Icons.push_pin,
                                                    size: 18,
                                                    color: primaryColor,
                                                  )
                                                  : const SizedBox(),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                    : Center(
                      child: Column(
                        children: [
                          SizedBox(height: 50.h),
                          const Icon(
                            Icons.error_outline_rounded,
                            color: primaryColor,
                            size: 50,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'No Chats Found',
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                SizedBox(height: 0.1.sh),
              ],
            ),
          ),
        );
      },
    );
  }
}
