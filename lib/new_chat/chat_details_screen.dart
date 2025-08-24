import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/new_chat/message_model.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/new_chat/chat_cubit.dart';
import 'package:matajer/new_chat/chat_states.dart';
import 'package:matajer/new_chat/reciver_model.dart';
import '../constants/vars.dart';

class ChatDetailsScreen extends StatefulWidget {
  const ChatDetailsScreen({super.key, required this.receiver});

  final ReciverModel receiver;

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  bool isTextFieldEmpty = true;
  String senderID = '';
  final TextEditingController messageController = TextEditingController();
  late ChatCubit chatCubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatCubit = ChatCubit.get(context);
  }

  @override
  void dispose() {
    chatCubit.getChatUsers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatStates>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            elevation: 2,
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            toolbarHeight: 90.h,
            flexibleSpace: Padding(
              padding: EdgeInsets.only(left: 15.w, top: 37.h),
              child: Row(
                children: [
                  Material(
                    color: primaryDarkColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(50.r),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50.r),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.fromLTRB(0, 8.h, 11.w, 8.h),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_left,
                              color: primaryDarkColor,
                              size: 40.h,
                            ),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 25.r,
                                  child: Padding(
                                    padding: EdgeInsets.all(2.h),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        200.r,
                                      ),
                                      child: widget.receiver.imageUrl != null
                                          ? CachedNetworkImage(
                                              imageUrl: widget.receiver.imageUrl
                                                  .toString(),
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            )
                                          : const Icon(IconlyBold.profile),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 31.w,
                                  bottom: 2.h,
                                  child: CircleAvatar(
                                    radius: 10.r,
                                    backgroundColor: primaryDarkColor
                                        .withOpacity(0.2),
                                    child: CircleAvatar(
                                      radius: 7.r,
                                      backgroundColor: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    widget.receiver.username,
                    style: TextStyle(
                      color: primaryDarkColor,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uId)
                .collection('chats')
                .doc(widget.receiver.uId)
                .collection('messages')
                .orderBy('dateTime', descending: true)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot documentSnapshot =
                        snapshot.data!.docs[index];
                    MessageModel messageModel = MessageModel.fromJson(
                      documentSnapshot.data()! as Map<String, dynamic>,
                      documentSnapshot.id,
                    );
                    senderID = messageModel.senderId.toString();
                    if (messageModel.messageType == MessageType.text) {
                      return TextMessageContainer(
                        messageModel: messageModel,
                        receiver: widget.receiver,
                      );
                    } else if (messageModel.messageType == MessageType.offer) {
                      return CustomOfferWidget(messageModel: messageModel);
                    } else {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: messageModel.senderId == uId
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Container(
                              height: 350.h,
                              width: 350.w,
                              padding: EdgeInsets.fromLTRB(
                                10.h,
                                10.h,
                                10.h,
                                7.h,
                              ),
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              decoration: BoxDecoration(
                                color: messageModel.senderId == uId
                                    ? senderColor
                                    : receiverColor,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18.r),
                                  topRight: Radius.circular(18.r),
                                  bottomLeft: messageModel.senderId == uId
                                      ? Radius.circular(18.r)
                                      : Radius.circular(3.r),
                                  bottomRight: messageModel.senderId == uId
                                      ? Radius.circular(3.r)
                                      : Radius.circular(18.r),
                                ),
                                border: messageModel.senderId == uId
                                    ? null
                                    : Border.all(
                                        color: primaryColor,
                                        width: 0.2,
                                        strokeAlign:
                                            BorderSide.strokeAlignOutside,
                                      ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 18,
                                    child: InkWell(
                                      onTap: () {},
                                      onLongPress: () {},
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: messageModel.message
                                              .toString(),
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 5.h),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          messageModel.senderId == uId
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatTimestamp(
                                            DateTime.parse(
                                              messageModel.dateTime!
                                                  .toDate()
                                                  .toString(),
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: chatDateColor,
                                            fontSize: 12.sp,
                                          ),
                                        ),
                                        // if (messageModel.senderId == uId)
                                        //   SizedBox(width: 5.w),
                                        // if (messageModel.senderId == uId)
                                        //   Icon(
                                        //     widget.messageItems!.read == ''
                                        //         ? Icons.check_circle_outline_rounded
                                        //         : Icons.check_circle_rounded,
                                        //     color: Colors.blueAccent,
                                        //     size: 15.h,
                                        //   ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          bottomNavigationBar: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 9.w),
                    child: Material(
                      color: primaryColor,
                      shape: const CircleBorder(),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50.r),
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            backgroundColor: scaffoldColor,
                            builder: (BuildContext context) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (currentUserModel.userType ==
                                      UserType.seller)
                                    ListTile(
                                      leading: Icon(
                                        Icons.discount,
                                        color: primaryColor,
                                        size: 35.h,
                                      ),
                                      title: const Text(
                                        'Create Proposition',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        "Click if you want to send this customer a discount",
                                      ),
                                      // onTap: () {
                                      //   slideAnimation(
                                      //     context: context,
                                      //     destination: ProductListScreen(
                                      //       shopModel: currentShopModel,
                                      //     ),
                                      //   );
                                      // },
                                    ),
                                  if (currentUserModel.userType ==
                                      UserType.seller)
                                    SizedBox(height: 10.h),
                                  ListTile(
                                    leading: Icon(
                                      Icons.image,
                                      color: primaryColor,
                                      size: 35.h,
                                    ),
                                    title: const Text(
                                      'Pick image',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: const Text(
                                      "Click if you want to send this customer an image",
                                    ),
                                    onTap: () {
                                      chatCubit.pickPhoto(
                                        source: ImageSource.gallery,
                                        receiverId: widget.receiver,
                                      );
                                      Navigator.pop(context);
                                    },
                                  ),
                                  SizedBox(height: 10.h),
                                ],
                              );
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white,
                            size: 30.h,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onTapOutside: (val) {
                        FocusScope.of(context).unfocus();
                      },
                      onChanged: (text) {
                        setState(() {
                          isTextFieldEmpty = text.isEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Write your message...',
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10.h,
                          horizontal: 16.w,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Visibility(
                    visible: !isTextFieldEmpty,
                    child: IconButton(
                      icon: Icon(
                        IconlyBold.send,
                        color: primaryColor,
                        size: 35.h,
                      ),
                      onPressed: () {
                        if (messageController.text.isNotEmpty) {
                          chatCubit.sendMessage(
                            message: messageController.text,
                            context: context,
                            receiver: widget.receiver,
                            messageType: MessageType.text,
                          );
                          messageController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomOfferWidget extends StatelessWidget {
  const CustomOfferWidget({super.key, required this.messageModel});

  final MessageModel messageModel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: textColor.withOpacity(0.1), width: 2.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Offer',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const Icon(Icons.more_horiz),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Divider(color: greyColor.withOpacity(0.2), thickness: 2),
            ),
            Container(
              height: 140.h,
              width: 0.94.sw,
              clipBehavior: Clip.antiAliasWithSaveLayer,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: EdgeInsets.all(10.w),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: CachedNetworkImage(
                          imageUrl: messageModel.offer!.product.images.first,
                          height: 110.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          progressIndicatorBuilder:
                              (context, url, downloadProgress) => Center(
                                child: SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15, left: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 230.w,
                            child: Text(
                              messageModel.offer!.product.title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 19.5.sp,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                              ),
                            ),
                          ),
                          Text(
                            messageModel.offer!.description,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: textColor.withOpacity(0.45),
                            ),
                            //   ElevatedButton(
                            //   onPressed: () async {
                            //     final receiverId =
                            //         widget
                            //             .productModel
                            //             .sellerId;
                            //     final chatId =
                            //         '${currentUserModel.uId}_$receiverId';
                            //
                            //     // Create chat room if needed
                            //     await ChatsCubit.get(
                            //       context,
                            //     ).createChatRoom(
                            //       userId:
                            //       currentUserModel
                            //           .uId,
                            //       userName:
                            //       currentUserModel
                            //           .username,
                            //       userImage:
                            //       currentUserModel
                            //           .profilePicture!,
                            //       shopId: receiverId,
                            //       shopName:
                            //       widget
                            //           .productModel
                            //           .sellerName,
                            //       shopImage:
                            //       widget
                            //           .productModel
                            //           .sellerLogo,
                            //     );
                            //
                            //     // Send offer message
                            //     final newMessage = ChatMessageModel(
                            //       id:
                            //       FirebaseFirestore
                            //           .instance
                            //           .collection(
                            //         'chats',
                            //       )
                            //           .doc(chatId)
                            //           .collection(
                            //         'messages',
                            //       )
                            //           .doc()
                            //           .id,
                            //       chatId: chatId,
                            //       senderId:
                            //       currentUserModel
                            //           .uId,
                            //       receiverId:
                            //       receiverId,
                            //       text:
                            //       messageController
                            //           .text,
                            //       productMention:
                            //       widget
                            //           .productModel,
                            //       type:
                            //       MessageType
                            //           .productMention,
                            //       timestamp:
                            //       Timestamp.now(),
                            //     );
                            //
                            //     await FirebaseFirestore
                            //         .instance
                            //         .collection('chats')
                            //         .doc(chatId)
                            //         .collection(
                            //       'messages',
                            //     )
                            //         .doc(newMessage.id)
                            //         .set(
                            //       newMessage
                            //           .toMap(),
                            //     );
                            //
                            //     Navigator.pop(
                            //       context,
                            //     ); // Close modal
                            //
                            //     // Go to chat screen
                            //     await Future.delayed(
                            //       const Duration(
                            //         seconds: 1,
                            //       ),
                            //           () {
                            //         navigateTo(
                            //           context: context,
                            //           screen: ChatDetailPage(
                            //             chatId: chatId,
                            //             receiverId:
                            //             widget
                            //                 .productModel
                            //                 .shopId,
                            //             receiverName:
                            //             widget
                            //                 .shopModel!
                            //                 .shopName,
                            //             receiverImage:
                            //             widget
                            //                 .shopModel!
                            //                 .shopLogoUrl,
                            //           ),
                            //         );
                            //       },
                            //     );
                            //   },
                            //   child: Text(
                            //     'Send Message',
                            //   ),
                            // ),
                          ),
                          SizedBox(height: 7.h),
                          Row(
                            spacing: 10,
                            children: [
                              Text(
                                'AED ${messageModel.offer!.newPrice}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 25.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'AED ${messageModel.offer!.product.price}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: primaryColor.withOpacity(0.4),
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.lineThrough,
                                  decorationThickness: 2,
                                  decorationColor: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15.h),
            if (messageModel.offer!.expireDate != null &&
                Timestamp.now().toDate().isAfter(
                  messageModel.offer!.expireDate!.toDate(),
                ))
              Center(
                child: Text(
                  'Offer Expired',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else if (uId == messageModel.senderId)
              Center(
                child: Text(
                  'Offer Sent',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              InkWell(
                // onTap: () async {
                //   AlertDialog alert = AlertDialog(
                //     title: const Text("Warning"),
                //     content: const Text(
                //       "Are you sure you want clear the cart to buy this offer now?",
                //     ),
                //     actions: [
                //       TextButton(
                //         onPressed: () async {
                //           await ProductCubit.get(context).clearCart();
                //           if (!context.mounted) return;
                //           await ProductCubit.get(context).addProductToCart(
                //             product: CartProductItemModel(
                //               productId: messageModel.offer!.product.id,
                //               quantity: 1,
                //               productDescription:
                //                   messageModel.offer!.product.description,
                //               price: messageModel.offer!.newPrice,
                //               sellerId: messageModel.offer!.product.userId,
                //               sellerName: messageModel.offer!.product.shopName,
                //               sellerPhone:
                //                   messageModel.offer!.product.sellerPhone,
                //               productName: messageModel.offer!.product.title,
                //               imageUrl:
                //                   messageModel.offer!.product.images.first,
                //               isOffer: true,
                //             ),
                //           );
                //           if (!context.mounted) return;
                //           await ChatCubit.get(context).expireOffer(
                //             receiverId: messageModel.offer!.product.userId,
                //             message: messageModel,
                //           );
                //           if (!context.mounted) return;
                //           // navigateReplacement(
                //           //   context: context,
                //           //   screen: const Basket(),
                //           // );
                //         },
                //         child: const Text("Yes"),
                //       ),
                //       TextButton(
                //         onPressed: () {
                //           Navigator.pop(context);
                //         },
                //         child: const Text("No"),
                //       ),
                //     ],
                //   );
                //   // show the dialog
                //   showDialog(
                //     context: context,
                //     builder: (BuildContext context) {
                //       return alert;
                //     },
                //   );
                // },
                child: Material(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: Text(
                        'Buy Offer Now',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TextMessageContainer extends StatelessWidget {
  const TextMessageContainer({
    super.key,
    required this.messageModel,
    required this.receiver,
  });

  final MessageModel messageModel;
  final ReciverModel receiver;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: messageModel.senderId == uId
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (messageModel.senderId != uId)
            CircleAvatar(
              radius: 23.r,
              child: Padding(
                padding: EdgeInsets.all(2.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(200.r),
                  child: receiver.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: receiver.imageUrl.toString(),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : const Icon(IconlyBold.profile),
                ),
              ),
            ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: messageModel.senderId == uId ? senderColor : receiverColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
                bottomLeft: messageModel.senderId == uId
                    ? Radius.circular(12.r)
                    : Radius.circular(2.r),
                bottomRight: messageModel.senderId == uId
                    ? Radius.circular(2.r)
                    : Radius.circular(12.r),
              ),
              border: messageModel.senderId == uId
                  ? null
                  : Border.all(
                      color: primaryColor,
                      width: 0.2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
            ),
            child: Column(
              crossAxisAlignment: messageModel.senderId == uId
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: 0.65.sw),
                  child: Text(
                    messageModel.message.toString(),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 5.h),
                Row(
                  mainAxisAlignment: messageModel.senderId == uId
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      _formatTimestamp(
                        DateTime.parse(
                          messageModel.dateTime!.toDate().toString(),
                        ),
                      ),
                      style: TextStyle(color: chatDateColor, fontSize: 12.sp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime timestamp) {
  return DateFormat('h:mm a').format(timestamp);
}
