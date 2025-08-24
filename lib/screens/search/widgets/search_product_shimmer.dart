import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class SearchProductCardShimmer extends StatelessWidget {
  const SearchProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
              /// Top Product Info Section
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
                      /// Product image shimmer
                      Container(
                        margin: EdgeInsets.fromLTRB(7, 7, 10, 7),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: greyColor.withOpacity(0.2),
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: shimmerPlaceholder(
                            height: 120,
                            width: 120,
                            radius: 13,
                          ),
                        ),
                      ),

                      /// Text content shimmer
                      Padding(
                        padding: const EdgeInsets.only(
                          right: 15,
                          bottom: 15,
                          top: 15,
                        ),
                        child: Column(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            shimmerPlaceholder(
                              height: 16,
                              width: 120,
                              radius: 4,
                            ),
                            shimmerPlaceholder(
                              height: 12,
                              width: 160,
                              radius: 4,
                            ),
                            shimmerPlaceholder(
                              height: 12,
                              width: 180,
                              radius: 4,
                            ),
                            shimmerPlaceholder(
                              height: 12,
                              width: 100,
                              radius: 4,
                            ),
                            Row(
                              spacing: 5,
                              children: [
                                shimmerPlaceholder(
                                  height: 14,
                                  width: 30,
                                  radius: 3,
                                ),
                                shimmerPlaceholder(
                                  height: 18,
                                  width: 50,
                                  radius: 4,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 10),

              /// Shop Info Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  spacing: 10,
                  children: [
                    /// Shop logo shimmer
                    shimmerPlaceholder(height: 57, width: 57, radius: 10),
                    SizedBox(width: 10),

                    /// Shop name & rating
                    Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        shimmerPlaceholder(height: 14, width: 100, radius: 4),
                        SizedBox(height: 4),
                        Row(
                          spacing: 3,
                          children: [
                            shimmerPlaceholder(
                              height: 12,
                              width: 25,
                              radius: 3,
                            ),
                            shimmerPlaceholder(
                              height: 12,
                              width: 30,
                              radius: 3,
                            ),
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
              ),

              SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }
}
