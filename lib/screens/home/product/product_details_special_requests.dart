import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/whatsApp/chat_page.dart';

class ProductDetailsSpecialRequests extends StatefulWidget {
  const ProductDetailsSpecialRequests({super.key, required this.productModel});

  final ProductModel productModel;

  @override
  State<ProductDetailsSpecialRequests> createState() =>
      _ProductDetailsSpecialRequestsState();
}

class _ProductDetailsSpecialRequestsState
    extends State<ProductDetailsSpecialRequests>
    with AutomaticKeepAliveClientMixin {
  late final TextEditingController _messageController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessageAndNavigate(BuildContext context) async {
    final shopId = widget.productModel.shopId;
    final userId = currentUserModel.uId;
    final chatId = '${userId}_$shopId';

    final chatCubit = ChatsCubit.instance;
    await chatCubit.createChatRoom(userId: userId, shopId: shopId);

    if (!context.mounted) return;

    // Navigate immediately 🚀
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(
          chatId: chatId,
          receiverId: shopId,
          clearSendMessage: true,
          receiverName: widget.productModel.shopName,
          receiverImage: widget.productModel.shopLogo,
        ),
      ),
    );

    // Fire-and-forget message (don’t await)
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      unawaited(
        chatCubit.sendProductMentionMessage(
          chatId: chatId,
          senderId: userId,
          receiverId: shopId,
          message: message,
          product: widget.productModel,
        ),
      );
    }
    _messageController.clear();
  }

  void _openMessageModal(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    S.of(context).send_message_to_shop,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input field
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: S.of(context).type_your_message,
                      filled: true,
                      fillColor: formFieldColor.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _sendMessageAndNavigate(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Center(
                            child: Text(
                              S.of(context).send_message,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 130,
                child: SvgPicture.asset(
                  "images/special-requests-illustration.svg",
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => const SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              _buildTextAndButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextAndButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).go_to_chat_tip,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _openMessageModal(context),
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  S.of(context).go_to_chat,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.arrow_right_alt_rounded, color: primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
