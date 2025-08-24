import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class ShopGridShimmer extends StatelessWidget {
  const ShopGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 3.w,
        childAspectRatio: 0.8,
      ),
      delegate: SliverChildBuilderDelegate(
        childCount: 10,
        (context, index) => RepaintBoundary(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  strokeAlign: BorderSide.strokeAlignOutside,
                  color: formFieldColor,
                ),
                borderRadius: BorderRadius.circular(15.r),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: shimmerPlaceholder(
                          width: double.infinity,
                          height: 130.h,
                          radius: 0,
                        ),
                      ),
                      Positioned(
                        left: 5,
                        bottom: 5,
                        child: // Shop Rate
                            Icon(
                          Icons.star_rounded,
                          color: CupertinoColors.systemYellow,
                          size: 20.h,
                        ),
                      ),
                      Positioned(
                        right: 5.w,
                        top: 5.h,
                        child: Container(
                          padding: EdgeInsets.all(9.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(200),
                          ),
                          child: Icon(
                            CupertinoIcons.heart,
                            color: primaryColor,
                            size: 23.h,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 87.h,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100.r),
                              border: Border.all(color: Colors.white),
                            ),
                            child: shimmerPlaceholder(
                              width: 55,
                              height: 55,
                              radius: 100.r,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5.w, 25, 5.w, 7.h),
                    child: Column(
                      spacing: 5,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          spacing: 5,
                          children: [
                            shimmerPlaceholder(
                              width: 40,
                              height: 10,
                              radius: 5.r,
                            ),
                            shimmerPlaceholder(
                              width: 40,
                              height: 10,
                              radius: 5.r,
                            ),
                          ],
                        ),
                        shimmerPlaceholder(width: 120, height: 10, radius: 5.r),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
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
                              shimmerPlaceholder(
                                width: 50,
                                height: 15,
                                radius: 5.r,
                              ),
                            ],
                          ),
                        ),
                      ],
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
