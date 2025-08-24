import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/models/cart_product_item_model.dart';
import 'package:matajer/models/chat/message.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/screens/my_cart/basket.dart';
import 'package:matajer/screens/whatsApp/offers.dart';

class SpecialOfferCard extends StatelessWidget {
  const SpecialOfferCard({
    super.key,
    required this.messageModel,
    required this.isMe,
  });

  final ChatMessageModel messageModel;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final userId = isSeller ? currentShopModel!.shopId : currentUserModel.uId;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(20.r),
                onTap: () {
                  navigateTo(
                    context: context,
                    screen: OffersPage(userId: userId),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: textColor.withOpacity(0.1),
                      width: 2.w,
                    ),
                  ),
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            spacing: 4,
                            children: [
                              Text(
                                DateFormat(
                                  "MMMM d",
                                ).format(messageModel.timestamp.toDate()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: textColor.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(
                                DateFormat(
                                  "hh:mma",
                                ).format(messageModel.timestamp.toDate()),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.more_horiz, size: 30),
                        ],
                      ),
                      Row(
                        spacing: 10,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: textColor.withOpacity(0.1),
                                width: 1.5,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundImage: NetworkImage(
                                messageModel.offer!.product.shopLogo,
                              ),
                              radius: 25,
                              onBackgroundImageError: (_, __) =>
                                  const Icon(Icons.error, color: Colors.red),
                            ),
                          ),

                          Expanded(
                            child: Column(
                              spacing: 5,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  messageModel.offer!.product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                Row(
                                  spacing: 5,
                                  children: [
                                    Text(
                                      messageModel.offer!.product.discount < 0
                                          ? 'AED ${formatNumberWithCommas(messageModel.offer!.product.price.toDouble())}'
                                          : 'AED ${formatNumberWithCommas(messageModel.offer!.product.price - messageModel.offer!.product.price * (messageModel.offer!.product.discount / 100))}',
                                      style: TextStyle(
                                        color: textColor.withOpacity(0.6),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.lineThrough,
                                        decorationThickness: 1.5,
                                      ),
                                    ),
                                    Text(
                                      'AED ${messageModel.offer!.newPrice}',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "3 items",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ],
                      ),
                      if (messageModel.offer!.expireDate != null &&
                          Timestamp.now().toDate().isAfter(
                            messageModel.offer!.expireDate!.toDate(),
                          ))
                        Material(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 17),
                              child: Text(
                                'OFFER EXPIRED',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (userId == messageModel.senderId)
                        Material(
                          color: CupertinoColors.systemGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 17),
                              child: Text(
                                'OFFER SENT',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: CupertinoColors.systemGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Row(
                          spacing: 5,
                          children: [
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () {},
                                child: Material(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 17,
                                      ),
                                      child: Text(
                                        'DECLINE',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: () async {
                                  if (ProductCubit.get(
                                    context,
                                  ).cartProducts.isNotEmpty) {
                                    AlertDialog alert = AlertDialog(
                                      title: const Text("Warning"),
                                      content: const Text(
                                        "Are you sure you want clear the cart to buy this offer now?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () async {
                                            await ProductCubit.get(
                                              context,
                                            ).clearCart();
                                            if (!context.mounted) return;
                                            await ProductCubit.get(
                                              context,
                                            ).addProductToCart(
                                              product: CartProductItemModel(
                                                product:
                                                    messageModel.offer!.product,
                                                quantity: 1,
                                                isOffer: true,
                                              ),
                                            );
                                            if (!context.mounted) return;
                                            await ChatsCubit.instance
                                                .expireOffer(
                                                  receiverId:
                                                      messageModel.senderId,
                                                  message: messageModel,
                                                );
                                            if (!context.mounted) return;
                                            navigateReplacement(
                                              context: context,
                                              screen: Basket(
                                                shopId: messageModel
                                                    .offer!
                                                    .product
                                                    .shopId,
                                              ),
                                            );
                                          },
                                          child: const Text("Yes"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("No"),
                                        ),
                                      ],
                                    );
                                    // show the dialog
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return alert;
                                      },
                                    );
                                  } else {
                                    if (!context.mounted) return;
                                    await ProductCubit.get(
                                      context,
                                    ).addProductToCart(
                                      product: CartProductItemModel(
                                        product: messageModel.offer!.product,
                                        quantity: 1,
                                        isOffer: true,
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    await ChatsCubit.instance.expireOffer(
                                      receiverId: messageModel.senderId,
                                      message: messageModel,
                                    );
                                    if (!context.mounted) return;
                                    navigateReplacement(
                                      context: context,
                                      screen: Basket(
                                        shopId:
                                            messageModel.offer!.product.shopId,
                                      ),
                                    );
                                  }
                                },
                                child: Material(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 17,
                                      ),
                                      child: Text(
                                        'ACCEPT OFFER',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
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
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? senderColor : receiverColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
            ),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: buildStyledText(
                      messageModel.offer!.description ??
                          'Unsupported messageModel type',
                      15,
                    ),
                  ),
                ),
                Row(
                  spacing: 5,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatTimestamp(messageModel.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    if (isMe)
                      Icon(
                        messageModel.isSeen ? Icons.done_all : Icons.done,
                        size: 16,
                        color: messageModel.isSeen ? Colors.blue : Colors.grey,
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
