import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/product/product_details_appBar.dart';
import 'package:matajer/screens/home/product/product_details_navbar.dart';
import 'package:matajer/screens/home/product/product_details_reviews.dart';
import 'package:matajer/screens/home/product/product_details_special_requests.dart';
import 'package:matajer/screens/home/product/product_details_specifications.dart';
import 'package:matajer/screens/home/product/product_details_title.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productModel,
    this.cart = false,
    this.fromNotif = false,
    this.orderedQuantity = 0,
    this.shopModel,
  });

  final ProductModel productModel;
  final bool cart, fromNotif;
  final int? orderedQuantity;
  final ShopModel? shopModel;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> scrollOffsetNotifier = ValueNotifier(0);
  final ValueNotifier<int> counterNotifier = ValueNotifier(1);
  final ValueNotifier<num> totalPriceNotifier = ValueNotifier(0);
  bool disableAddToCartBtn = false;
  bool isOwner = true;

  ProductModel? product; // ✅ nullable
  List<int> selectedSpecifications = [];
  List<num> specificationsPrice = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    if (widget.productModel.id != null) {
      _loadProduct(widget.productModel.id);
    } else {
      product = widget.productModel;
      _initializeProductData();
    }

    if (widget.shopModel != null) {
      isOwner = currentUserModel.shops.any(
        (shop) => shop['id'] == widget.shopModel!.shopId,
      );
    } else {
      isOwner = false;
    }
  }

  void _initializeProductData() {
    if (product == null) return;

    if (!isOwner) {
      ProductCubit.get(context).increaseProductClicks(productId: product!.id);
    }

    final cartItem = widget.cart
        ? ProductCubit.get(context).cartProducts.firstWhere(
            (e) => e.product.id == product!.id,
            // orElse: () => null, // ✅ prevent crash
          )
        : null;

    selectedSpecifications = List.generate(product!.specifications.length, (
      index,
    ) {
      if (cartItem != null && cartItem.selectedSpecifications.isNotEmpty) {
        final selectedValue = cartItem.selectedSpecifications[index]['value'];
        return product!.specifications[index].subTitles.indexWhere(
          (e) => e.title == selectedValue,
        );
      }
      return 0;
    });

    specificationsPrice = List.generate(product!.specifications.length, (
      index,
    ) {
      final sub = product!.specifications[index].subTitles;
      final selected = selectedSpecifications[index];
      return sub[selected].price;
    });

    _scrollController.addListener(() {
      scrollOffsetNotifier.value = _scrollController.offset;
    });

    counterNotifier.value = cartItem?.quantity ?? 1;

    _updateTotalPrice();
  }

  void _loadProduct(String productId) async {
    final fetchedProduct = await ProductCubit.get(
      context,
    ).getProductById(productId: productId);
    if (fetchedProduct != null && mounted) {
      setState(() {
        product = fetchedProduct;
        _initializeProductData(); // ✅ init after load
      });
    }
  }

  void _updateTotalPrice() {
    final basePrice = widget.productModel.price;
    final specsTotal = specificationsPrice.fold<num>(
      0,
      (sum, price) => sum + price,
    );
    final unitPrice = basePrice + specsTotal;
    final quantity = counterNotifier.value;

    totalPriceNotifier.value = unitPrice * quantity;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    scrollOffsetNotifier.dispose();
    counterNotifier.dispose();
    totalPriceNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        return state is ProductGetProductByIdErrorState
            ? Scaffold(
                body: Center(
                  child: Chip(
                    side: BorderSide.none,
                    backgroundColor: Colors.red.withOpacity(0.07),
                    label: const Text(
                      "This product has been deleted",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            : Scaffold(
                extendBody: true,
                extendBodyBehindAppBar: true,
                body: CustomScrollView(
                  key: const PageStorageKey('product-details-scroll'),
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    ProductDetailsAppBar(
                      productModel: widget.productModel,
                      productScrollOffsetNotifier: scrollOffsetNotifier,
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 10),

                        // Title and Price
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 6,
                          ),
                          child: ProductDetailsTitleAndPrice(
                            productModel: widget.productModel,
                            orderedQuantity: widget.orderedQuantity ?? 0,
                            counterNotifier: counterNotifier,
                            cart: widget.cart,
                            totalPriceNotifier: totalPriceNotifier,
                            onPriceUpdate: _updateTotalPrice,
                          ),
                        ),

                        // Specifications
                        if (widget.productModel.specifications.isNotEmpty) ...[
                          _divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 6,
                            ),
                            child: ProductDetailsSpecifications(
                              productModel: widget.productModel,
                              initialSelectedIndexes: selectedSpecifications,
                              onSpecChanged: (index, selectedIndex, price) {
                                selectedSpecifications[index] = selectedIndex;
                                specificationsPrice[index] = price;
                                _updateTotalPrice();
                              },
                            ),
                          ),
                        ],

                        // Reviews and Special Requests
                        if (widget.productModel.sellerId != uId) ...[
                          _divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 6,
                            ),
                            child: ProductDetailsReviews(
                              productModel: widget.productModel,
                            ),
                          ),
                          _divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ProductDetailsSpecialRequests(
                              productModel: widget.productModel,
                            ),
                          ),
                        ],

                        const SizedBox(height: 150),
                      ]),
                    ),
                  ],
                ),
                bottomNavigationBar:
                    (widget.productModel.sellerId == uId || isGuest)
                    ? null
                    : ProductDetailsNavbar(
                        productModel: widget.productModel,
                        cart: widget.cart,
                        counterNotifier: counterNotifier,
                        totalPriceNotifier: totalPriceNotifier,
                        selectedSpecifications: selectedSpecifications,
                        specificationsPrice: specificationsPrice,
                        originalQuantity: widget.orderedQuantity ?? 1,
                        originalSpecifications: widget.cart
                            ? ProductCubit.get(context).cartProducts
                                  .firstWhere(
                                    (e) =>
                                        e.product.id == widget.productModel.id,
                                  )
                                  .selectedSpecifications
                            : [],
                      ),
              );
      },
    );
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Divider(color: primaryColor.withOpacity(0.1), thickness: 7),
    );
  }
}
