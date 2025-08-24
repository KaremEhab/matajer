import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/chat/chat_state.dart';
import 'package:matajer/models/chat/message.dart';
import 'package:matajer/screens/whatsApp/widgets/messages/audio_message_card.dart';
import 'package:matajer/screens/whatsApp/widgets/messages/image_message_card.dart';
import 'package:matajer/screens/whatsApp/widgets/messages/product_mention_card.dart';
import 'package:matajer/screens/whatsApp/widgets/messages/special_offer_card.dart';

class BuildMessageCard extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final bool isSelected;
  final bool isSelecting;
  final Function(String messageId)? onSelect;

  const BuildMessageCard({
    super.key,
    required this.message,
    required this.isMe,
    this.isSelected = false,
    this.isSelecting = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => onSelect?.call(message.id),
      onTap: () {
        if (isSelecting) {
          onSelect?.call(message.id);
        }
      },
      child: Container(
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
        child: BlocConsumer<ChatsCubit, ChatsStates>(
          listener: (context, state) {},
          builder: (context, state) {
            switch (message.type) {
              case MessageType.offer:
                return SpecialOfferCard(isMe: isMe, messageModel: message);
              case MessageType.productMention:
                return ProductMentionCard(isMe: isMe, message: message);
              case MessageType.audio:
                return AudioCard(isMe: isMe, message: message);
              case MessageType.image:
                return ImageMessageCard(isMe: isMe, message: message);
              case MessageType.text:
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? senderColor : receiverColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      spacing: 5,
                      crossAxisAlignment:
                          isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text ?? 'Unsupported message',
                          style: const TextStyle(fontSize: 15),
                        ),
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
                                color:
                                    message.isSeen ? Colors.blue : Colors.grey,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              default:
                return const SizedBox.shrink();
            }
          },
        ),
      ),
    );
  }
}
