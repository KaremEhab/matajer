import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/order/order_state.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/screens/profile/order_details.dart';
import 'package:matajer/widgets/order_card.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SuccessPayment extends StatefulWidget {
  const SuccessPayment({
    super.key,
    required this.orderId,
    required this.shopId,
    required this.deliveryTime,
    this.price = 0,
  });

  final String orderId, shopId;
  final num deliveryTime;
  final double price;

  @override
  State<SuccessPayment> createState() => _SuccessPaymentState();
}

class _SuccessPaymentState extends State<SuccessPayment>
    with AutomaticKeepAliveClientMixin {
  late final String id;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    id = widget.orderId.replaceAll('"', '');
    _pageController = PageController(viewportFraction: 0.95);

    ProductCubit.get(context).placeOrder(
      docId: id,
      shopId: widget.shopId,
      deliveryTime: widget.deliveryTime,
      price: widget.price,
      context: context,
    );
    // OrderCubit.get(context).getOrderById(id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SuccessHeader()),

            /// Order Products Section (isolated Bloc)
            SliverToBoxAdapter(
              child: BlocConsumer<OrderCubit, OrderState>(
                listener: (context, state) {
                  if (state is OrderGetByIdErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: switch (state) {
                      OrderGetByIdLoadingState() => buildShimmerFallback(),
                      OrderGetByIdSuccessState(order: final order) =>
                        OrderProductsPager(
                          order: order,
                          controller: _pageController,
                        ),
                      _ => buildShimmerFallback(),
                    },
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),

      /// Bottom Buttons (isolated)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<OrderCubit, OrderState>(
            builder: (context, state) {
              OrderModel? order;
              // if (state is! OrderGetByIdSuccessState) {
              //   return const SizedBox.shrink();
              // }
              if (state is OrderGetByIdSuccessState) {
                order = state.order;
              }
              return OrderActions(order: order);
            },
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// --- Isolated Widgets ---

class SuccessHeader extends StatelessWidget {
  const SuccessHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        SvgPicture.asset('images/success payment.svg', width: 0.75.sw),
        const SizedBox(height: 20),
        Text(
          S.of(context).payment_successful,
          style: TextStyle(
            fontSize: 25,
            color: primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            S.of(context).thanks_for_shopping_with_us,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: primaryColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class OrderProductsPager extends StatelessWidget {
  const OrderProductsPager({
    super.key,
    required this.order,
    required this.controller,
  });

  final dynamic order;
  final PageController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: controller,
            physics: const BouncingScrollPhysics(),
            itemCount: order.products.length,
            itemBuilder: (context, index) {
              final product = order.products[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: OrderCard(
                  order: order,
                  clickable: false,
                  product: product.product,
                  totalQuantity: product.quantity,
                ),
              );
            },
          ),
        ),
        if (order.products.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SmoothPageIndicator(
              controller: controller,
              count: order.products.length,
              effect: WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: primaryColor,
                dotColor: Colors.grey.withOpacity(0.4),
              ),
            ),
          ),
      ],
    );
  }
}

class OrderActions extends StatelessWidget {
  const OrderActions({super.key, required this.order});
  final dynamic order;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              navigateTo(
                context: context,
                screen: OrderDetails(order: order, goBack: false),
              );
            },
            child: Text(
              S.of(context).track_your_order,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              navigateAndFinish(context: context, screen: Layout());
            },
            child: Text(
              S.of(context).done,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
