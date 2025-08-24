import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/favorites/favorites_state.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/product_list_screen.dart';
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/home/categories/shop_products_card.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/product_details.dart';

import '../../constants/vars.dart';

class Favourites extends StatefulWidget {
  final int initialIndex;
  const Favourites({super.key, this.initialIndex = 0});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  late int currentIndex;
  PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        leadingWidth: 57,
        leading: Padding(
          padding: EdgeInsets.fromLTRB(7, 6, 7, 6),
          child: Material(
            color: lightGreyColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(context);
              },
              child: Center(
                child: Icon(
                  Icons.keyboard_arrow_left_rounded,
                  color: textColor,
                  size: 27,
                ),
              ),
            ),
          ),
        ),
        actions: [SizedBox(width: 38)],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  currentIndex = 0;
                  pageController.animateToPage(
                    currentIndex,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: Text(
                'Shops',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: currentIndex == 0
                      ? textColor
                      : greyColor.withOpacity(0.5),
                ),
              ),
            ),
            SizedBox(width: 30),
            const CircleAvatar(radius: 4, backgroundColor: textColor),
            SizedBox(width: 30),
            InkWell(
              onTap: () {
                setState(() {
                  currentIndex = 1;
                  pageController.animateToPage(
                    currentIndex,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                });
              },
              child: Text(
                'Products',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: currentIndex == 1
                      ? textColor
                      : greyColor.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: pageController,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          children: const [FavouriteShops(), ProductShops()],
        ),
      ),
    );
  }
}

class FavouriteShops extends StatefulWidget {
  const FavouriteShops({super.key});

  @override
  State<FavouriteShops> createState() => _FavouriteShopsState();
}

class _FavouriteShopsState extends State<FavouriteShops> {
  @override
  void initState() {
    super.initState();
    if (!isGuest) {
      FavoritesCubit.get(context).getFavorites(userId: currentUserModel.uId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isGuest
        ? Center(
            child: SizedBox(
              width: 0.7.sw,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyLight.star, size: 150, color: primaryColor),
                  Text(
                    S.of(context).cannot_access_favorites,
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
        : BlocConsumer<FavoritesCubit, FavoritesStates>(
            listener: (context, state) {},
            builder: (context, state) {
              return ConditionalBuilder(
                condition: FavoritesCubit.get(context).favShopsList.isNotEmpty,
                builder: (context) => ListView.builder(
                  itemCount: FavoritesCubit.get(context).favShopsList.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.only(top: 10.h),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return ShopListCard(
                      shopModel: FavoritesCubit.get(
                        context,
                      ).favShopsList[index],
                    );
                  },
                ),
                fallback: (context) => state is FavoritesLoadingState
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : Center(
                        child: Text(
                          'No Favourite Shops',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
              );
            },
          );
  }
}

class ProductShops extends StatefulWidget {
  const ProductShops({super.key});

  @override
  State<ProductShops> createState() => _ProductShopsState();
}

class _ProductShopsState extends State<ProductShops> {
  List<String> selectedProductIds = [];

  @override
  void initState() {
    super.initState();
    if (!isGuest) {
      FavoritesCubit.get(context).getFavorites(userId: currentUserModel.uId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return isGuest
        ? Center(
            child: SizedBox(
              width: 0.7.sw,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(IconlyLight.star, size: 150, color: primaryColor),
                  Text(
                    S.of(context).cannot_access_favorites,
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
        : BlocConsumer<FavoritesCubit, FavoritesStates>(
            listener: (context, state) {},
            builder: (context, state) {
              return ConditionalBuilder(
                condition: FavoritesCubit.get(
                  context,
                ).favProductsList.isNotEmpty,
                builder: (context) => ListView.builder(
                  itemCount: FavoritesCubit.get(context).favProductsList.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.only(top: 10.h),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final productModel = ProductCubit.get(
                      context,
                    ).products[index];
                    final isSelected = selectedProductIds.contains(
                      productModel.id,
                    );
                    return ShopProductsCard(
                      productModel: productModel,
                      isSelected: isSelected,
                      onTap: productModel.sellerId != currentUserModel.uId
                          ? () {
                              navigateTo(
                                context: context,
                                screen: ProductDetailsScreen(
                                  productModel: ProductCubit.get(
                                    context,
                                  ).products[index],
                                ),
                              );
                            }
                          : () {
                              setState(() {
                                if (selectedProductIds.isNotEmpty) {
                                  // Toggle selection
                                  if (isSelected) {
                                    selectedProductIds.remove(productModel.id);
                                  } else {
                                    selectedProductIds.add(productModel.id);
                                  }
                                } else {
                                  navigateTo(
                                    context: context,
                                    screen: ProductDetailsScreen(
                                      productModel: ProductCubit.get(
                                        context,
                                      ).products[index],
                                    ),
                                  );
                                }
                              });
                            },
                      onLongPress: productModel.sellerId != currentUserModel.uId
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  selectedProductIds.remove(productModel.id);
                                } else {
                                  selectedProductIds.add(productModel.id);
                                }
                              });
                            },
                      deleteButton:
                          selectedProductIds.isNotEmpty &&
                              productModel.sellerId == currentUserModel.uId
                          ? () => MultiProductDeleter.show(
                              context: context,
                              selectedProductIds: selectedProductIds,
                              onDeleteComplete: () {
                                setState(() {
                                  selectedProductIds.clear();
                                });
                              },
                            )
                          : null,
                    );
                  },
                ),
                fallback: (context) => state is FavoritesLoadingState
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : Center(
                        child: Text(
                          'No Favourite Products',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
              );
            },
          );
  }
}
