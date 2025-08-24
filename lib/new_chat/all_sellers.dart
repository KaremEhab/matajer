import 'package:cached_network_image/cached_network_image.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/new_chat/reciver_model.dart';

import 'chat_details_screen.dart';

class AllSellers extends StatefulWidget {
  const AllSellers({super.key});

  @override
  _AllSellersState createState() => _AllSellersState();
}

class _AllSellersState extends State<AllSellers> {
  bool display = false;
  TextEditingController searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    ProductCubit.get(context).getAllShops();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductGetAllSellersSuccessState) {
          display = true;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            leadingWidth: 62.w,
            leading: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 6, 0, 6),
              child: Material(
                color: lightGreyColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color: textColor,
                      size: 27.h,
                    ),
                  ),
                ),
              ),
            ),
            title: Text(
              'Choose a Seller',
              style: TextStyle(
                fontSize: 21.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: ConditionalBuilder(
            condition: display,
            builder:
                (context) => SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 15.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 60.h,
                          width: 0.92.sw,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15.r),
                              border: Border.all(
                                width: 2.w,
                                color: greyColor.withOpacity(0.3),
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                            ),
                            child: TextFormField(
                              controller: searchController,
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  ProductCubit.get(
                                    context,
                                  ).searchSellers(value);
                                } else {
                                  setState(() {
                                    searchController;
                                  });
                                }
                              },
                              onTapOutside: (focus) {
                                FocusScope.of(context).unfocus();
                              },
                              decoration: const InputDecoration(
                                fillColor: transparentColor,
                                hintText: "I'm Looking For...",
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                        ),
                        if (searchController.text.isEmpty)
                          ListView.builder(
                            itemCount:
                                ProductCubit.get(context).allShops.length,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final seller =
                                  ProductCubit.get(context).allShops[index];
                              return Column(
                                children: [
                                  SizedBox(height: index == 0 ? 20.h : 10.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Material(
                                      color: greyColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15.r),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        onTap: () {
                                          navigateTo(
                                            context: context,
                                            screen: ChatDetailsScreen(
                                              receiver: ReciverModel(
                                                uId: seller.sellerId,
                                                imageUrl: seller.shopLogoUrl,
                                                lastMessage: '',
                                                lastMessageDate: null,
                                                username: seller.shopName,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10.h,
                                            horizontal: 10.w,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Material(
                                                    color: primaryColor
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12.r,
                                                          ),
                                                      child: SizedBox(
                                                        height: 73.h,
                                                        width: 73.w,
                                                        child: Center(
                                                          child: CachedNetworkImage(
                                                            imageUrl:
                                                                seller
                                                                    .shopLogoUrl,
                                                            height: 73.h,
                                                            width: 73.w,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10.w),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                        width: 0.48.sw,
                                                        child: Text(
                                                          seller.shopName,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 18.sp,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 3.h),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      15.w,
                                                                  vertical: 2.h,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: greyColor
                                                                  .withOpacity(
                                                                    0.15,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    5.r,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              seller
                                                                  .shopCategory,
                                                              style: TextStyle(
                                                                fontSize: 11.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    greyColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 7.h),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "4.8",
                                                            style: TextStyle(
                                                              fontSize: 15.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                          SizedBox(width: 2.w),
                                                          Text(
                                                            "(325)",
                                                            style: TextStyle(
                                                              fontSize: 15.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: greyColor,
                                                            ),
                                                          ),
                                                          SizedBox(width: 3.w),
                                                          Icon(
                                                            size: 22.h,
                                                            Icons.star_rounded,
                                                            color:
                                                                CupertinoColors
                                                                    .systemYellow,
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
                                  ),
                                ],
                              );
                            },
                          ),
                        if (searchController.text.isNotEmpty)
                          ListView.builder(
                            itemCount:
                                ProductCubit.get(
                                  context,
                                ).sellersSearchResults.length,
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final seller =
                                  ProductCubit.get(
                                    context,
                                  ).sellersSearchResults[index];
                              return Column(
                                children: [
                                  SizedBox(height: index == 0 ? 20.h : 10.h),
                                  SizedBox(
                                    width: double.infinity,
                                    child: Material(
                                      color: greyColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15.r),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          15.r,
                                        ),
                                        onTap: () {
                                          navigateTo(
                                            context: context,
                                            screen: ChatDetailsScreen(
                                              receiver: ReciverModel(
                                                uId: seller.sellerId,
                                                imageUrl: seller.shopLogoUrl,
                                                lastMessage: '',
                                                lastMessageDate: null,
                                                username: seller.shopName,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10.h,
                                            horizontal: 10.w,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Material(
                                                    color: primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                    child: SizedBox(
                                                      height: 73.h,
                                                      width: 73.w,
                                                      child: Center(
                                                        child: CachedNetworkImage(
                                                          imageUrl:
                                                              seller
                                                                  .shopLogoUrl,
                                                          height: 73.h,
                                                          width: 73.w,
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10.w),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                        width: 0.48.sw,
                                                        child: Text(
                                                          seller.shopName,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 18.sp,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: textColor,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(height: 3.h),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      15.w,
                                                                  vertical: 2.h,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: greyColor
                                                                  .withOpacity(
                                                                    0.15,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    5.r,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              seller
                                                                  .shopCategory,
                                                              style: TextStyle(
                                                                fontSize: 11.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    greyColor,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 7.h),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            "4.8",
                                                            style: TextStyle(
                                                              fontSize: 15.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                          SizedBox(width: 2.w),
                                                          Text(
                                                            "(325)",
                                                            style: TextStyle(
                                                              fontSize: 15.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: greyColor,
                                                            ),
                                                          ),
                                                          SizedBox(width: 3.w),
                                                          Icon(
                                                            size: 22.h,
                                                            Icons.star_rounded,
                                                            color:
                                                                CupertinoColors
                                                                    .systemYellow,
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
                                  ),
                                ],
                              );
                            },
                          ),
                        SizedBox(height: 0.1.sh),
                      ],
                    ),
                  ),
                ),
            fallback:
                (context) => const Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
          ),
        );
      },
    );
  }
}
