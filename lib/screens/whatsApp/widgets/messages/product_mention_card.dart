import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/chat/message.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:matajer/constants/vars.dart';

class ProductMentionCard extends StatelessWidget {
  const ProductMentionCard({
    super.key,
    required this.isMe,
    required this.message,
  });

  final bool isMe;
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildProductCard(context),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isMe ? senderColor : receiverColor,
              borderRadius: const BorderRadius.only(
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
                      message.text ?? 'Unsupported message type',
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
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .doc(message.productMentionId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(7),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomLeft: Radius.circular(isMe ? 12 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 12),
              ),
              border: Border.all(
                color: senderColor,
                width: 1,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 2,
                      child: shimmerPlaceholder(
                        height: 130,
                        width: 100,
                        radius: 12,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          shimmerPlaceholder(height: 20, width: 140, radius: 8),
                          const SizedBox(height: 8),
                          shimmerPlaceholder(
                            height: 10,
                            width: double.infinity,
                            radius: 6,
                          ),
                          const SizedBox(height: 4),
                          shimmerPlaceholder(
                            height: 10,
                            width: double.infinity,
                            radius: 6,
                          ),
                          const SizedBox(height: 4),
                          shimmerPlaceholder(height: 10, width: 200, radius: 6),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    shimmerPlaceholder(
                                      height: 14,
                                      width: 40,
                                      radius: 6,
                                    ),
                                    const SizedBox(height: 4),
                                    shimmerPlaceholder(
                                      height: 18,
                                      width: 30,
                                      radius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 50,
                                color: Colors.grey.withOpacity(0.3),
                              ),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    shimmerPlaceholder(
                                      height: 14,
                                      width: 40,
                                      radius: 6,
                                    ),
                                    const SizedBox(height: 4),
                                    shimmerPlaceholder(
                                      height: 18,
                                      width: 60,
                                      radius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 15),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      shimmerPlaceholder(height: 25, width: 25, radius: 100),
                      const SizedBox(width: 10),
                      Expanded(
                        child: shimmerPlaceholder(
                          height: 14,
                          width: double.infinity,
                          radius: 6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      shimmerPlaceholder(height: 30, width: 80, radius: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final productData = snapshot.data!.data();
        if (productData == null) {
          return const Text("Product not found");
        }

        final product = ProductModel.fromJson(
          productData as Map<String, dynamic>,
        );
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(isMe ? 12 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 12),
            ),
            border: Border.all(
              color: senderColor,
              width: 1,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: Stack(
            children: [
              if (product.images.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.images.length > 1
                          ? product.images[1]
                          : product.images.first,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.white.withOpacity(0.8)),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 140,
                          width: 100,
                          margin: const EdgeInsets.all(7),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          ),
                          child: product.images.isEmpty
                              ? Material(
                                  color: lightGreyColor.withOpacity(0.4),
                                  child: Center(
                                    child: Icon(IconlyLight.image, size: 50),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: product.images.first,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                height: 1.1,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            // Text.rich(
                            //   TextSpan(
                            //     children: buildStyledText(
                            //       "${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}${product.description}",
                            //       13,
                            //     ),
                            //   ),
                            //   overflow: TextOverflow.ellipsis,
                            //   maxLines: 2,
                            // ),
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(S.of(context).rates),
                                        Text(
                                          product.numberOfRating.toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 4,
                                    height: 50,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        Text(S.of(context).price),
                                        // Price
                                        if (product.discount <= 0)
                                          Text(
                                            formatNumberWithCommas(
                                              product.price.toDouble(),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),

                                        // Discounted Price
                                        if (product.discount > 0)
                                          Text(
                                            formatNumberWithCommas(
                                              product.price -
                                                  product.price *
                                                      (product.discount / 100),
                                            ),
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.white,
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(100.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100.r),
                            child: CachedNetworkImage(
                              imageUrl: currentUserModel.profilePicture!,
                              height: 25,
                              width: 25,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  isMe
                                      ? '${S.of(context).viewed_by_you_and}${product.clicks - 1} ${S.of(context).others}'
                                      : '${S.of(context).viewed_by} ${product.shopName} ${S.of(context).and} +${product.clicks - 1} ${S.of(context).others}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductDetailsScreen(
                                            productModel: product,
                                          ),
                                    ),
                                  );
                                },
                                child: Text(S.of(context).view_details),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Discount badge
              if (product.discount > 0)
                Align(
                  alignment: lang == 'en'
                      ? Alignment.topLeft
                      : Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: lang == 'en'
                            ? Radius.circular(12)
                            : Radius.circular(0),
                        topRight: lang == 'ar'
                            ? Radius.circular(12)
                            : Radius.circular(0),
                        bottomRight: lang == 'en'
                            ? Radius.circular(8)
                            : Radius.circular(0),
                        bottomLeft: lang == 'ar'
                            ? Radius.circular(8)
                            : Radius.circular(0),
                      ),
                    ),
                    child: Row(
                      spacing: 5,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${product.discount}% ${S.of(context).off}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            'AED ${formatNumberWithCommas(product.price.toDouble())}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              height: 1.7,
                              decorationColor: Colors.white,
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
