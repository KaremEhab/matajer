// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_slidable/flutter_slidable.dart';
// import 'package:iconly/iconly.dart';
// import 'package:matajer/constants/colors.dart';
// import 'package:matajer/constants/functions.dart';
// import 'package:matajer/constants/vars.dart';
// import 'package:matajer/cubit/chat/chat_cubit.dart';
// import 'package:matajer/cubit/chat/chat_state.dart';
// import 'package:matajer/models/chatroom_model.dart';
// import 'package:matajer/models/message_model.dart';
// import 'chat_details.dart';
//
// class Chat extends StatefulWidget {
//   const Chat({super.key});
//
//   @override
//   State<Chat> createState() => _ChatState();
// }
//
// class _ChatState extends State<Chat> {
//   TextEditingController searchController = TextEditingController();
//   List<ChatRoomModel>? rooms;
//   List unreadList = [];
//   int unreadMessagesCount = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     unreadList = [];
//     fetchUnreadMessagesCount();
//   }
//
//   void fetchUnreadMessagesCount() async {
//     int count = await ChatCubit.get(context).getTotalUnreadMessages();
//     setState(() {
//       unreadMessagesCount = count;
//     });
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<ChatCubit, ChatState>(
//       listener: (context, state) {},
//       builder: (context, state) {
//         SystemChrome.setSystemUIOverlayStyle(
//           const SystemUiOverlayStyle(
//             statusBarColor: scaffoldColor,
//             statusBarBrightness: Brightness.dark,
//             statusBarIconBrightness: Brightness.dark,
//           ),
//         );
//         return Scaffold(
//           appBar: PreferredSize(
//             preferredSize: Size(double.infinity, 136.h),
//             child: Padding(
//               padding: EdgeInsets.symmetric(horizontal: 15.w),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   SizedBox(
//                     height: 40.h,
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Row(
//                         children: [
//                           Text(
//                             "Messages",
//                             style: TextStyle(
//                               fontSize: 30.sp,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                           SizedBox(
//                             width: 10.w,
//                           ),
//                           Material(
//                             color: primaryColor,
//                             borderRadius: BorderRadius.circular(8.r),
//                             child: Padding(
//                               padding: EdgeInsets.symmetric(
//                                   horizontal: 15.w, vertical: 3.h),
//                               child: Text(
//                                 unreadMessagesCount.toString(),
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       Material(
//                         color: greyColor.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12.r),
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(12.r),
//                           onTap: () {},
//                           child: Padding(
//                             padding: EdgeInsets.all(5.h),
//                             child: Icon(
//                               Icons.add,
//                               color: textColor,
//                               size: 27.h,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(
//                     height: 10.h,
//                   ),
//                   Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(15.r),
//                       border: Border.all(
//                         width: 2.w,
//                         color: greyColor.withOpacity(0.3),
//                         strokeAlign: BorderSide.strokeAlignOutside,
//                       ),
//                     ),
//                     child: TextFormField(
//                       controller: searchController,
//                       onTapOutside: (focus) {
//                         FocusScope.of(context).unfocus();
//                       },
//                       decoration: const InputDecoration(
//                         fillColor: transparentColor,
//                         hintText: "I'm Looking For...",
//                         prefixIcon: Icon(Icons.search),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           body: SingleChildScrollView(
//             physics: const BouncingScrollPhysics(),
//             child: Column(
//               children: [
//                 SizedBox(
//                   height: 20.h,
//                 ),
//                 StreamBuilder(
//                   stream: FirebaseFirestore.instance
//                       .collection('Chats')
//                       .where('members', arrayContains: uId)
//                       .snapshots(),
//                   builder: (context, snapshot) {
//                     if (snapshot.hasData) {
//                       rooms = snapshot.data!.docs
//                           .map((e) => ChatRoomModel.fromJson(e.data()))
//                           .toList()
//                         ..sort((a, b) =>
//                             b.lastMessageTime!.compareTo(a.lastMessageTime!));
//                       return snapshot.data!.docs.isNotEmpty
//                           ? ListView.builder(
//                               padding: EdgeInsets.zero,
//                               physics: const NeverScrollableScrollPhysics(),
//                               itemCount: rooms!.length,
//                               shrinkWrap: true,
//                               itemBuilder: (context, index) {
//                                 String userId = rooms![index]
//                                     .members!
//                                     .where((element) => element != uId)
//                                     .first;
//                                 return Slidable(
//                                   key: ValueKey(index),
//                                   startActionPane: ActionPane(
//                                     motion: const ScrollMotion(),
//                                     dismissible:
//                                         DismissiblePane(onDismissed: () {}),
//                                     children: [
//                                       SlidableAction(
//                                         onPressed: (context) {
//                                           // Implement delete logic here
//                                           print('Pin action');
//                                         },
//                                         backgroundColor:
//                                             CupertinoColors.systemGreen,
//                                         foregroundColor: Colors.white,
//                                         icon: Icons.push_pin,
//                                         label:
//                                             'Pin ${rooms![index].username![userId]} chat',
//                                       ),
//                                     ],
//                                   ),
//                                   endActionPane: ActionPane(
//                                     motion: const ScrollMotion(),
//                                     children: [
//                                       SlidableAction(
//                                         flex: 2,
//                                         onPressed: (context) {
//                                           // Implement archive logic here
//                                           print('Mute action');
//                                         },
//                                         backgroundColor:
//                                             CupertinoColors.systemGrey,
//                                         foregroundColor: Colors.white,
//                                         icon: CupertinoIcons.volume_off,
//                                         label: 'Mute',
//                                       ),
//                                       SlidableAction(
//                                         onPressed: (context) {
//                                           // Implement save logic here
//                                           print('Delete action');
//                                         },
//                                         backgroundColor:
//                                             CupertinoColors.systemRed,
//                                         foregroundColor: Colors.white,
//                                         icon: CupertinoIcons.delete,
//                                       ),
//                                     ],
//                                   ),
//                                   child: Material(
//                                     color: scaffoldColor,
//                                     child: InkWell(
//                                       onTap: () async {
//                                         await FirebaseFirestore.instance
//                                             .collection('Chats')
//                                             .doc(rooms![index].id)
//                                             .set(
//                                           {
//                                             'online': {
//                                               uId: true,
//                                             },
//                                           },
//                                           SetOptions(
//                                             merge: true,
//                                           ),
//                                         );
//                                         if (!context.mounted) return;
//                                         slideAnimation(
//                                           context: context,
//                                           destination: ChatDetails(
//                                             roomId: rooms![index].id!,
//                                             userId: userId,
//                                             username: rooms![index]
//                                                 .username![userId]
//                                                 .toString(),
//                                             profilePic:
//                                                 rooms![index].profilePic,
//                                           ),
//                                           rightSlide: true,
//                                         );
//                                         print(index);
//                                       },
//                                       child: Container(
//                                         padding: EdgeInsets.symmetric(
//                                             horizontal: 20.w),
//                                         margin: EdgeInsets.symmetric(
//                                             vertical: 13.h),
//                                         child: Row(
//                                           children: [
//                                             CircleAvatar(
//                                               backgroundColor:
//                                                   primaryColor.withOpacity(0.2),
//                                               radius: 29.h,
//                                               child: Padding(
//                                                 padding: EdgeInsets.all(3.h),
//                                                 child: ClipRRect(
//                                                   borderRadius:
//                                                       BorderRadius.circular(
//                                                           200.r),
//                                                   child: rooms![index]
//                                                                   .profilePic![
//                                                               userId] !=
//                                                           null
//                                                       ? CachedNetworkImage(
//                                                           imageUrl:
//                                                               rooms![index]
//                                                                   .profilePic![
//                                                                       userId]
//                                                                   .toString(),
//                                                           width:
//                                                               double.infinity,
//                                                           height:
//                                                               double.infinity,
//                                                           fit: BoxFit.cover,
//                                                           placeholder:
//                                                               (context, url) =>
//                                                                   const Center(
//                                                             child:
//                                                                 CircularProgressIndicator(),
//                                                           ),
//                                                           errorWidget: (context,
//                                                                   url, error) =>
//                                                               const Icon(
//                                                                   Icons.error),
//                                                         )
//                                                       : Icon(
//                                                           IconlyBold.profile,
//                                                           size: 30.h,
//                                                         ),
//                                                 ),
//                                               ),
//                                             ),
//                                             SizedBox(
//                                               width: 10.w,
//                                             ),
//                                             Expanded(
//                                               flex: 3,
//                                               child: Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Row(
//                                                     children: [
//                                                       Expanded(
//                                                         child: Row(
//                                                           children: [
//                                                             Text(
//                                                               rooms![index]
//                                                                   .username![
//                                                                       userId]
//                                                                   .toString(),
//                                                               style: TextStyle(
//                                                                 fontSize: 18.sp,
//                                                                 color: Colors
//                                                                     .black,
//                                                                 fontWeight:
//                                                                     FontWeight
//                                                                         .w600,
//                                                               ),
//                                                             ),
//                                                             SizedBox(
//                                                               width: 6.w,
//                                                             ),
//                                                             Icon(
//                                                               Icons
//                                                                   .check_circle,
//                                                               color: blueColor,
//                                                               size: 16.h,
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ),
//                                                       Text(
//                                                         formatPostDate(
//                                                           DateTime.parse(
//                                                             rooms![index]
//                                                                 .lastMessageTime!
//                                                                 .toDate()
//                                                                 .toString(),
//                                                           ),
//                                                         ),
//                                                         maxLines: 1,
//                                                         overflow: TextOverflow
//                                                             .ellipsis,
//                                                         style: TextStyle(
//                                                           fontSize: 13.sp,
//                                                           color: Colors.black
//                                                               .withOpacity(0.4),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   StreamBuilder(
//                                                     stream: FirebaseFirestore
//                                                         .instance
//                                                         .collection('Chats')
//                                                         .doc(rooms![index].id)
//                                                         .collection('messages')
//                                                         .snapshots(),
//                                                     builder:
//                                                         (context, snapshot) {
//                                                       if (snapshot.hasData) {
//                                                         unreadList = snapshot
//                                                             .data!.docs
//                                                             .map((e) =>
//                                                                 MessageModel
//                                                                     .fromJson(e
//                                                                         .data()))
//                                                             .where((element) =>
//                                                                 element.read ==
//                                                                 '')
//                                                             .where((element) =>
//                                                                 element
//                                                                     .fromId !=
//                                                                 uId)
//                                                             .toList();
//
//                                                         return Row(
//                                                           children: [
//                                                             if (unreadList
//                                                                 .isEmpty)
//                                                               SizedBox(
//                                                                   width: 4.w),
//                                                             Expanded(
//                                                               child: (rooms![index].lastMessage!.contains(
//                                                                               '.png') ||
//                                                                           rooms![index].lastMessage!.contains(
//                                                                               '.jpg')) &&
//                                                                       unreadList
//                                                                           .isNotEmpty
//                                                                   ? Row(
//                                                                       children: [
//                                                                         Text(
//                                                                           "press and hold to view image  ",
//                                                                           maxLines:
//                                                                               1,
//                                                                           overflow:
//                                                                               TextOverflow.ellipsis,
//                                                                           style:
//                                                                               TextStyle(
//                                                                             fontSize:
//                                                                                 15.sp,
//                                                                             color:
//                                                                                 Colors.blueAccent,
//                                                                           ),
//                                                                         ),
//                                                                         Icon(
//                                                                           IconlyBold
//                                                                               .image,
//                                                                           size:
//                                                                               20.h,
//                                                                           color:
//                                                                               Colors.blueAccent,
//                                                                         ),
//                                                                       ],
//                                                                     )
//                                                                   : Text(
//                                                                       rooms![index].lastMessage ==
//                                                                               ''
//                                                                           ? 'Send ${rooms![index].username![userId]} a message'
//                                                                           : rooms![index]
//                                                                               .lastMessage
//                                                                               .toString(),
//                                                                       maxLines:
//                                                                           1,
//                                                                       overflow:
//                                                                           TextOverflow
//                                                                               .ellipsis,
//                                                                       style:
//                                                                           TextStyle(
//                                                                         fontSize:
//                                                                             15.sp,
//                                                                         color: rooms![index].lastMessage ==
//                                                                                 ''
//                                                                             ? primaryColor
//                                                                             : unreadList.isEmpty
//                                                                                 ? Colors.black.withOpacity(0.8)
//                                                                                 : primaryColor,
//                                                                       ),
//                                                                     ),
//                                                             ),
//                                                             SizedBox(
//                                                                 width: 8.w),
//                                                             if (unreadList
//                                                                 .isNotEmpty)
//                                                               Container(
//                                                                 padding: const EdgeInsets
//                                                                     .symmetric(
//                                                                     horizontal:
//                                                                         10,
//                                                                     vertical:
//                                                                         4),
//                                                                 decoration:
//                                                                     BoxDecoration(
//                                                                   color: Colors
//                                                                       .blueAccent,
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               25),
//                                                                 ),
//                                                                 child: Text(
//                                                                   unreadList.length >
//                                                                           99
//                                                                       ? "99+"
//                                                                       : "${unreadList.length}",
//                                                                   style:
//                                                                       TextStyle(
//                                                                     color: Colors
//                                                                         .white,
//                                                                     fontSize:
//                                                                         12.sp,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                           ],
//                                                         );
//                                                       } else {
//                                                         return const Center(
//                                                           child:
//                                                               CircularProgressIndicator(),
//                                                         );
//                                                       }
//                                                     },
//                                                   ),
//                                                   // Row(
//                                                   //   children: [
//                                                   //     Expanded(
//                                                   //       child: Text(
//                                                   //         'Hi there i hope everything is going well',
//                                                   //         maxLines: 1,
//                                                   //         overflow: TextOverflow
//                                                   //             .ellipsis,
//                                                   //         style: TextStyle(
//                                                   //           fontSize: 15.sp,
//                                                   //           color: Colors.black
//                                                   //               .withOpacity(
//                                                   //                   0.8),
//                                                   //         ),
//                                                   //       ),
//                                                   //     ),
//                                                   //     SizedBox(width: 8.w),
//                                                   //     Container(
//                                                   //       padding:
//                                                   //           const EdgeInsets
//                                                   //               .symmetric(
//                                                   //               horizontal: 10,
//                                                   //               vertical: 4),
//                                                   //       decoration:
//                                                   //           BoxDecoration(
//                                                   //         color: primaryColor,
//                                                   //         borderRadius:
//                                                   //             BorderRadius
//                                                   //                 .circular(25),
//                                                   //       ),
//                                                   //       child: Text(
//                                                   //         "99+",
//                                                   //         style: TextStyle(
//                                                   //           color: Colors.white,
//                                                   //           fontSize: 12.sp,
//                                                   //         ),
//                                                   //       ),
//                                                   //     ),
//                                                   //   ],
//                                                   // )
//                                                 ],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               },
//                             )
//                           : Center(
//                               child: Column(
//                                 children: [
//                                   SizedBox(
//                                     height: 50.h,
//                                   ),
//                                   const Icon(
//                                     Icons.error_outline_rounded,
//                                     color: primaryColor,
//                                     size: 50,
//                                   ),
//                                   SizedBox(
//                                     height: 10.h,
//                                   ),
//                                   Text(
//                                     'No Chats Found',
//                                     style: TextStyle(
//                                       fontSize: 20.sp,
//                                       fontWeight: FontWeight.w800,
//                                       color: textColor,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                     } else {
//                       return const Center(
//                         child: CircularProgressIndicator(),
//                       );
//                     }
//                   },
//                 ),
//                 SizedBox(
//                   height: 0.1.sh,
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
