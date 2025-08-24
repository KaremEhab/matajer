import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/categories/shop_products_card.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:matajer/screens/my_cart/basket.dart';
import 'package:matajer/widgets/navigation_bar.dart';

class ShopNavbar extends StatelessWidget {
  final bool displayBottomSheet;
  final Function(bool) onSuccess;
  final ShopModel shop;

  const ShopNavbar({
    super.key,
    required this.displayBottomSheet,
    required this.onSuccess,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductGetCartProductsSuccessState) {
          onSuccess(true);
        }
      },
      builder: (context, state) {
        final cartProducts = ProductCubit.get(context).cartProducts;
        final bool emptyCart = cartProducts.isEmpty;
        final num total = cartProducts.fold<num>(
          0,
          (sum, item) => sum + item.totalPrice,
        );
        final String? shopId = emptyCart
            ? null
            : cartProducts.first.product.shopId;

        return SafeArea(
          child: Material(
            color: transparentColor,
            child: InkWell(
              onTap: emptyCart
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: scaffoldColor,
                        showDragHandle: true,
                        builder: (context) {
                          final minSize = cartProducts.length > 1
                              ? 0.4
                              : cartProducts.first.product.discount > 0
                              ? 0.33
                              : 0.3;
                          return SafeArea(
                            child: DraggableScrollableSheet(
                              initialChildSize: minSize,
                              minChildSize: minSize,
                              maxChildSize: 0.95,
                              expand: false,
                              builder: (_, controller) {
                                return Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 90,
                                      ), // space for bottom button
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        controller: controller,
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: cartProducts.length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              cartProducts[index].product;
                                          final quantity =
                                              cartProducts[index].quantity;
                                          final totalPrice =
                                              cartProducts[index].totalPrice;
                                          return Stack(
                                            children: [
                                              ShopProductsCard(
                                                productModel: product,
                                                isSelected: false,
                                                onTap: () {
                                                  navigateTo(
                                                    context: context,
                                                    screen:
                                                        ProductDetailsScreen(
                                                          cart: true,
                                                          productModel: product,
                                                          shopModel: shop,
                                                          orderedQuantity:
                                                              quantity,
                                                        ),
                                                  );
                                                },
                                                onLongPress: null,
                                                deleteButton: null,
                                                totalPrice: totalPrice.toDouble(),
                                              ),
                                              if (quantity > 1)
                                                Container(
                                                  height: 35,
                                                  width: 35,
                                                  margin:
                                                      EdgeInsetsGeometry.directional(
                                                        start: 10,
                                                        top: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          100,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      quantity > 99
                                                          ? "+99"
                                                          : quantity.toString(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // Fixed Checkout Button
                                    Positioned(
                                      bottom: 20,
                                      left: 7,
                                      right: 7,
                                      child: ActionButton(
                                        color: secondaryColor,
                                        onTap: () async {
                                          if (shopId == null) return;
                                          navigateTo(
                                            context: context,
                                            screen: Basket(shopId: shopId),
                                          );
                                        },
                                        child: Row(
                                          spacing: 8,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              IconlyLight.buy,
                                              color: primaryColor,
                                              size: 23,
                                            ),
                                            Text(
                                              "(${ProductCubit.get(context).totalCartQuantity}) ${S.of(context).checkout}",
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            Text(
                                              "${formatNumberWithCommas(total.toDouble())} AED",
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
              child: Padding(
                padding: EdgeInsets.fromLTRB(7, 0, 7, 15),
                child: Material(
                  borderRadius: BorderRadius.circular(15),
                  child: Opacity(
                    opacity: emptyCart ? 0.5 : 1,
                    child: SizedBox(
                      height: 70,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(0, 10),
                              blurRadius: 8,
                              color: primaryColor.withOpacity(0.5),
                            ),
                          ],
                        ),
                        child: ConditionalBuilder(
                          condition: displayBottomSheet,
                          builder: (context) => Row(
                            // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Material(
                                      color: primaryDarkColor,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          ProductCubit.get(
                                            context,
                                          ).totalCartQuantity.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsetsGeometry.directional(
                                          start: 15,
                                        ),
                                        child: Text(
                                          S.of(context).view_basket,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: lang == 'en' ? 12 : 0,
                                    left: lang == 'ar' ? 12 : 0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        S.of(context).total_amount,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.7),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'AED ${formatNumberWithCommas(ProductCubit.get(context).totalCartPrice.toDouble())}',
                                        style: TextStyle(
                                          height: 0.8,
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          fallback: (context) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
