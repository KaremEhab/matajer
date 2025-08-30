import 'package:cached_network_image/cached_network_image.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/order/order_state.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/screens/orders/order_details_screen.dart';

class SellerHome extends StatefulWidget {
  const SellerHome({super.key});

  @override
  State<SellerHome> createState() => _SellerHomeState();
}

class _SellerHomeState extends State<SellerHome> {
  TextEditingController searchController = TextEditingController();
  int selectedTab = 0;

  bool display = false;
  bool displayOrders = false;

  @override
  void initState() {
    super.initState();
    OrderCubit.get(context).ordersScreenInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        leadingWidth: 53,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).hello},',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            Text(
              currentShopModel!.shopName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(
              right: lang == 'en' ? 7 : 0,
              left: lang == 'en' ? 0 : 7,
              top: 1,
              bottom: 1,
            ),
            padding: EdgeInsets.all(4),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(200),
              border: Border.all(
                color: greyColor.withOpacity(0.7),
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(200),
              child: CachedNetworkImage(
                imageUrl: currentShopModel!.shopLogoUrl,
                width: 45,
                height: 50,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const CupertinoActivityIndicator(),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.error, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state is OrderOrderScreenInitSuccessState) {
            display = true;
          } else if (state is OrderGetSellerOrdersSuccessState) {
            displayOrders = true;
          }
        },
        builder: (context, state) {
          return ConditionalBuilder(
            condition: display,
            builder: (context) => CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // --- Summary card ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(15.r),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 10),
                                  blurRadius: 8,
                                  color: primaryColor.withOpacity(0.5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 7),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      S.of(context).your_orders_summary,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Icon(
                                    //   Icons.more_horiz_rounded,
                                    //   color: Colors.white,
                                    //   size: 25.h,a
                                    // ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          S.of(context).pending_orders,
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              OrderCubit.get(
                                                context,
                                              ).pendingOrdersCount.toString(),
                                              style: TextStyle(
                                                fontSize: 50.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              OrderCubit.get(
                                                        context,
                                                      ).pendingOrdersCount >
                                                      1
                                                  ? S.of(context).orders
                                                  : S.of(context).order,
                                              style: TextStyle(
                                                height: 2.5,
                                                fontSize: 20.sp,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          S.of(context).fulfilled_orders,
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(
                                              0.6,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              OrderCubit.get(
                                                context,
                                              ).fulfilledOrdersCount.toString(),
                                              style: TextStyle(
                                                fontSize: 50.sp,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              OrderCubit.get(
                                                        context,
                                                      ).fulfilledOrdersCount >
                                                      1
                                                  ? S.of(context).orders
                                                  : S.of(context).order,
                                              style: TextStyle(
                                                height: 2.6,
                                                fontSize: 20.sp,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          S.of(context).your_orders,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                    ),
                  ),
                ),

                // --- Sticky Active / History buttons ---
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyHeaderDelegate(
                    height: 60, // must match child height
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: BlocBuilder<ProductCubit, ProductState>(
                        builder: (context, state) {
                          final activeCount = OrderCubit.get(
                            context,
                          ).activeOrders.length;
                          final fulfilledCount = OrderCubit.get(
                            context,
                          ).historyOrders.length;
                          return Container(
                            color: Colors.white,
                            height: 50,
                            padding: EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Material(
                                    color: selectedTab == 0
                                        ? primaryColor
                                        : lightGreyColor.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12.r),
                                      onTap: () {
                                        selectedTab = 0;
                                        displayOrders = false;
                                        OrderCubit.get(
                                          context,
                                        ).getSellerActiveOrders();
                                      },
                                      child: Center(
                                        child: Text(
                                          "${S.of(context).active} ${OrderCubit.get(context).activeOrdersCount}",
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w700,
                                            color: selectedTab == 0
                                                ? Colors.white
                                                : greyColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Material(
                                    color: selectedTab == 1
                                        ? primaryColor
                                        : lightGreyColor.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(12.r),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12.r),
                                      onTap: () {
                                        selectedTab = 1;
                                        displayOrders = false;
                                        OrderCubit.get(
                                          context,
                                        ).getSellerHistoryOrders();
                                      },
                                      child: Center(
                                        child: Text(
                                          "${S.of(context).history} ${OrderCubit.get(context).fulfilledOrdersCount}",
                                          style: TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w700,
                                            color: selectedTab == 1
                                                ? Colors.white
                                                : greyColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // --- Orders list ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Center(
                      child: ConditionalBuilder(
                        condition: displayOrders,
                        builder: (context) =>
                            (selectedTab == 0
                                ? OrderCubit.get(
                                    context,
                                  ).activeOrders.isNotEmpty
                                : OrderCubit.get(
                                    context,
                                  ).historyOrders.isNotEmpty)
                            ? ListView.builder(
                                itemCount: selectedTab == 0
                                    ? OrderCubit.get(
                                        context,
                                      ).activeOrders.length
                                    : OrderCubit.get(
                                        context,
                                      ).historyOrders.length,
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  OrderModel order = selectedTab == 0
                                      ? OrderCubit.get(
                                          context,
                                        ).activeOrders[index]
                                      : OrderCubit.get(
                                          context,
                                        ).historyOrders[index];
                                  final status = order.orderStatus;

                                  return Column(
                                    children: [
                                      SizedBox(height: 13),
                                      Material(
                                        color: lightGreyColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          22.r,
                                        ),
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            22.r,
                                          ),
                                          onTap: () {
                                            navigateTo(
                                              context: context,
                                              screen: OrderDetailsScreen(
                                                order: order,
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            clipBehavior:
                                                Clip.antiAliasWithSaveLayer,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(22.r),
                                              border: Border.all(
                                                color: textColor.withOpacity(
                                                  0.1,
                                                ),
                                                strokeAlign: BorderSide
                                                    .strokeAlignOutside,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.fromLTRB(
                                                15,
                                                15,
                                                15,
                                                20,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    order.id,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: textColor,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Divider(
                                                    color: greyColor
                                                        .withOpacity(0.15),
                                                    thickness: 3,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          // correct
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                S
                                                                    .of(context)
                                                                    .buyer_name,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color: greyColor
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              Text(
                                                                order.buyerName,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color: textColor
                                                                      .withOpacity(
                                                                        0.8,
                                                                      ),
                                                                  fontSize: 17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 8),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                S
                                                                    .of(context)
                                                                    .order_status,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color: greyColor
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 3,
                                                              ),
                                                              Material(
                                                                color:
                                                                    getStatusBackgroundColor(
                                                                      status,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      6.r,
                                                                    ),
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            15,
                                                                        vertical:
                                                                            3,
                                                                      ),
                                                                  child: Row(
                                                                    children: [
                                                                      Icon(
                                                                        IconlyLight
                                                                            .document,
                                                                        color: getStatusTextColor(
                                                                          status,
                                                                        ),
                                                                        size:
                                                                            17,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            3,
                                                                      ),
                                                                      Text(
                                                                        getTranslatedOrderStatus(
                                                                          context,
                                                                          status,
                                                                        ),
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.w700,
                                                                          color: getStatusTextColor(
                                                                            status,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(width: 5),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                S
                                                                    .of(context)
                                                                    .buyer_phone,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color: greyColor
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              Text(
                                                                order.buyerPhone !=
                                                                        ""
                                                                    ? order
                                                                          .buyerPhone
                                                                    : S
                                                                          .of(
                                                                            context,
                                                                          )
                                                                          .not_added,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                textDirection:
                                                                    TextDirection
                                                                        .ltr,
                                                                style: TextStyle(
                                                                  color: textColor
                                                                      .withOpacity(
                                                                        0.8,
                                                                      ),
                                                                  fontSize: 17,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          SizedBox(height: 8),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                S
                                                                    .of(context)
                                                                    .order_price,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color: greyColor
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                              Text(
                                                                'AED ${formatNumberWithCommas(order.price.toDouble())}',
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color:
                                                                      primaryColor,
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                ),
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
                              )
                            : Column(
                                children: [
                                  SizedBox(height: 50),
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: primaryColor,
                                    size: 50,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    S.of(context).no_orders_found,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                        fallback: (context) => Column(
                          children: [
                            SizedBox(height: 50),
                            const CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
            fallback: (context) => const Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        },
      ),
    );
  }
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyHeaderDelegate({
    required this.child,
    this.height = 50, // <-- Match the SizedBox height
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
