import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/product_list_screen.dart';
import 'package:matajer/screens/home/categories/shop_products_card.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:matajer/screens/home/shop/shop_products_shimmer.dart';
import 'package:matajer/screens/home/shop_screen.dart';
import 'package:matajer/screens/seller/add_products.dart';

import '../../../constants/vars.dart';

class ShopProductsWidget extends StatefulWidget {
  final bool displayProducts;
  final int selectedSubCategory, limit;
  final ShopModel shop;
  final Function(bool) onSuccess;
  final ScrollController scrollController;

  const ShopProductsWidget({
    super.key,
    required this.displayProducts,
    required this.selectedSubCategory,
    required this.shop,
    this.limit = 10,
    required this.onSuccess,
    required this.scrollController,
  });

  @override
  State<ShopProductsWidget> createState() => _ShopProductsWidgetState();
}

class _ShopProductsWidgetState extends State<ShopProductsWidget>
    with AutomaticKeepAliveClientMixin<ShopProductsWidget> {
  List<String> selectedProductIds = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // ✅ Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialProducts();
    });

    widget.scrollController.addListener(() {
      final cubit = ProductCubit.get(context);
      if (widget.scrollController.position.pixels >=
              widget.scrollController.position.maxScrollExtent - 300 &&
          !cubit.isLoadingMoreProducts &&
          !cubit.reachedEndProduct &&
          widget.displayProducts) {
        _loadMoreProducts();
      }
    });
  }

  Future<void> _loadInitialProducts() async {
    final cubit = ProductCubit.get(context);
    if (widget.selectedSubCategory == 0) {
      await cubit.getProducts(
        sellerId: widget.shop.sellerId,
        sellerCategory: widget.shop.shopCategory,
        limit: widget.limit, // ✅ USE THE DYNAMIC LIMIT
      );
    } else {
      final parent = context.findAncestorStateOfType<ShopScreenState>();
      final category = parent?.productsList[widget.selectedSubCategory];
      if (category != null && category.isNotEmpty) {
        await cubit.getProductsByCategory(
          sellerId: widget.shop.sellerId,
          category: category,
          context: context,
          limit: widget.limit, // ✅ USE THE DYNAMIC LIMIT
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    final cubit = ProductCubit.get(context);
    if (widget.selectedSubCategory == 0) {
      await cubit.getMoreProducts(
        sellerId: widget.shop.sellerId,
        sellerCategory: widget.shop.shopCategory,
        context: context,
        limit: widget.limit,
      );
    } else {
      final parent = context.findAncestorStateOfType<ShopScreenState>();
      final category = parent?.productsList[widget.selectedSubCategory];
      if (category != null && category.isNotEmpty) {
        await cubit.getMoreProductsByCategory(
          sellerId: widget.shop.sellerId,
          category: category,
          limit: widget.limit,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = ProductCubit.get(context);

    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: cubit.products.isEmpty
            ? 100
            : widget.shop.sellerId == uId
            ? 90
            : 20,
      ),
      sliver: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductGetProductsSuccessState) {
            widget.onSuccess(true);
          }
        },
        builder: (context, state) {
          final products = cubit.products;

          return ConditionalBuilder(
            condition:
                widget.displayProducts &&
                cubit.state is! ProductGetProductsLoadingState &&
                state is! ProductGetProductsByCategoryLoadingState,
            builder: (context) {
              return products.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                IconlyLight.buy,
                                size: 80,
                                color: primaryColor.withOpacity(0.5),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                S.of(context).no_products_found,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.shop.sellerId == uId)
                                const SizedBox(height: 10),
                              if (widget.shop.sellerId == uId)
                                InkWell(
                                  onTap: () => slideAnimation(
                                    context: context,
                                    destination: AddProducts(
                                      shopModel: widget.shop,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      S.of(context).create_your_first_product,
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              SizedBox(
                                height: widget.shop.sellerId == uId ? 130 : 180,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount:
                            products.length +
                            (cubit.isLoadingMoreProducts ? 1 : 0),
                        (context, index) {
                          if (index == products.length) {
                            // Show loading indicator when fetching more
                            return const Padding(
                              padding: EdgeInsets.only(top: 20, bottom: 70),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final productModel = products[index];
                          final isSelected = selectedProductIds.contains(
                            productModel.id,
                          );

                          return RepaintBoundary(
                            child: Column(
                              children: [
                                ShopProductsCard(
                                  productModel: productModel,
                                  isSelected: isSelected,
                                  onTap:
                                      productModel.sellerId !=
                                          currentUserModel.uId
                                      ? () {
                                          navigateTo(
                                            context: context,
                                            screen: ProductDetailsScreen(
                                              productModel: productModel,
                                              shopModel: widget.shop,
                                            ),
                                          );
                                        }
                                      : () {
                                          setState(() {
                                            if (selectedProductIds.isNotEmpty) {
                                              if (isSelected) {
                                                selectedProductIds.remove(
                                                  productModel.id,
                                                );
                                              } else {
                                                selectedProductIds.add(
                                                  productModel.id,
                                                );
                                              }
                                            } else {
                                              navigateTo(
                                                context: context,
                                                screen: ProductDetailsScreen(
                                                  productModel: productModel,
                                                  shopModel: widget.shop,
                                                ),
                                              );
                                            }
                                          });
                                        },
                                  onLongPress:
                                      productModel.sellerId !=
                                          currentUserModel.uId
                                      ? null
                                      : () {
                                          setState(() {
                                            if (isSelected) {
                                              selectedProductIds.remove(
                                                productModel.id,
                                              );
                                            } else {
                                              selectedProductIds.add(
                                                productModel.id,
                                              );
                                            }
                                          });
                                        },
                                  deleteButton:
                                      selectedProductIds.isNotEmpty &&
                                          productModel.sellerId ==
                                              currentUserModel.uId
                                      ? () => MultiProductDeleter.show(
                                          context: context,
                                          shopModel: widget.shop,
                                          selectedProductIds:
                                              selectedProductIds,
                                          onDeleteComplete: () {
                                            setState(() {
                                              selectedProductIds.clear();
                                            });
                                          },
                                        )
                                      : null,
                                ),

                                // Bottom padding if last product
                                if (index == products.length - 1 &&
                                    !cubit.isLoadingMoreProducts)
                                  SizedBox(
                                    height: products.length > 3 ? 120 : 210,
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
            },
            fallback: (context) => ShopProductsShimmer(),
          );
        },
      ),
    );
  }
}
