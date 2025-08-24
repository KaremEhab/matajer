import 'package:flutter/material.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/models/chat/message.dart';

class AudioCard extends StatelessWidget {
  const AudioCard({super.key, required this.isMe, required this.message});

  final bool isMe;
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final chatCubit = ChatsCubit.instance;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  isMe ? "You sent a voice note" : "They sent a voice note",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              chatCubit.isLoadingMap[message.id] == true
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : IconButton(
                    icon: Icon(
                      (chatCubit.isPlayingMap[message.id] ?? false)
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed:
                        () => chatCubit.handlePlayPause(
                          message.id,
                          message.mediaUrl!,
                          context,
                        ),
                  ),
            ],
          ),
          Row(
            spacing: 5,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                formatTimestamp(message.timestamp),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
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
    );
  }
}
