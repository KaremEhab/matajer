import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/cart_product_item_model.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/profile/order_details.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.product,
    required this.totalQuantity,
    this.clickable = true,
  });

  final int totalQuantity;
  final OrderModel order;
  final ProductModel product;
  final bool clickable;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: formFieldColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: clickable
            ? () => navigateTo(
                context: context,
                screen: OrderDetails(order: order),
              )
            : null,
        onLongPress: clickable
            ? () => OrderCubit.get(
                context,
              ).handleViewOrderProducts(context, order)
            : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Row(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.r),
                    child: CachedNetworkImage(
                      imageUrl: product.images.first,
                      fit: BoxFit.cover,
                      height: 120,
                      width: 120,
                      progressIndicatorBuilder: (_, __, ___) =>
                          shimmerPlaceholder(
                            width: 120,
                            height: 120,
                            radius: 15.r,
                          ),
                      errorWidget: (_, __, ___) => const Icon(Icons.error),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  // Order Info
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Text(S.of(context).last_order),
                            Text(
                              DateFormat(
                                "MMMM d, yyyy",
                              ).format(order.createdAt.toDate()),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Row(
                          children: [
                            Expanded(child: buildReOrderButton(context, order)),
                            Expanded(
                              child: buildStatusBadge(context, order.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (totalQuantity > 1)
                Container(
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Text(
                      totalQuantity > 99 ? "+99" : totalQuantity.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget buildReOrderButton(BuildContext context, OrderModel order) {
  return Padding(
    padding: EdgeInsetsGeometry.directional(end: 5),
    child: Material(
      color: primaryColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          await ProductCubit.get(context).getCartProducts();
          if (!context.mounted) return;

          bool proceed = true;

          // Check if cart has products from another shop
          if (ProductCubit.get(context).cartProducts.isNotEmpty &&
              ProductCubit.get(context).cartProducts.first.product.shopId !=
                  order.shopId) {
            // Await dialog result
            proceed =
                await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(S.of(context).different_seller),
                    content: Text(S.of(context).clear_cart_prompt),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(S.of(context).cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ProductCubit.get(context).clearCart();
                          if (!context.mounted) return;
                          Navigator.pop(context, true); // return true = proceed
                        },
                        child: Text(S.of(context).clear_cart),
                      ),
                    ],
                  ),
                ) ??
                false; // default false if dialog dismissed
          }

          if (!proceed) return;

          // Add products to cart
          await Future.wait([
            for (CartProductItemModel product in order.products)
              ProductCubit.get(context).addProductToCart(product: product),
          ]);

          if (!context.mounted) return;

          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                S.of(context).products_added_cart,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              S.of(context).reorder,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget buildRateButton(BuildContext context, String orderId) {
  return Padding(
    padding: EdgeInsets.only(
      right: lang == 'en' ? 6.w : 0,
      left: lang == 'ar' ? 6.w : 0,
    ),
    child: Material(
      color: const Color(0xFFDEFDB1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          final orders = OrderCubit.get(context).buyerOrders;
          final orderIndex = orders.indexWhere((order) => order.id == orderId);

          if (orderIndex != -1) {
            OrderCubit.get(
              context,
            ).showRatingModal(context: context, index: orderIndex);
          } else {
            // Optional: show error if order not found
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Order not found")));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            spacing: 3,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                IconlyBold.star,
                color: CupertinoColors.systemYellow,
                size: 20,
              ),
              Text(
                S.of(context).rate_order,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildStatusBadge(BuildContext context, String orderId) {
  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }

      if (!snapshot.hasData || !snapshot.data!.exists) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Text("N/A", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        );
      }

      final data = snapshot.data!.data()!;
      final int statusIndex = data['orderStatus'] as int;
      final status = OrderStatus.values[statusIndex];

      // ✅ Show rate button if delivered
      if (status == OrderStatus.delivered) {
        return buildRateButton(context, orderId);
      }

      // ✅ Otherwise show status badge
      return Container(
        decoration: BoxDecoration(
          color: getStatusBackgroundColor(status),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            getTranslatedOrderStatus(context, status),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: getStatusTextColor(status),
            ),
          ),
        ),
      );
    },
  );
}

Widget buildShimmerFallback() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(7, 5, 7, 0),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: formFieldColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          shimmerPlaceholder(width: 120, height: 120, radius: 15.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                shimmerPlaceholder(width: 180, height: 20, radius: 5.r),
                shimmerPlaceholder(width: 150, height: 15, radius: 5.r),
                shimmerPlaceholder(
                  width: double.infinity,
                  height: 40,
                  radius: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
