import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/models/chat/message.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class ImageMessageCard extends StatelessWidget {
  const ImageMessageCard({
    super.key,
    required this.isMe,
    required this.message,
  });

  final bool isMe;
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          decoration: BoxDecoration(
            color: isMe ? senderColor : receiverColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntrinsicHeight(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: SizedBox(
                      height: 200.h,
                      width: double.infinity,
                      child:
                          message.mediaUrl == null
                              ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  shimmerPlaceholder(
                                    height: 200.h,
                                    width: double.infinity,
                                    radius: 8.r,
                                  ),
                                  if (context
                                          .read<ChatsCubit>()
                                          .uploadProgress[message.id] !=
                                      null)
                                    SizedBox(
                                      height: 100,
                                      width: 100,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value:
                                                  context
                                                      .read<ChatsCubit>()
                                                      .uploadProgress[message
                                                      .id],
                                              strokeWidth: 4,
                                              backgroundColor: Colors.white,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(primaryColor),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "${(context.read<ChatsCubit>().uploadProgress[message.id]! * 100).toStringAsFixed(0)}%",
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              )
                              : CachedNetworkImage(
                                imageUrl: message.mediaUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder:
                                    (context, url) => shimmerPlaceholder(
                                      height: 200.h,
                                      width: double.infinity,
                                      radius: 8.r,
                                    ),
                                errorWidget:
                                    (context, url, error) => const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  spacing: 5,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatTimestamp(message.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    if (isMe)
                      Icon(
                        message.isSeen ? Icons.done_all : Icons.done,
                        size: 16,
                        color: message.isSeen ? Colors.blue : Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
