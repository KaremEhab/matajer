import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/widgets/expandable_text.dart';

class ProductDetailsTitleAndPrice extends StatelessWidget {
  const ProductDetailsTitleAndPrice({
    super.key,
    required this.cart,
    required this.orderedQuantity,
    required this.productModel,
    required this.counterNotifier,
    required this.totalPriceNotifier,
    required this.onPriceUpdate,
  });

  final bool cart;
  final int orderedQuantity;
  final ProductModel productModel;
  final ValueNotifier<int> counterNotifier;
  final ValueNotifier<num> totalPriceNotifier;
  final VoidCallback onPriceUpdate;

  @override
  Widget build(BuildContext context) {
    final num basePrice = productModel.price;

    return ValueListenableBuilder<int>(
      valueListenable: counterNotifier,
      builder: (_, count, __) {
        Stream<ProductModel> productStream(String productId) {
          return FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .snapshots()
              .map(
                (doc) => ProductModel.fromJson({...doc.data()!, 'id': doc.id}),
              );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          totalPriceNotifier.value = basePrice * count;
        });

        return RepaintBoundary(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 7.h),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productModel.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating section
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "(${productModel.numberOfRating})",
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              (productModel.numberOfRating == 0
                                      ? 0
                                      : (productModel.sumOfRating /
                                            productModel.numberOfRating))
                                  .toStringAsFixed(1),
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              size: 22.h,
                              Icons.star_rounded,
                              color: CupertinoColors.systemYellow,
                            ),
                          ],
                        ),
                        StreamBuilder<ProductModel>(
                          stream: productStream(productModel.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text(
                                "${productModel.quantity} ${S.of(context).left}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              );
                            }

                            if (!snapshot.hasData) {
                              return Text(
                                S.of(context).out_stock,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              );
                            }

                            final liveProduct = snapshot.data!;
                            return Text(
                              "${liveProduct.quantity} ${S.of(context).left}",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    CustomExpandableRichText(
                      textWidth: double.infinity,
                      textHeight: 1.3,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      maxLines: 3,
                      text: productModel.description,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        if (productModel.discount <= 0)
                          Text(
                            "AED ${formatNumberWithCommas(basePrice.toDouble())}",
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),

                        // Discounted Price
                        if (productModel.discount > 0)
                          Row(
                            spacing: 5,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'AED ${NumberFormat('#,###').format(productModel.price)}',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  height: 1.7,
                                  decorationColor: Colors.red,
                                  color: Colors.red.withOpacity(0.5),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'AED ${NumberFormat('#,###').format(productModel.price - productModel.price * (productModel.discount / 100))}',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),

                        // Quantity controls
                        if (productModel.sellerId != uId)
                          cart
                              ? Chip(
                                  backgroundColor: secondaryColor,
                                  side: BorderSide.none,
                                  label: Text(
                                    '${S.of(context).quantity}: $orderedQuantity',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    _quantityBtn(
                                      icon: Icons.remove,
                                      enabled: count > 1,
                                      onTap: () {
                                        counterNotifier.value--;
                                        onPriceUpdate();
                                      },
                                      color: count > 1
                                          ? Colors.red
                                          : greyColor.withOpacity(0.3),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    _quantityBtn(
                                      icon: Icons.add,
                                      enabled: productModel.quantity > 0,
                                      onTap: () {
                                        counterNotifier.value++;
                                        onPriceUpdate();
                                      },
                                      color: productModel.quantity > 0
                                          ? primaryColor
                                          : greyColor.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quantityBtn({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(6.r),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}
