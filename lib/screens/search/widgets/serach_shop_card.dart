import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/shop_screen.dart';

class SearchShopCard extends StatefulWidget {
  final ShopModel shop;
  const SearchShopCard({super.key, required this.shop});

  @override
  State<SearchShopCard> createState() => _SearchShopCardState();
}

class _SearchShopCardState extends State<SearchShopCard>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // must call super.build
    return RepaintBoundary(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          navigateTo(
            context: context,
            screen: ShopScreen(shopModel: widget.shop),
          );
        },
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Material(
                color: greyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 10,
                        children: [
                          Material(
                            color: primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.r),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Center(
                                  child: CachedNetworkImage(
                                    imageUrl: widget.shop.shopLogoUrl,
                                    placeholder: (context, _) =>
                                        shimmerPlaceholder(
                                          height: 80,
                                          width: 80,
                                          radius: 12.r,
                                        ),
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Column(
                            spacing: 5,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 0.6.sw,
                                child: Row(
                                  spacing: 3,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.shop.shopName,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.verified,
                                      color: primaryColor,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: greyColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      widget.shop.shopCategory,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: greyColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                spacing: 3,
                                children: [
                                  Text(widget.shop.sumOfRating.toString()),
                                  Text("(${widget.shop.numberOfRating})"),
                                  Icon(
                                    size: 22,
                                    Icons.star_rounded,
                                    color: CupertinoColors.systemYellow,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
