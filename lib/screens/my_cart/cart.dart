import 'package:cached_network_image/cached_network_image.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/home.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:matajer/screens/home/shop_screen.dart';
import 'package:matajer/screens/home/widgets/home/home_appBar.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/widgets/clear_dialog.dart';

class Cart extends StatefulWidget {
  const Cart({super.key});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> with TickerProviderStateMixin {
  final GlobalKey<HomeState> homeKey = GlobalKey<HomeState>();
  List<bool> itemVisibility = [];

  List<String> selectedProductIds = [];

  ScrollController scrollController = ScrollController();
  bool isVisible = true;
  bool display = false;
  bool expanded = true;
  List<bool> isUpdating = [];

  @override
  void initState() {
    super.initState();
    ProductCubit.get(context).getCartProducts();
    final cartProducts = ProductCubit.get(context).cartProducts;

    if (itemVisibility.length != cartProducts.length) {
      itemVisibility = List.generate(cartProducts.length, (_) => false);
      _triggerStaggeredAnimation(); // Start animation after rebuild
    }

    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection ==
          ScrollDirection.reverse) {
        setState(() {
          isVisible = false;
        });
      } else {
        setState(() {
          isVisible = true;
        });
      }
    });
  }

  void _triggerStaggeredAnimation() async {
    for (int i = 0; i < itemVisibility.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          itemVisibility[i] = true;
        });
      }
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        centerTitle: true,
        forceMaterialTransparency: true,
        leadingWidth: 53,
        leading: Padding(
          padding: EdgeInsets.fromLTRB(
            lang == 'en' ? 7 : 0,
            6,
            lang == 'ar' ? 7 : 0,
            6,
          ),
          child: isGuest
              ? null
              : Material(
                  color: lightGreyColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12.r),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: ProductCubit.get(context).cartProducts.isEmpty
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => ClearDialog(
                                title: S.of(context).clear_cart_title,
                                subtitle: S.of(context).clear_cart_tip,
                              ),
                            );

                            if (confirmed == true) {
                              ProductCubit.get(context).clearCart();
                            }
                          },
                    child: Center(
                      child: Icon(
                        IconlyBold.delete,
                        color: ProductCubit.get(context).cartProducts.isEmpty
                            ? Colors.red.withOpacity(0.4)
                            : Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
        ),
        title: buildAddressMenu(context, -15),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              right: lang == 'en' ? 7 : 0,
              left: lang == 'ar' ? 7 : 0,
            ),
            child: Material(
              color: lightGreyColor.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () async {
                  if (cartShopId != null) {
                    ShopModel? seller = await ProductCubit.get(
                      context,
                    ).getShop(sellerId: cartShopId!);

                    chatReceiverName = seller!.shopName;
                    chatReceiverImage = seller.shopLogoUrl;

                    if (!context.mounted) return;
                    slideAnimation(
                      context: context,
                      destination: ShopScreen(shopModel: seller),
                    );
                  } else {
                    setState(() {
                      layoutPageController!
                          .animateToPage(
                            0,
                            duration: Duration(milliseconds: 300),
                            curve: Curves.ease,
                          )
                          .then((_) => homeKey.currentState?.scrollToTop());
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Icon(
                    Icons.add_shopping_cart_rounded,
                    color: textColor,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: isGuest
          ? Center(
              child: SizedBox(
                width: 0.7.sw,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(IconlyLight.bag, size: 150, color: primaryColor),
                    Text(
                      S.of(context).cannot_access_cart,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        navigateTo(context: context, screen: SignUp());
                      },
                      child: Chip(
                        label: Text(
                          S.of(context).create_an_account,
                          style: TextStyle(color: Colors.white),
                        ),
                        side: BorderSide.none,
                        backgroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : BlocConsumer<ProductCubit, ProductState>(
              listener: (context, state) {
                if (state is ProductGetCartProductsSuccessState) {
                  isUpdating = List.generate(
                    ProductCubit.get(context).cartProducts.length,
                    (index) => false,
                  );
                  display = true;
                }
              },
              builder: (context, state) {
                return ConditionalBuilder(
                  condition: display,
                  builder: (context) =>
                      ProductCubit.get(context).cartProducts.isNotEmpty
                      ? SingleChildScrollView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(7, 0, 7, 10),
                                child: Material(
                                  color: formFieldColor,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      setState(() {
                                        expanded = !expanded;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 10,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            spacing: 5,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(2.h),
                                                decoration: BoxDecoration(
                                                  color: senderColor,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Container(
                                                  padding: EdgeInsets.all(2.h),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 0.015.sh,
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            200.r,
                                                          ),
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            ProductCubit.get(
                                                                  context,
                                                                )
                                                                .cartProducts
                                                                .first
                                                                .product
                                                                .shopLogo,
                                                        progressIndicatorBuilder:
                                                            (
                                                              context,
                                                              url,
                                                              progress,
                                                            ) =>
                                                                shimmerPlaceholder(
                                                                  height:
                                                                      0.8.sh,
                                                                  width: 0.8.sh,
                                                                  radius: 200.r,
                                                                ),
                                                        height: 0.8.sh,
                                                        width: 0.8.sh,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                ProductCubit.get(context)
                                                    .cartProducts
                                                    .first
                                                    .product
                                                    .shopName,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: textColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '${ProductCubit.get(context).cartProducts.length} ${ProductCubit.get(context).cartProducts.length == 1 ? S.of(context).item : S.of(context).items}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              AnimatedRotation(
                                                turns: expanded ? 0.5 : 0,
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .keyboard_arrow_down_rounded,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: expanded
                                    ? ListView.builder(
                                        itemCount: ProductCubit.get(
                                          context,
                                        ).cartProducts.length,
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemBuilder: (context, index) {
                                          final cartProducts = ProductCubit.get(
                                            context,
                                          ).cartProducts;

                                          // Ensure visibility list matches the cart list
                                          if (itemVisibility.length !=
                                              cartProducts.length) {
                                            itemVisibility = List.generate(
                                              cartProducts.length,
                                              (_) => false,
                                            );
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  _triggerStaggeredAnimation();
                                                });
                                          }

                                          // If still not ready, return a loading or placeholder
                                          if (itemVisibility.length !=
                                              cartProducts.length) {
                                            return const SizedBox.shrink(); // or a spinner
                                          }

                                          cartShopId = ProductCubit.get(
                                            context,
                                          ).cartProducts[index].product.shopId;
                                          if (index >= itemVisibility.length) {
                                            return const SizedBox.shrink();
                                          }

                                          final product =
                                              cartProducts[index].product;
                                          final quantity =
                                              cartProducts[index].quantity;
                                          final isSelected = selectedProductIds
                                              .contains(product.id);

                                          return AnimatedSlide(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            offset: itemVisibility[index]
                                                ? Offset.zero
                                                : const Offset(0, 0.2),
                                            curve: Curves.easeOut,
                                            child: AnimatedOpacity(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              opacity: itemVisibility[index]
                                                  ? 1
                                                  : 0,

                                              child: Column(
                                                children: [
                                                  if (index != 0)
                                                    SizedBox(height: 10),
                                                  Stack(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 7,
                                                            ),
                                                        child: Material(
                                                          color: formFieldColor,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                22.r,
                                                              ),
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  22.r,
                                                                ),
                                                            onLongPress: () {
                                                              setState(() {
                                                                selectedProductIds
                                                                    .add(
                                                                      product
                                                                          .id,
                                                                    );
                                                              });
                                                            },
                                                            onTap: () {
                                                              setState(() {
                                                                if (selectedProductIds
                                                                    .isNotEmpty) {
                                                                  // Selection mode is ON: Toggle selection
                                                                  if (isSelected) {
                                                                    selectedProductIds
                                                                        .remove(
                                                                          product
                                                                              .id,
                                                                        ); // Click again to remove
                                                                  } else {
                                                                    selectedProductIds.add(
                                                                      product
                                                                          .id,
                                                                    ); // Click to select
                                                                  }
                                                                } else {
                                                                  // Selection mode is OFF: Navigate
                                                                  slideAnimation(
                                                                    context:
                                                                        context,
                                                                    destination: ProductDetailsScreen(
                                                                      cart:
                                                                          true,
                                                                      orderedQuantity:
                                                                          quantity,
                                                                      productModel: ProductCubit.get(
                                                                        context,
                                                                      ).cartProducts[index].product,
                                                                    ),
                                                                    rightSlide:
                                                                        true,
                                                                  );
                                                                }
                                                              });
                                                            },
                                                            child: Container(
                                                              width: double
                                                                  .infinity,
                                                              clipBehavior: Clip
                                                                  .antiAliasWithSaveLayer,
                                                              decoration:
                                                                  BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          22,
                                                                        ),
                                                                  ),
                                                              child: Row(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  SizedBox(
                                                                    width: 140,
                                                                    height: 120,
                                                                    child:
                                                                        ProductCubit.get(
                                                                              context,
                                                                            )
                                                                            .cartProducts[index]
                                                                            .product
                                                                            .images
                                                                            .isNotEmpty
                                                                        ? Padding(
                                                                            padding: EdgeInsets.all(
                                                                              10,
                                                                            ),
                                                                            child: ClipRRect(
                                                                              borderRadius: BorderRadius.circular(
                                                                                20,
                                                                              ),
                                                                              child: CachedNetworkImage(
                                                                                imageUrl: ProductCubit.get(
                                                                                  context,
                                                                                ).cartProducts[index].product.images.first,
                                                                                fit: BoxFit.cover,
                                                                                height: 120,
                                                                                width: double.infinity,
                                                                              ),
                                                                            ),
                                                                          )
                                                                        : Center(
                                                                            child: Icon(
                                                                              IconlyBold.image,
                                                                            ),
                                                                          ),
                                                                  ),
                                                                  Expanded(
                                                                    child: Padding(
                                                                      padding: EdgeInsets.fromLTRB(
                                                                        lang ==
                                                                                'ar'
                                                                            ? 15
                                                                            : 0,
                                                                        10,
                                                                        lang ==
                                                                                'en'
                                                                            ? 15
                                                                            : 0,
                                                                        10,
                                                                      ),
                                                                      child: Column(
                                                                        spacing:
                                                                            5,
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Column(
                                                                            spacing:
                                                                                5,
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Flexible(
                                                                                    child: Text(
                                                                                      ProductCubit.get(
                                                                                        context,
                                                                                      ).cartProducts[index].product.title,
                                                                                      overflow: TextOverflow.ellipsis,
                                                                                      style: TextStyle(
                                                                                        fontSize: 16,
                                                                                        fontWeight: FontWeight.w900,
                                                                                        color: textColor,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  Row(
                                                                                    spacing: 5,
                                                                                    children: [
                                                                                      Container(
                                                                                        padding: const EdgeInsets.all(
                                                                                          3,
                                                                                        ),
                                                                                        decoration: BoxDecoration(
                                                                                          color: primaryColor,
                                                                                          borderRadius: BorderRadius.circular(
                                                                                            7,
                                                                                          ),
                                                                                        ),
                                                                                        child: Icon(
                                                                                          IconlyLight.edit,
                                                                                          color: Colors.white,
                                                                                          size: 14,
                                                                                        ),
                                                                                      ),
                                                                                      Text(
                                                                                        S
                                                                                            .of(
                                                                                              context,
                                                                                            )
                                                                                            .edit,
                                                                                        style: TextStyle(
                                                                                          fontSize: 14,
                                                                                          fontWeight: FontWeight.w900,
                                                                                          color: primaryColor,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                  Row(
                                                                                    children: [
                                                                                      /// Decrease / Delete
                                                                                      Material(
                                                                                        color: greyColor.withOpacity(
                                                                                          0.2,
                                                                                        ),
                                                                                        borderRadius: BorderRadius.circular(
                                                                                          6.r,
                                                                                        ),
                                                                                        child: InkWell(
                                                                                          borderRadius: BorderRadius.circular(
                                                                                            6.r,
                                                                                          ),
                                                                                          onTap: () async {
                                                                                            setState(
                                                                                              () => isUpdating[index] = true,
                                                                                            );

                                                                                            final cubit = ProductCubit.get(
                                                                                              context,
                                                                                            );

                                                                                            if (cubit.cartProducts[index].quantity >
                                                                                                1) {
                                                                                              await cubit.decreaseProductQuantityInCart(
                                                                                                index: index,
                                                                                              );
                                                                                            } else {
                                                                                              await cubit.removeProductFromCart(
                                                                                                index: index,
                                                                                              );
                                                                                            }

                                                                                            setState(
                                                                                              () => isUpdating[index] = false,
                                                                                            );
                                                                                          },
                                                                                          child: Padding(
                                                                                            padding: EdgeInsets.all(
                                                                                              3.h,
                                                                                            ),
                                                                                            child: Icon(
                                                                                              ProductCubit.get(
                                                                                                        context,
                                                                                                      ).cartProducts[index].quantity ==
                                                                                                      1
                                                                                                  ? Icons.delete
                                                                                                  : Icons.remove,
                                                                                              size: 18.h,
                                                                                              color:
                                                                                                  ProductCubit.get(
                                                                                                        context,
                                                                                                      ).cartProducts[index].quantity ==
                                                                                                      1
                                                                                                  ? Colors.red
                                                                                                  : textColor,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ),

                                                                                      /// Quantity
                                                                                      Padding(
                                                                                        padding: const EdgeInsets.symmetric(
                                                                                          horizontal: 12,
                                                                                        ),
                                                                                        child: Text(
                                                                                          ProductCubit.get(
                                                                                            context,
                                                                                          ).cartProducts[index].quantity.toString(),
                                                                                          style: TextStyle(
                                                                                            fontSize: 17,
                                                                                            fontWeight: FontWeight.w900,
                                                                                            color: primaryColor,
                                                                                          ),
                                                                                        ),
                                                                                      ),

                                                                                      /// Increase
                                                                                      Material(
                                                                                        color: greyColor.withOpacity(
                                                                                          0.2,
                                                                                        ),
                                                                                        borderRadius: BorderRadius.circular(
                                                                                          6.r,
                                                                                        ),
                                                                                        child: InkWell(
                                                                                          borderRadius: BorderRadius.circular(
                                                                                            6.r,
                                                                                          ),
                                                                                          onTap: () async {
                                                                                            setState(
                                                                                              () => isUpdating[index] = true,
                                                                                            );

                                                                                            await ProductCubit.get(
                                                                                              context,
                                                                                            ).increaseProductQuantityInCart(
                                                                                              index: index,
                                                                                            );

                                                                                            setState(
                                                                                              () => isUpdating[index] = false,
                                                                                            );
                                                                                          },
                                                                                          child: Padding(
                                                                                            padding: EdgeInsets.all(
                                                                                              3.h,
                                                                                            ),
                                                                                            child: Icon(
                                                                                              Icons.add,
                                                                                              size: 18.h,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Row(
                                                                                children: [
                                                                                  Text(
                                                                                    "${ProductCubit.get(context).cartProducts[index].product.sumOfRating.toStringAsFixed(1)} (${ProductCubit.get(context).cartProducts[index].product.numberOfRating})",
                                                                                    style: const TextStyle(
                                                                                      fontWeight: FontWeight.w700,
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(
                                                                                    width: 2,
                                                                                  ),
                                                                                  const Icon(
                                                                                    Icons.star_rounded,
                                                                                    size: 20,
                                                                                    color: CupertinoColors.systemYellow,
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              Text(
                                                                                "AED ${formatNumberWithCommas(ProductCubit.get(context).cartProducts[index].totalPrice.toDouble())}",
                                                                                style: TextStyle(
                                                                                  fontSize: 20,
                                                                                  fontWeight: FontWeight.w900,
                                                                                  color: textColor,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          Wrap(
                                                                            spacing:
                                                                                5,
                                                                            runSpacing:
                                                                                2,
                                                                            children:
                                                                                ProductCubit.get(
                                                                                  context,
                                                                                ).cartProducts[index].selectedSpecifications.map<
                                                                                  Widget
                                                                                >((
                                                                                  spec,
                                                                                ) {
                                                                                  final title =
                                                                                      spec['title'] ??
                                                                                      '';
                                                                                  final value =
                                                                                      spec['value'] ??
                                                                                      '';
                                                                                  return Container(
                                                                                    padding: const EdgeInsets.symmetric(
                                                                                      horizontal: 6,
                                                                                      vertical: 3,
                                                                                    ),
                                                                                    decoration: BoxDecoration(
                                                                                      color: primaryColor.withOpacity(
                                                                                        0.08,
                                                                                      ),
                                                                                      borderRadius: BorderRadius.circular(
                                                                                        6,
                                                                                      ),
                                                                                    ),
                                                                                    child: Text(
                                                                                      value,
                                                                                      style: TextStyle(
                                                                                        fontSize: 12,
                                                                                        color: primaryColor,
                                                                                        fontWeight: FontWeight.w600,
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                }).toList(),
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
                                                      ),
                                                      if (isSelected)
                                                        Positioned.fill(
                                                          child: InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                if (selectedProductIds
                                                                    .isNotEmpty) {
                                                                  // Selection mode is ON: Toggle selection
                                                                  if (isSelected) {
                                                                    selectedProductIds
                                                                        .remove(
                                                                          product
                                                                              .id,
                                                                        ); // Click again to remove
                                                                  } else {
                                                                    selectedProductIds.add(
                                                                      product
                                                                          .id,
                                                                    ); // Click to select
                                                                  }
                                                                } else {
                                                                  // Selection mode is OFF: Navigate
                                                                  slideAnimation(
                                                                    context:
                                                                        context,
                                                                    destination: ProductDetailsScreen(
                                                                      cart:
                                                                          true,
                                                                      orderedQuantity:
                                                                          quantity,
                                                                      productModel: ProductCubit.get(
                                                                        context,
                                                                      ).cartProducts[index].product,
                                                                    ),
                                                                    rightSlide:
                                                                        true,
                                                                  );
                                                                }
                                                              });
                                                            },
                                                            child: Container(
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                      0.3,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      20,
                                                                    ),
                                                              ),
                                                              child: Center(
                                                                child: Icon(
                                                                  Icons
                                                                      .check_circle,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 48,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),

                                                      // delete button top left
                                                      if (isSelected)
                                                        Positioned(
                                                          top: 5,
                                                          left: 5,
                                                          child: Material(
                                                            color: Colors.white,
                                                            shape:
                                                                const CircleBorder(),
                                                            child: GestureDetector(
                                                              onTap: () async {
                                                                await ProductCubit.get(
                                                                  context,
                                                                ).removeProductFromCart(
                                                                  index: index,
                                                                );
                                                              },
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      8.0,
                                                                    ),
                                                                child: Icon(
                                                                  IconlyLight
                                                                      .delete,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 20,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              SizedBox(height: 180),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconlyLight.bag,
                                size: 100,
                                color: primaryColor,
                              ),
                              Text(
                                S.of(context).cart_empty,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
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
