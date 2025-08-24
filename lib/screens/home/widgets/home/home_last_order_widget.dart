import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/order/order_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/profile/orders.dart';
import 'package:matajer/widgets/order_card.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeLastOrderWidget extends StatefulWidget {
  const HomeLastOrderWidget({super.key});

  @override
  State<HomeLastOrderWidget> createState() => _HomeLastOrderWidgetState();
}

class _HomeLastOrderWidgetState extends State<HomeLastOrderWidget> {
  late final PageController _pageController;
  bool displayLastOrder = false;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    OrderCubit.get(context).getBuyerOrders();
    _pageController = PageController(viewportFraction: 0.98);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderGetBuyerOrdersSuccessState) {
          final hasOrders = OrderCubit.get(context).buyerOrders.isNotEmpty;
          setState(() => displayLastOrder = hasOrders);
          if (!hasOrders) homeCategoriesOffset = 0.4.sh;
        }
      },
      builder: (context, state) {
        final allOrders = OrderCubit.get(context).buyerOrders;
        final pendingOrders = allOrders.where((order) {
          // Check if all products in this order are rated
          final allRated = order.isRated == true;

          return !allRated;
        }).toList();

        if (!displayLastOrder && state is OrderGetBuyerOrdersLoadingState) {
          return SliverToBoxAdapter(child: buildShimmerFallback());
        } else if (pendingOrders.isEmpty) {
          return SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(
                height: 150,
                child: PageView.builder(
                  itemCount: pendingOrders.length > 5
                      ? 5
                      : pendingOrders.length, // 5 orders + 1 for "View All"
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    // Otherwise show the normal order card
                    final order = pendingOrders[index];
                    final product = order.products.first.product;
                    final totalQuantity = order.products.fold(
                      0,
                      (sum, p) => sum + p.quantity,
                    );

                    return Stack(
                      children: [
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: index == 4 || index == pendingOrders.length - 1
                                ? 0
                                : 7,
                          ),
                          child: OrderCard(
                            order: order,
                            product: product,
                            totalQuantity: totalQuantity,
                          ),
                        ),
                        // If this is the last card and orders are more than 5, show "View All"
                        if (index == 4)
                          Padding(
                            padding: EdgeInsetsDirectional.only(end: 7),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Material(
                                  color: secondaryColor.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    splashColor: secondaryColor.withOpacity(
                                      0.5,
                                    ),
                                    highlightColor: secondaryColor.withOpacity(
                                      0.5,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const OrdersHistory(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: primaryColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          S.of(context).view_all,
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              if (pendingOrders.length > 1) ...[
                const SizedBox(height: 8),
                SmoothPageIndicator(
                  controller: _pageController,
                  count: pendingOrders.length > 5 ? 5 : pendingOrders.length,
                  effect: WormEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: primaryColor,
                    dotColor: Colors.grey.withOpacity(0.4),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
