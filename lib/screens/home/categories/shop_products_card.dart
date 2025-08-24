import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class ShopProductsCard extends StatelessWidget {
  const ShopProductsCard({
    super.key,
    required this.productModel,
    required this.onTap,
    required this.deleteButton,
    required this.isSelected,
    this.totalPrice,
    this.onLongPress, // ✅ Add to constructor
  });

  final ProductModel productModel;
  final void Function()? onTap, deleteButton, onLongPress;
  final bool isSelected;
  final double? totalPrice;

  @override
  Widget build(BuildContext context) {
    final filteredSubtitles = productModel.specifications
        .expand((spec) => spec.subTitles)
        .where(
          (sub) => colorNames.containsKey(
            sub.title.toLowerCase().replaceAll(' ', ''),
          ),
        )
        .toList();

    final hasColors = filteredSubtitles.isNotEmpty;

    final visibleTitles = getVisibleTitles(productModel);
    final hiddenCount = getHiddenTitlesCount(
      visibleTitles.length,
      productModel,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 0, 7, 8),
      child: Material(
        color: formFieldColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  lang == 'en' ? 10 : 15,
                  10,
                  lang == 'en' ? 15 : 10,
                  10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: productModel.discount > 0 ? 150.h : 115.h,
                        child:
                            (productModel.images.isNotEmpty &&
                                productModel.images.first.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: CachedNetworkImage(
                                  imageUrl: productModel.images.first,
                                  fit: BoxFit.cover,
                                  progressIndicatorBuilder:
                                      (context, url, downloadProgress) =>
                                          shimmerPlaceholder(
                                            width: double.infinity,
                                            height: double.infinity,
                                            radius: 16.r,
                                          ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              )
                            : Material(
                                color: lightGreyColor.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(16.r),
                                child: Center(
                                  child: Icon(IconlyLight.image, size: 45),
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5.60,
                        children: [
                          Text(
                            productModel.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            spacing: 5,
                            children: [
                              Expanded(
                                child: Text(
                                  productModel.quantity > 0
                                      ? S.of(context).in_stock
                                      : S.of(context).out_stock,
                                  style: TextStyle(
                                    color: productModel.quantity > 0
                                        ? CupertinoColors.systemGreen
                                        : CupertinoColors.systemRed,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              // Rating section
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "(${productModel.numberOfRating})",
                                    style: TextStyle(color: textColor),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    (productModel.numberOfRating == 0
                                            ? 0
                                            : (productModel.sumOfRating /
                                                  productModel.numberOfRating))
                                        .toStringAsFixed(1),
                                    style: TextStyle(color: textColor),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    size: 22.h,
                                    Icons.star_rounded,
                                    color: CupertinoColors.systemYellow,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (visibleTitles.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    visibleTitles.join(" - "),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                if (hiddenCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    height: 25,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '+$hiddenCount',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          Row(
                            spacing: 15,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              hasColors
                                  ? Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: () {
                                          final colorNum =
                                              productModel.discount <= 0
                                              ? 5
                                              : 2;
                                          final colorWidgets = <Widget>[];

                                          for (
                                            int i = 0;
                                            i < filteredSubtitles.length &&
                                                i < colorNum;
                                            i++
                                          ) {
                                            final sub = filteredSubtitles[i];
                                            final color =
                                                colorNames[sub.title
                                                    .toLowerCase()
                                                    .replaceAll(' ', '')]!;

                                            colorWidgets.add(
                                              Container(
                                                height: 25,
                                                width: 25,
                                                margin: const EdgeInsets.only(
                                                  right: 6,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: ShapeDecoration(
                                                  color: color,
                                                  shape: OvalBorder(
                                                    side: BorderSide(
                                                      width: 0.8,
                                                      color:
                                                          color.computeLuminance() >
                                                              0.5
                                                          ? Colors.black
                                                          : Colors.grey.shade300,
                                                    ),
                                                  ),
                                                ),
                                                child: Container(
                                                  decoration: ShapeDecoration(
                                                    color: color,
                                                    shape: OvalBorder(
                                                      side: BorderSide(
                                                        width: 1,
                                                        color:
                                                            color.computeLuminance() >
                                                                0.5
                                                            ? Colors.black
                                                            : Colors.grey.shade300,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          final extraCount =
                                              filteredSubtitles.length -
                                              colorNum;
                                          if (extraCount > colorNum) {
                                            colorWidgets.add(
                                              Container(
                                                height: 25,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(25),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '+$extraCount',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          return colorWidgets;
                                        }(),
                                      ),
                                    )
                                  : Flexible(
                                      child: Text.rich(
                                        TextSpan(
                                          children: buildStyledText(
                                            productModel.description,
                                            14,
                                          ),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),

                              if (productModel.discount <= 0)
                                Text(
                                  totalPrice == null
                                      ? 'AED ${formatNumberWithCommas(productModel.price.toDouble())}'
                                      : 'AED ${formatNumberWithCommas(totalPrice!.toDouble())}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                          if (productModel.discount > 0)
                            Row(
                              spacing: 5,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AED ${formatNumberWithCommas(productModel.price.toDouble())}',
                                  style: TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.red,
                                    color: Colors.red.withOpacity(0.5),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'AED ${formatNumberWithCommas(productModel.price.toDouble() - productModel.price.toDouble() * (productModel.discount.toDouble() / 100))}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Discount badge
              if (productModel.discount > 0)
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
                            ? Radius.circular(16)
                            : Radius.circular(0),
                        topRight: lang == 'ar'
                            ? Radius.circular(16)
                            : Radius.circular(0),
                        bottomRight: lang == 'en'
                            ? Radius.circular(12)
                            : Radius.circular(0),
                        bottomLeft: lang == 'ar'
                            ? Radius.circular(12)
                            : Radius.circular(0),
                      ),
                    ),
                    child: Text(
                      '${productModel.discount}% ${S.of(context).off}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              if (isSelected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),

              // delete button top left
              if (isSelected)
                Positioned(
                  top: 5,
                  left: 5,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: GestureDetector(
                      onTap: deleteButton,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          IconlyLight.delete,
                          color: Colors.red,
                          size: 20,
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
  }
}
