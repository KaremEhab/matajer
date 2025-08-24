import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/generated/l10n.dart';

class TypingIndicator extends StatelessWidget {
  final String chatId, receiverTypingPath;

  const TypingIndicator({
    required this.chatId,
    required this.receiverTypingPath,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final isTyping = data[receiverTypingPath] ?? false;

        return isTyping
            ? Text(
              S.of(context).typing,
              style: TextStyle(fontSize: 12, color: textColor),
            )
            : const SizedBox.shrink();
      },
    );
  }
}
