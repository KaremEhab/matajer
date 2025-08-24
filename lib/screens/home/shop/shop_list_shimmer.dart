import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class ShopListShimmer extends StatelessWidget {
  const ShopListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: 10,
        (context, index) => RepaintBoundary(
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            margin: const EdgeInsets.fromLTRB(7, 2, 7, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: greyColor.withOpacity(0.2),
                width: 2,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    shimmerPlaceholder(
                      width: double.infinity,
                      height: 180,
                      radius: 22.r,
                    ),
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 5,
                            children: [
                              shimmerPlaceholder(
                                width: 100,
                                height: 20,
                                radius: 5.r,
                              ),
                              Icon(
                                Icons.verified_rounded,
                                color: primaryColor,
                                size: 20.h,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Shop SubCategories
                              Row(
                                spacing: 5,
                                children: [
                                  shimmerPlaceholder(
                                    width: 50,
                                    height: 15,
                                    radius: 5.r,
                                  ),
                                  shimmerPlaceholder(
                                    width: 50,
                                    height: 15,
                                    radius: 5.r,
                                  ),
                                  shimmerPlaceholder(
                                    width: 50,
                                    height: 15,
                                    radius: 5.r,
                                  ),
                                ],
                              ),

                              // Shop Rate
                              Row(
                                spacing: 5,
                                children: [
                                  shimmerPlaceholder(
                                    width: 60,
                                    height: 20,
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
                        ],
                      ),
                    ),
                  ],
                ),

                // Shop Logo Shimmer
                Positioned(
                  bottom: 67,
                  right: 11,
                  child: shimmerPlaceholder(
                    width: 73,
                    height: 73,
                    radius: 15.r,
                  ),
                ),

                // Favourite Icon Shimmer
                Positioned(
                  top: 11,
                  right: 11,
                  child: Container(
                    padding: EdgeInsets.all(9.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      CupertinoIcons.heart,
                      color: primaryColor,
                      size: 23.h,
                    ),
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
