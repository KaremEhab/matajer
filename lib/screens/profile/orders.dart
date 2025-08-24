
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/order/order_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/widgets/order_card.dart';

class OrdersHistory extends StatefulWidget {
  const OrdersHistory({super.key});

  @override
  State<OrdersHistory> createState() => _OrdersHistoryState();
}

class _OrdersHistoryState extends State<OrdersHistory> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> orderScrollOffsetNotifier = ValueNotifier(0);
  bool display = false;

  @override
  void initState() {
    super.initState();
    OrderCubit.get(context).getBuyerOrders();
    _scrollController.addListener(() {
      orderScrollOffsetNotifier.value = _scrollController.position.pixels;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    orderScrollOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = OrderCubit.get(context).buyerOrders;

    return BlocConsumer<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderGetBuyerOrdersSuccessState) display = true;
      },
      builder: (context, state) {
        return ConditionalBuilder(
          condition: display,
          builder: (context) {
            if (orders.isEmpty) {
              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: primaryColor,
                          size: 50,
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          S.of(context).empty_orders,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Scaffold(
              body: SafeArea(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Scrollable AppBar
                    SliverAppBar(
                      pinned: true,
                      floating: false,
                      automaticallyImplyLeading: false,
                      forceMaterialTransparency: true,
                      titleSpacing: 0,
                      title: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 7,
                        ),
                        child: AppBar(
                          forceMaterialTransparency: true,
                          leadingWidth: 53,
                          leading: Padding(
                            padding: EdgeInsets.fromLTRB(
                              lang == 'en' ? 7 : 0,
                              6,
                              lang == 'en' ? 0 : 7,
                              6,
                            ),
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
                                    backIcon(),
                                    color: textColor,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          title: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                S.of(context).orders_history,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                currentUserModel.currentAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: greyColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          centerTitle: true,
                        ),
                      ),
                    ),

                    // Sticky last order
                    OrdersLastOrderWidget(
                      orderModel: orders[0],
                      orderScrollOffsetNotifier: orderScrollOffsetNotifier,
                    ),

                    SliverPadding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 7,
                        end: 7,
                        top: 10,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: OrderCard(
                          order: orders[0],
                          product: orders[0].products.first.product,
                          totalQuantity: orders[0].products.fold(
                            0,
                            (sum, p) => sum + p.quantity,
                          ),
                        ),
                      ),
                    ),

                    // Previous orders list
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index + 1 >= orders.length) return null;

                        final order = orders[index + 1];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (index == 0)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 10,
                                  top: 10,
                                ),
                                child: Text(
                                  S.of(context).previous_orders_status,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 7,
                                end: 7,
                                top: 10,
                              ),
                              child: OrderCard(
                                order: order,
                                product: order.products.first.product,
                                totalQuantity: order.products.fold(
                                  0,
                                  (sum, p) => sum + p.quantity,
                                ),
                              ),
                            ),
                          ],
                        );
                      }, childCount: orders.length - 1),
                    ),
                  ],
                ),
              ),
            );
          },
          fallback: (context) =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}

class OrdersLastOrderWidget extends StatelessWidget {
  final ValueListenable<double> orderScrollOffsetNotifier;
  final OrderModel orderModel;

  const OrdersLastOrderWidget({
    super.key,
    required this.orderModel,
    required this.orderScrollOffsetNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FixedHeightHeaderDelegate(
        orderScrollOffsetNotifier: orderScrollOffsetNotifier,
        orderModel: orderModel,
        height: 50, // Fixed height
      ),
    );
  }
}

class _FixedHeightHeaderDelegate extends SliverPersistentHeaderDelegate {
  final ValueListenable<double> orderScrollOffsetNotifier;
  final OrderModel orderModel;
  final double height;

  _FixedHeightHeaderDelegate({
    required this.orderScrollOffsetNotifier,
    required this.orderModel,
    required this.height,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ValueListenableBuilder<double>(
      valueListenable: orderScrollOffsetNotifier,
      builder: (context, offset, _) {
        final fadeStart = 50.0;
        final fadeEnd = 200.0;
        final opacity = ((offset - fadeStart) / (fadeEnd - fadeStart)).clamp(
          0.0,
          1.0,
        );

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Last Order Status",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              Opacity(
                opacity: opacity,
                child: Text(
                  getTranslatedOrderStatus(context, orderModel.orderStatus),
                  style: TextStyle(
                    color: getStatusTextColor(orderModel.orderStatus),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _FixedHeightHeaderDelegate oldDelegate) =>
      oldDelegate.orderModel != orderModel ||
      oldDelegate.orderScrollOffsetNotifier != orderScrollOffsetNotifier;
}
