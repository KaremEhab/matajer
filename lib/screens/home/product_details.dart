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

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  // Use 'late' ProductModel to hold the potentially fetched/updated data.
  // Initialize it with widget.productModel, but treat it as the source of truth.
  late ProductModel product;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> scrollOffsetNotifier = ValueNotifier(0);
  final ValueNotifier<int> counterNotifier = ValueNotifier(1);
  final ValueNotifier<num> totalPriceNotifier = ValueNotifier(0);
  bool disableAddToCartBtn = false;
  bool isOwner = true;

  List<int> selectedSpecifications = [];
  List<num> specificationsPrice = [];

  @override
  void initState() {
    super.initState();
    product = widget.productModel;

    // Start loading the up-to-date product data
    _loadProduct(widget.productModel.id);

    if (widget.shopModel != null) {
      // Assuming 'currentUserModel' is globally accessible as per the original code
      isOwner = currentUserModel.shops.any(
        (shop) => shop['id'] == widget.shopModel!.shopId,
      );
    } else {
      isOwner = false;
    }

    // Initialize data based on the initial product, will be re-run after load
    _initializeProductData();
  }

  void _initializeProductData() {
    // ⚠️ CRITICAL CHANGE: Use the 'product' state variable, not widget.productModel.
    // Also, guard against product specifications being empty.
    if (product.specifications.isEmpty) {
      selectedSpecifications = [];
      specificationsPrice = [];
      _updateTotalPrice(
        basePrice: product.price,
        specsTotal: 0,
      ); // Update with only base price
      return;
    }

    if (!isOwner) {
      ProductCubit.get(context).increaseProductClicks(productId: product.id);
    }

    // Find the cart item using the ID of the current 'product' state
    final cartItem = widget.cart
        ? ProductCubit.get(context).cartProducts.firstWhere(
            (e) => e.product.id == product.id,
            // orElse is implicitly null/exception, matching the original logic
          )
        : null;

    // Use 'product.specifications' length for initialization
    selectedSpecifications = List.generate(product.specifications.length, (
      index,
    ) {
      if (cartItem != null &&
          cartItem.selectedSpecifications.isNotEmpty &&
          index < cartItem.selectedSpecifications.length) {
        final selectedValue = cartItem.selectedSpecifications[index]['value'];
        return product.specifications[index].subTitles.indexWhere(
          (e) => e.title == selectedValue,
        );
      }
      return 0;
    });

    specificationsPrice = List.generate(product.specifications.length, (index) {
      final sub = product.specifications[index].subTitles;
      final selected = selectedSpecifications[index];
      // Guard against RangeError if selected index is invalid (though unlikely with indexWhere logic)
      if (selected >= 0 && selected < sub.length) {
        return sub[selected].price;
      }
      return 0; // Default to 0 price if spec is invalid
    });

    // Only add listener once
    if (!_scrollController.hasListeners) {
      _scrollController.addListener(() {
        scrollOffsetNotifier.value = _scrollController.offset;
      });
    }

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
        _initializeProductData(); // Re-initialize with fetched product data
      });
    }
  }

  // Adjusted _updateTotalPrice to take optional parameters for more control
  void _updateTotalPrice({num? basePrice, num? specsTotal}) {
    final effectiveBasePrice =
        basePrice ?? product.price; // Use 'product.price'
    final effectiveSpecsTotal =
        specsTotal ??
        specificationsPrice.fold<num>(0, (sum, price) => sum + price);

    final unitPrice = effectiveBasePrice + effectiveSpecsTotal;
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
    return BlocConsumer<ProductCubit, ProductState>(
      listener: (context, state) {
        if (state is ProductGetProductByIdSuccessState) {
          setState(() {
            product = state.product;
            _initializeProductData();
          });
        }
      },
      builder: (context, state) {
        final currentProduct = product; // Use local variable for clarity

        return Scaffold(
          body:
              state is ProductGetProductByIdLoadingState &&
                  currentProduct.id == widget.productModel.id
              ? Center(child: CircularProgressIndicator())
              : state is ProductGetProductByIdErrorState
              ? Center(
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
                )
              : CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    ProductDetailsAppBar(
                      productModel: currentProduct, // ⚠️ Use currentProduct
                      productScrollOffsetNotifier: scrollOffsetNotifier,
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final List<Widget> children = [
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 6,
                              ),
                              child: ProductDetailsTitleAndPrice(
                                productModel:
                                    currentProduct, // ⚠️ Use currentProduct
                                orderedQuantity: widget.orderedQuantity ?? 0,
                                counterNotifier: counterNotifier,
                                cart: widget.cart,
                                totalPriceNotifier: totalPriceNotifier,
                                onPriceUpdate: _updateTotalPrice,
                              ),
                            ),
                            if (currentProduct.specifications.isNotEmpty) ...[
                              // ⚠️ Use currentProduct
                              _divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 6,
                                ),
                                child: ProductDetailsSpecifications(
                                  productModel:
                                      currentProduct, // ⚠️ Use currentProduct
                                  initialSelectedIndexes:
                                      selectedSpecifications,
                                  onSpecChanged: (index, selectedIndex, price) {
                                    selectedSpecifications[index] =
                                        selectedIndex;
                                    specificationsPrice[index] = price;
                                    _updateTotalPrice();
                                  },
                                ),
                              ),
                            ],
                            // Assuming uId and isGuest are globally available as per the original code
                            if (currentProduct.sellerId != uId) ...[
                              // ⚠️ Use currentProduct
                              _divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 6,
                                ),
                                child: ProductDetailsReviews(
                                  productModel:
                                      currentProduct, // ⚠️ Use currentProduct
                                ),
                              ),
                              _divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                child: ProductDetailsSpecialRequests(
                                  productModel:
                                      currentProduct, // ⚠️ Use currentProduct
                                ),
                              ),
                            ],
                            const SizedBox(height: 150),
                          ];
                          return children[index];
                        },
                        childCount: (() {
                          final p = currentProduct; // ⚠️ Use currentProduct
                          int count = 2; // SizedBox + Title
                          if (p.specifications.isNotEmpty) count += 2;
                          if (p.sellerId != uId) count += 4;
                          count += 1; // bottom SizedBox
                          return count;
                        })(),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar:
              (currentProduct.sellerId == uId ||
                  isGuest) // ⚠️ Use currentProduct
              ? null
              : ProductDetailsNavbar(
                  productModel: currentProduct, // ⚠️ Use currentProduct
                  cart: widget.cart,
                  counterNotifier: counterNotifier,
                  totalPriceNotifier: totalPriceNotifier,
                  selectedSpecifications: selectedSpecifications,
                  specificationsPrice: specificationsPrice,
                  originalQuantity: widget.orderedQuantity ?? 1,
                  // Ensure this logic is also robust against missing cart item
                  originalSpecifications: widget.cart
                      ? ProductCubit.get(context).cartProducts
                            .firstWhere(
                              (e) => e.product.id == currentProduct.id,
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
