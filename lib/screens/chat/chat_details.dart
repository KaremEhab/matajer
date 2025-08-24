// import 'dart:io';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:iconly/iconly.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:matajer/constants/colors.dart';
// import 'package:matajer/constants/functions.dart';
// import 'package:matajer/constants/image_picker.dart';
// import 'package:matajer/constants/vars.dart';
// import 'package:matajer/cubit/chat/chat_cubit.dart';
// import 'package:matajer/cubit/chat/chat_message_card.dart';
// import 'package:matajer/cubit/chat/chat_state.dart';
// import 'package:matajer/models/message_model.dart';
// import 'package:matajer/screens/chat/order_offer.dart';
// import 'package:matajer/widgets/pick_image_source.dart';
//
// class ChatDetails extends StatefulWidget {
//   const ChatDetails({
//     super.key,
//     required this.roomId,
//     required this.userId,
//     required this.username,
//     required this.profilePic,
//   });
//
//   final String roomId, userId, username;
//   final Map<String, dynamic>? profilePic;
//
//   @override
//   ChatDetailsState createState() => ChatDetailsState();
// }
//
// class ChatDetailsState extends State<ChatDetails> {
//   String firstMessage = '';
//   String contractId = '';
//   String? firstMessageContainingOrderId;
//   List? selectedImages;
//   List? chatTotalImages;
//
//   Future<void> pickImages() async {
//     List<XFile> newImages = await ImagePickerUtils.galleryImagePicker();
//
//     if (newImages.isNotEmpty) {
//       setState(() {
//         if (selectedImages == null) {
//           selectedImages = newImages;
//         } else {
//           selectedImages!.addAll(newImages);
//         }
//       });
//       print('Selected ${newImages.length} images: $newImages');
//     } else {
//       print('Image picking canceled');
//     }
//   }
//
//   bool isTextFieldEmpty = true;
//   String messageId = '';
//   final TextEditingController textController = TextEditingController();
//   final ScrollController scrollController = ScrollController();
//
//   @override
//   void dispose() {
//     super.dispose();
//     FirebaseFirestore.instance.collection('Chats').doc(widget.roomId).set(
//       {
//         'online': {
//           uId: false,
//         },
//       },
//       SetOptions(
//         merge: true,
//       ),
//     );
//     // Close the stream subscription
//     FirebaseFirestore.instance
//         .collection('Chats')
//         .doc(widget.roomId)
//         .collection('messages')
//         .orderBy('createdAt')
//         .snapshots()
//         .listen((event) {})
//         .cancel();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<ChatCubit, ChatState>(
//       listener: (context, state) {},
//       builder: (context, state) {
//         SystemChrome.setSystemUIOverlayStyle(
//           const SystemUiOverlayStyle(
//             statusBarColor: primaryColor,
//             statusBarIconBrightness: Brightness.light,
//           ),
//         );
//         return Scaffold(
//           body: Column(
//             children: [
//               // AppBar
//               Container(
//                 color: primaryColor,
//                 child: SafeArea(
//                   child: Padding(
//                     padding:
//                         EdgeInsets.only(left: 15.w, bottom: 10.h, top: 10.h),
//                     child: StreamBuilder(
//                         stream: FirebaseFirestore.instance
//                             .collection('Chats')
//                             .doc(widget.roomId)
//                             .snapshots(),
//                         builder: (context, snapshot) {
//                           if (snapshot.hasData) {
//                             var data = snapshot.data!.data();
//                             bool isOnline =
//                                 data?['online']?[widget.userId] ?? false;
//                             return Row(
//                               children: [
//                                 Material(
//                                   color: primaryDarkColor,
//                                   borderRadius: BorderRadius.circular(50.r),
//                                   child: InkWell(
//                                     borderRadius: BorderRadius.circular(50.r),
//                                     onTap: () {
//                                       Navigator.pop(context);
//                                     },
//                                     child: Container(
//                                       padding: EdgeInsets.fromLTRB(
//                                           0, 10.h, 11.w, 10.h),
//                                       decoration: BoxDecoration(
//                                         borderRadius:
//                                             BorderRadius.circular(50.r),
//                                       ),
//                                       child: Row(
//                                         children: [
//                                           Icon(
//                                             Icons.keyboard_arrow_left,
//                                             color: Colors.white,
//                                             size: 40.h,
//                                           ),
//                                           Stack(
//                                             clipBehavior: Clip.none,
//                                             children: [
//                                               CircleAvatar(
//                                                 radius: 25.r,
//                                                 child: Padding(
//                                                   padding: EdgeInsets.all(2.h),
//                                                   child: ClipRRect(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             200.r),
//                                                     child: CachedNetworkImage(
//                                                       imageUrl:
//                                                           widget.profilePic![
//                                                               widget.userId],
//                                                       width: double.infinity,
//                                                       height: double.infinity,
//                                                       fit: BoxFit.cover,
//                                                       placeholder:
//                                                           (context, url) =>
//                                                               const Center(
//                                                         child:
//                                                             CircularProgressIndicator(),
//                                                       ),
//                                                       errorWidget: (context,
//                                                               url, error) =>
//                                                           const Icon(
//                                                               Icons.error),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                               Positioned(
//                                                 left: 31.w,
//                                                 bottom: 2.h,
//                                                 child: CircleAvatar(
//                                                   radius: 10.r,
//                                                   backgroundColor:
//                                                       primaryDarkColor,
//                                                   child: CircleAvatar(
//                                                     radius: 7.r,
//                                                     backgroundColor: isOnline
//                                                         ? Colors.green
//                                                         : Colors.red,
//                                                   ),
//                                                 ),
//                                               )
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(
//                                   width: 10.w,
//                                 ),
//                                 Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       widget.username,
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 18.sp,
//                                         fontWeight: FontWeight.w600,
//                                       ),
//                                     ),
//                                     Text(
//                                       isOnline ? "In Chat" : "Offline",
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 14.sp,
//                                       ),
//                                     )
//                                   ],
//                                 ),
//                               ],
//                             );
//                           } else {
//                             return const CircularProgressIndicator();
//                           }
//                         }),
//                   ),
//                 ),
//               ),
//               Expanded(
//                 child: StreamBuilder(
//                     stream: FirebaseFirestore.instance
//                         .collection('Chats')
//                         .doc(widget.roomId)
//                         .collection('messages')
//                         .orderBy('createdAt')
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (snapshot.hasData) {
//                         final messageItems = snapshot.data!.docs
//                             .map((e) => MessageModel.fromJson(e.data()))
//                             .toList()
//                             .reversed
//                             .toList();
//                         // Find the first message containing the order ID
//                         if (firstMessageContainingOrderId == null) {
//                           for (var message in messageItems) {
//                             if (message.message!
//                                 .contains('YOUR ORDER ID IS:')) {
//                               firstMessageContainingOrderId = message.message;
//                               break;
//                             }
//                           }
//                         }
//                         return messageItems.isNotEmpty
//                             ? ListView.builder(
//                                 reverse: true,
//                                 controller: scrollController,
//                                 itemCount: messageItems.length,
//                                 padding: EdgeInsets.symmetric(vertical: 12.h),
//                                 itemBuilder: (context, index) {
//                                   if (messageItems[index].toId == uId) {
//                                     ChatCubit.get(context).chatSeen(
//                                       widget.roomId,
//                                       messageItems[index].id.toString(),
//                                     );
//                                   }
//                                   messageId = messageItems[index].id.toString();
//                                   firstMessage =
//                                       messageItems[0].message.toString();
//                                   if (messageItems[index].type == 'image') {
//                                     chatTotalImages
//                                         ?.add(messageItems[index].message);
//                                   }
//                                   return Column(
//                                     children: [
//                                       if (index == messageItems.length - 1 ||
//                                           _isDifferentDay(
//                                               DateTime.parse(messageItems[index]
//                                                   .createdAt!
//                                                   .toDate()
//                                                   .toString()),
//                                               DateTime.parse(
//                                                   messageItems[index + 1]
//                                                       .createdAt!
//                                                       .toDate()
//                                                       .toString())))
//                                         Container(
//                                           padding: EdgeInsets.symmetric(
//                                               horizontal: 16.w, vertical: 8.h),
//                                           decoration: BoxDecoration(
//                                             color: dayContainerColor,
//                                             borderRadius:
//                                                 BorderRadius.circular(10.r),
//                                           ),
//                                           child: Text(
//                                             messageDate(DateTime.parse(
//                                                 messageItems[index]
//                                                     .createdAt!
//                                                     .toDate()
//                                                     .toString())),
//                                             style: TextStyle(
//                                               color: Colors.black,
//                                               fontSize: 13.sp,
//                                             ),
//                                           ),
//                                         ),
//                                       SizedBox(
//                                         height: 8.h,
//                                       ),
//                                       InkWell(
//                                         onTap: () {},
//                                         child: ChatMessageCard(
//                                           messageItems: messageItems[index],
//                                           msgId:
//                                               messageItems[index].id.toString(),
//                                           roomId: widget.roomId,
//                                           userId: widget.userId,
//                                           profilePic: widget.profilePic,
//                                         ),
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               )
//                             : Center(
//                                 child: Material(
//                                   borderRadius: BorderRadius.circular(15.r),
//                                   color: senderColor,
//                                   child: InkWell(
//                                     borderRadius: BorderRadius.circular(15.r),
//                                     onTap: () {
//                                       ChatCubit.get(context).sendMessage(
//                                         roomId: widget.roomId,
//                                         userId: widget.userId,
//                                         messageText: 'Assalamu Alaikum 👋🏼',
//                                       );
//                                     },
//                                     child: Padding(
//                                       padding: EdgeInsets.all(15.h),
//                                       child: Column(
//                                         mainAxisSize: MainAxisSize.min,
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Text(
//                                             '👋🏼',
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .displayMedium,
//                                           ),
//                                           SizedBox(
//                                             height: 15.h,
//                                           ),
//                                           Text(
//                                             'Say Assalamu Alaikum',
//                                             style: Theme.of(context)
//                                                 .textTheme
//                                                 .bodyMedium,
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               );
//                       } else {
//                         return const Center(
//                           child: CircularProgressIndicator(),
//                         );
//                       }
//                     }),
//               ),
//               Padding(
//                 padding: EdgeInsets.all(8.h),
//                 child: Row(
//                   children: <Widget>[
//                     Padding(
//                       padding: EdgeInsets.only(right: 9.w),
//                       child: Material(
//                         color: primaryColor,
//                         shape: const CircleBorder(),
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(50.r),
//                           onTap: () {
//                             showModalBottomSheet(
//                               context: context,
//                               showDragHandle: true,
//                               backgroundColor: scaffoldColor,
//                               builder: (BuildContext context) {
//                                 return Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     ListTile(
//                                       leading: Icon(
//                                         Icons.discount,
//                                         color: primaryColor,
//                                         size: 35.h,
//                                       ),
//                                       title: const Text(
//                                         'Create Proposition',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                       subtitle: const Text(
//                                         "Click if you want to send this customer a discount",
//                                       ),
//                                       onTap: () {
//                                         slideAnimation(
//                                           context: context,
//                                           destination: const OrderOffer(),
//                                         );
//                                       },
//                                     ),
//                                     SizedBox(
//                                       height: 10.h,
//                                     ),
//                                     PickImageSource(
//                                       galleryButton: () async {
//                                         ImagePicker picker = ImagePicker();
//                                         XFile? image = await picker.pickImage(
//                                             source: ImageSource.gallery);
//                                         if (image != null) {
//                                           if (!context.mounted) return;
//                                           ChatCubit.get(context).sendImage(
//                                               widget.roomId,
//                                               widget.userId,
//                                               File(image.path));
//                                         }
//                                       },
//                                       cameraButton: () async {
//                                         ImagePicker picker = ImagePicker();
//                                         XFile? image = await picker.pickImage(
//                                             source: ImageSource.camera);
//                                         if (image != null) {
//                                           if (!context.mounted) return;
//                                           ChatCubit.get(context).sendImage(
//                                               widget.roomId,
//                                               widget.userId,
//                                               File(image.path));
//                                         }
//                                       },
//                                     ),
//                                   ],
//                                 );
//                               },
//                             );
//                           },
//                           child: Padding(
//                             padding: const EdgeInsets.all(5),
//                             child: Icon(
//                               Icons.more_horiz_rounded,
//                               color: Colors.white,
//                               size: 30.h,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     Expanded(
//                       child: TextField(
//                         controller: textController,
//                         onTapOutside: (val) {
//                           FocusScope.of(context).unfocus();
//                         },
//                         onChanged: (text) {
//                           setState(() {
//                             isTextFieldEmpty = text.isEmpty;
//                           });
//                         },
//                         decoration: InputDecoration(
//                           hintText: 'Write your message...',
//                           contentPadding: EdgeInsets.symmetric(
//                             vertical: 10.h,
//                             horizontal: 16.w,
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8.w),
//                     Visibility(
//                       visible: !isTextFieldEmpty,
//                       child: IconButton(
//                         icon: Icon(
//                           IconlyBold.send,
//                           color: primaryColor,
//                           size: 35.h,
//                         ),
//                         onPressed: () {
//                           if (textController.text.isNotEmpty) {
//                             setState(() {
//                               ChatCubit.get(context).sendMessage(
//                                 roomId: widget.roomId,
//                                 userId: widget.userId,
//                                 messageText: textController.text,
//                               );
//                             });
//                             textController.clear();
//                             isTextFieldEmpty = true;
//                             scrollController.animateTo(
//                               scrollController.position.minScrollExtent,
//                               duration: const Duration(milliseconds: 300),
//                               curve: Curves.easeOut,
//                             );
//                           }
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   bool _isDifferentDay(DateTime time1, DateTime time2) {
//     return time1.day != time2.day ||
//         time1.month != time2.month ||
//         time1.year != time2.year;
//   }
// }
