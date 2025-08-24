import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class ShopProductsShimmer extends StatelessWidget {
  const ShopProductsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: 10,
        (context, index) => RepaintBoundary(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(10, 10, 15, 10),
            margin: const EdgeInsets.fromLTRB(7, 0, 7, 8),
            decoration: BoxDecoration(
              color: formFieldColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              spacing: 10,
              children: [
                Expanded(
                  child: shimmerPlaceholder(
                    width: double.infinity,
                    height: 115,
                    radius: 16.r,
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
                      shimmerPlaceholder(
                        width: double.infinity,
                        height: 20,
                        radius: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 5,
                        children: [
                          shimmerPlaceholder(width: 50, height: 15, radius: 5),

                          // Product Rate
                          Row(
                            spacing: 5,
                            children: [
                              shimmerPlaceholder(
                                width: 40,
                                height: 10,
                                radius: 5.r,
                              ),
                              Icon(
                                Icons.star_rounded,
                                color: CupertinoColors.systemYellow,
                                size: 20.h,
                              ),
                            ],
                          ),
                        ],
                      ),
                      shimmerPlaceholder(width: 80, height: 15, radius: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 25,
                                width: 25,
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.all(2),
                                decoration: ShapeDecoration(
                                  color: formFieldColor,
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 0.8,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  decoration: ShapeDecoration(
                                    color: formFieldColor,
                                    shape: OvalBorder(
                                      side: BorderSide(
                                        width: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  child: shimmerPlaceholder(
                                    width: 25,
                                    height: 25,
                                    radius: 100.r,
                                  ),
                                ),
                              ),
                              Container(
                                height: 25,
                                width: 25,
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.all(2),
                                decoration: ShapeDecoration(
                                  color: formFieldColor,
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 0.8,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  decoration: ShapeDecoration(
                                    color: formFieldColor,
                                    shape: OvalBorder(
                                      side: BorderSide(
                                        width: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  child: shimmerPlaceholder(
                                    width: 25,
                                    height: 25,
                                    radius: 100.r,
                                  ),
                                ),
                              ),
                              Container(
                                height: 25,
                                width: 25,
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.all(2),
                                decoration: ShapeDecoration(
                                  color: formFieldColor,
                                  shape: OvalBorder(
                                    side: BorderSide(
                                      width: 0.8,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  decoration: ShapeDecoration(
                                    color: formFieldColor,
                                    shape: OvalBorder(
                                      side: BorderSide(
                                        width: 1,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  child: shimmerPlaceholder(
                                    width: 25,
                                    height: 25,
                                    radius: 100.r,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          shimmerPlaceholder(width: 80, height: 25, radius: 5),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
