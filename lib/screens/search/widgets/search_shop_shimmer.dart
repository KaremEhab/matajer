import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class SearchShopCardShimmer extends StatelessWidget {
  const SearchShopCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                    children: [
                      /// Shop logo shimmer
                      Material(
                        color: primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: shimmerPlaceholder(
                            height: 80,
                            width: 80,
                            radius: 12.r,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),

                      /// Right column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Shop name shimmer + verified icon
                          SizedBox(
                            width: 0.6.sw,
                            child: Row(
                              children: [
                                shimmerPlaceholder(
                                  height: 16,
                                  width: 120,
                                  radius: 5,
                                ),
                                SizedBox(width: 5),
                                shimmerPlaceholder(
                                  height: 14,
                                  width: 14,
                                  radius: 50,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 5),

                          /// Category chip shimmer
                          shimmerPlaceholder(height: 18, width: 80, radius: 5),
                          SizedBox(height: 5),

                          /// Rating row shimmer
                          Row(
                            children: [
                              shimmerPlaceholder(
                                height: 14,
                                width: 25,
                                radius: 4,
                              ),
                              SizedBox(width: 5),
                              shimmerPlaceholder(
                                height: 14,
                                width: 40,
                                radius: 4,
                              ),
                              SizedBox(width: 5),
                              shimmerPlaceholder(
                                height: 16,
                                width: 16,
                                radius: 8,
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
    );
  }
}
