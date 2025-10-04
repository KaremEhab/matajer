import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/home/product_details.dart';

class SearchProductCard extends StatefulWidget {
  final ProductModel product;
  const SearchProductCard({super.key, required this.product});

  @override
  State<SearchProductCard> createState() => _SearchProductCardState();
}

class _SearchProductCardState extends State<SearchProductCard>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // must call super.build
    return RepaintBoundary(
      child: InkWell(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
        ),
        onTap: () {
          navigateTo(
            context: context,
            screen: ProductDetailsScreen(productModel: widget.product),
          );
        },
        child: Container(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            border: Border.all(
              color: greyColor.withOpacity(0.2),
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: Column(
            children: [
              Material(
                color: Colors.white,
                child: Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      topLeft: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(
                          lang == 'en' ? 7 : 10,
                          7,
                          lang == 'ar' ? 7 : 10,
                          7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: greyColor.withOpacity(0.2),
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: widget.product.images.isEmpty
                              ? SizedBox(
                                  height: 120,
                                  width: 120,
                                  child: Center(
                                    child: Icon(IconlyLight.image, size: 55),
                                  ),
                                )
                              : CachedNetworkImage(
                                  imageUrl: widget.product.images.first,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: lang == 'en' ? 15 : 0,
                            left: lang == 'ar' ? 15 : 0,
                          ),
                          child: Column(
                            spacing: 5,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: buildStyledText(
                                    widget.product.description,
                                    12,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 3,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 1),
                                    child: Text(
                                      "AED ",
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatNumberWithCommas(
                                      widget.product.price.toDouble(),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                      height: 1.3,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  spacing: 10,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: greyColor.withOpacity(0.2),
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: widget.product.shopLogo,
                          height: 57,
                          width: 57,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.shopName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        Row(
                          spacing: 3,
                          children: [
                            Text(
                              (widget.product.numberOfRating == 0
                                      ? 0
                                      : (widget.product.sumOfRating /
                                            widget.product.numberOfRating))
                                  .toStringAsFixed(1),
                            ),
                            Text("(${widget.product.numberOfRating})"),
                            Icon(
                              size: 18,
                              Icons.star_rounded,
                              color: CupertinoColors.systemYellow,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
