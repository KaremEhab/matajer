import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/cart_product_item_model.dart';
import 'package:matajer/models/product_model.dart';

class ProductDetailsNavbar extends StatefulWidget {
  const ProductDetailsNavbar({
    super.key,
    required this.productModel,
    required this.cart,
    required this.counterNotifier,
    required this.totalPriceNotifier,
    required this.selectedSpecifications,
    required this.specificationsPrice,
    required this.originalQuantity,
    required this.originalSpecifications,
  });

  final ProductModel productModel;
  final bool cart;
  final int originalQuantity;
  final List<Map<String, String>> originalSpecifications;
  final ValueNotifier<int> counterNotifier;
  final ValueNotifier<num> totalPriceNotifier;
  final List<int> selectedSpecifications;
  final List<num> specificationsPrice;

  @override
  State<ProductDetailsNavbar> createState() => _ProductDetailsNavbarState();
}

class _ProductDetailsNavbarState extends State<ProductDetailsNavbar> {
  bool disableAddToCartBtn = false;
  late bool hasChanges;
  late List<Map<String, String>> currentSelectedSpecifications;

  @override
  void initState() {
    super.initState();

    hasChanges = false;

    widget.counterNotifier.addListener(_checkForChanges);
    widget.totalPriceNotifier.addListener(_checkForChanges);

    _checkForChanges(); // Initial state check
  }

  void _checkForChanges() {
    // Build normalized current specs
    currentSelectedSpecifications = List.generate(
      widget.productModel.specifications.length,
      (i) => {
        'title': widget.productModel.specifications[i].title.trim(),
        'value': widget
            .productModel
            .specifications[i]
            .subTitles[widget.selectedSpecifications[i]]
            .title
            .trim(),
      },
    );

    final sameQuantity =
        widget.counterNotifier.value == widget.originalQuantity;

    final sameSpecs = _listsAreEqual(
      widget.originalSpecifications,
      currentSelectedSpecifications,
    );

    final newHasChanges = !(sameQuantity && sameSpecs);

    if (hasChanges != newHasChanges) {
      setState(() => hasChanges = newHasChanges);
    }
  }

  bool _listsAreEqual(
    List<Map<String, String>> a,
    List<Map<String, String>> b,
  ) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['title'] != b[i]['title'] || a[i]['value'] != b[i]['value']) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<num>(
      valueListenable: widget.totalPriceNotifier,
      builder: (_, total, __) {
        return widget.productModel.quantity <= 0
            ? SizedBox.shrink()
            : SafeArea(
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(7, 0, 7, 20),
                    child: Material(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(15),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: (!hasChanges || disableAddToCartBtn)
                            ? null
                            : () async {
                                setState(() => disableAddToCartBtn = true);

                                try {
                                  // Build selected specifications
                                  final selectedSpecs = List.generate(
                                    widget.productModel.specifications.length,
                                    (i) => {
                                      'title': widget
                                          .productModel
                                          .specifications[i]
                                          .title,
                                      'value': widget
                                          .productModel
                                          .specifications[i]
                                          .subTitles[widget
                                              .selectedSpecifications[i]]
                                          .title,
                                    },
                                  );

                                  // 🔄 Normalize specs for comparison consistency
                                  final normalizedSpecs =
                                      List<Map<String, String>>.from(
                                        selectedSpecs.map(
                                          (e) => {
                                            'title': e['title']!.trim(),
                                            'value': e['value']!.trim(),
                                          },
                                        ),
                                      );

                                  final cartProduct = CartProductItemModel(
                                    product: widget.productModel,
                                    quantity: widget.counterNotifier.value,
                                    selectedSpecifications: normalizedSpecs,
                                  );

                                  if (widget.cart) {
                                    // 📝 Edit existing cart item
                                    await ProductCubit.get(
                                      context,
                                    ).editCartProduct(newItem: cartProduct);
                                    if (context.mounted) Navigator.pop(context);
                                  } else {
                                    // ➕ Add new product to cart
                                    final cartProducts = ProductCubit.get(
                                      context,
                                    ).cartProducts;
                                    final isDifferentSeller =
                                        cartProducts.isNotEmpty &&
                                        cartProducts.first.product.shopId !=
                                            widget.productModel.shopId;

                                    if (isDifferentSeller) {
                                      await _showClearCartDialog(
                                        context,
                                        normalizedSpecs,
                                      );
                                      return;
                                    }

                                    await ProductCubit.get(
                                      context,
                                    ).addProductToCart(product: cartProduct);

                                    if (context.mounted) Navigator.pop(context);
                                  }
                                } catch (e) {
                                  log("Add/edit cart error: $e");
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          S.of(context).something_went_wrong,
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => disableAddToCartBtn = false);
                                  }
                                }
                              },
                        child: Container(
                          height: 65,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 10),
                                blurRadius: 8,
                                color: primaryColor.withOpacity(0.5),
                              ),
                            ],
                          ),
                          child: widget.cart
                              ? Center(
                                  child: Text(
                                    S.of(context).save_changes,
                                    style: TextStyle(
                                      color: hasChanges
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        disableAddToCartBtn
                                            ? '${S.of(context).adding} ${widget.productModel.title}...'
                                            : S.of(context).add_to_cart,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    // Price
                                    if (widget.productModel.discount <= 0)
                                      Text(
                                        'AED ${formatNumberWithCommas(total.toDouble())}',
                                        style: const TextStyle(
                                          height: 0.8,
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    // Discounted Price
                                    if (widget.productModel.discount > 0)
                                      Row(
                                        spacing: 5,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'AED ${NumberFormat('#,###').format(widget.productModel.price)}',
                                            style: TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              height: 1.6,
                                              decorationColor: Colors.red,
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'AED ${NumberFormat('#,###').format(widget.productModel.price - widget.productModel.price * (widget.productModel.discount / 100))}',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
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
                ),
              );
      },
    );
  }

  Future<void> _showClearCartDialog(
    BuildContext context,
    List<Map<String, String>> selectedSpecs,
  ) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          S.of(context).different_seller,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
        ),
        content: Text(
          S.of(context).clear_cart_prompt,
          style: TextStyle(fontSize: 15.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              S.of(context).cancel,
              style: TextStyle(color: primaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              await ProductCubit.get(context).clearCart();
              await ProductCubit.get(context).addProductToCart(
                product: CartProductItemModel(
                  product: widget.productModel,
                  quantity: widget.counterNotifier.value,
                  selectedSpecifications: selectedSpecs,
                ),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: Text(
              S.of(context).clear_cart,
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
