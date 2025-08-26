import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/comments/comments_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/shop/shop_appBar.dart';
import 'package:matajer/screens/home/shop/shop_discount_ads.dart';
import 'package:matajer/screens/home/shop/shop_navBar.dart';
import 'package:matajer/screens/home/shop/shop_products_widget.dart';
import 'package:matajer/screens/home/shop/shop_subcategory_selector.dart';
import 'package:matajer/screens/seller/add_products.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.shopModel});

  final ShopModel shopModel;

  @override
  State<ShopScreen> createState() => ShopScreenState();
}

class ShopScreenState extends State<ShopScreen> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> shopScrollOffsetNotifier = ValueNotifier(0);
  final PageController pageController = PageController();

  List<String> productsList = [];
  late num rating;
  int selectedSubCategory = 0;
  bool displayProducts = false;
  bool displayBottomSheet = false;
  bool isLoadingSubCategories = true;
  bool hasAnyProducts = true;

  @override
  void initState() {
    super.initState();

    final numberOfRating = widget.shopModel.numberOfRating != 0
        ? widget.shopModel.numberOfRating
        : 1;
    final sumOfRating = widget.shopModel.sumOfRating;
    rating = sumOfRating / numberOfRating;

    _scrollController.addListener(() {
      shopScrollOffsetNotifier.value = _scrollController.position.pixels;
    });

    // Delay Cubit access to after widget tree has built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSubcategories();
    });
  }

  Future<void> _initializeSubcategories() async {
    // 1. Load all products first
    await ProductCubit.get(context).getProducts(
      sellerId: widget.shopModel.sellerId,
      sellerCategory: widget.shopModel.shopCategory,
    );

    final cubit = ProductCubit.get(context);
    final hasProducts = cubit.allProducts.isNotEmpty;

    final Set<String> subcategoriesFromShop = widget.shopModel.subcategories
        .toSet();

    setState(() {
      productsList = ["All", ...subcategoriesFromShop.toList()..sort()];
      isLoadingSubCategories = false;
      hasAnyProducts = hasProducts;
    });

    displayProducts = hasProducts;

    CommentsCubit.get(context).getCommentsByShopId(widget.shopModel.shopId);
    ProductCubit.get(context).getCartProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    shopScrollOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          ShopAppBar(
            rating: rating,
            shopModel: widget.shopModel,
            productsList: productsList,
            shopScrollOffsetNotifier: shopScrollOffsetNotifier,
          ),
          ShopDiscountAds(discountButton: () {}, shopModel: widget.shopModel),
          if (productsList.isNotEmpty)
            ShopSubcategorySelector(
              shopCategory: widget.shopModel.shopCategory,
              productsList: productsList,
              selectedSubCategory: selectedSubCategory,
              onSubCategorySelected: (index) {
                setState(() {
                  shopScrollOffsetNotifier.value = 0;
                  selectedSubCategory = index;

                  if (index == 0) {
                    ProductCubit.get(context).getProducts(
                      sellerId: widget.shopModel.sellerId,
                      sellerCategory: widget.shopModel.shopCategory,
                    );
                  } else {
                    ProductCubit.get(context).getProductsByCategory(
                      sellerId: widget.shopModel.sellerId,
                      category: productsList[index],
                      context: context,
                    );
                  }
                });
              },
            ),

          ShopProductsWidget(
            limit: 4,
            displayProducts: displayProducts,
            scrollController: _scrollController,
            selectedSubCategory: selectedSubCategory,
            shop: widget.shopModel,
            onSuccess: (value) {
              setState(() {
                displayProducts = value;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: ShopNavbar(
        displayBottomSheet: displayBottomSheet,
        shop: widget.shopModel,
        onSuccess: (value) {
          setState(() {
            displayBottomSheet = value;
          });
        },
      ),
      floatingActionButton:
          (widget.shopModel.sellerId == uId && productsList.isNotEmpty)
          ? FloatingActionButton(
              backgroundColor: primaryColor,
              shape: CircleBorder(),
              onPressed: () {
                slideAnimation(
                  context: context,
                  destination: AddProducts(shopModel: widget.shopModel),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
