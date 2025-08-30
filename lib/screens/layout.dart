// layout.dart

import 'dart:developer';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/cubit/user/user_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/my_cart/basket.dart';
import 'package:matajer/screens/my_cart/cart.dart';
import 'package:matajer/screens/home/home.dart';
import 'package:matajer/screens/profile/profile.dart';
import 'package:matajer/screens/search/search.dart';
import 'package:matajer/screens/seller/add_products.dart';
import 'package:matajer/screens/seller/seller_home.dart';
import 'package:matajer/screens/seller/seller_profile.dart';
import 'package:matajer/screens/seller/seller_reports.dart';
import 'package:matajer/screens/whatsApp/chats_list.dart';
import 'package:matajer/widgets/navigation_bar.dart';

// globals.dart or vars.dart (where your globals live)
PageController? layoutPageController;

// Utility to reset
void resetLayoutController() {
  layoutPageController?.dispose();
  layoutPageController = PageController();
}

class Layout extends StatefulWidget {
  const Layout({super.key, this.getUserData = true});
  final bool getUserData;

  @override
  State<Layout> createState() => LayoutState();
}

class LayoutState extends State<Layout> with WidgetsBindingObserver {
  final GlobalKey<HomeState> homeKey = GlobalKey<HomeState>();
  DateTime? lastBackPressed;
  int selectedPage = 0;
  int selectedIcon = 0;
  List<Widget> pages = [];
  bool display = false;

  @override
  void initState() {
    super.initState();

    layoutPageController ??= PageController(); // ✅ always ensure controller

    if (widget.getUserData) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await UserCubit.get(context).getUserData();
        if (isSeller) await UserCubit.get(context).getShop();
        if (!isSeller) {
          FavoritesCubit.get(
            context,
          ).getFavorites(userId: currentUserModel.uId);
        }

        setPages();

        if (mounted) {
          setState(() {
            display = true;
          });
        }

        WidgetsBinding.instance.addObserver(this);
      });
    } else {
      setPages();
      display = true;
      WidgetsBinding.instance.addObserver(this);
    }
  }

  void setPages() {
    pages = isSeller
        ? [
            const SellerHome(),
            Reports(shopId: currentShopModel!.shopId),
            Reports(shopId: currentShopModel!.shopId),
            ChatsPage(userId: currentShopModel!.shopId),
            SellerProfile(shopModel: currentShopModel!),
          ]
        : [
            Home(key: homeKey),
            const Search(),
            const Cart(),
            ChatsPage(userId: currentUserModel.uId),
            const Profile(),
          ];
  }

  @override
  void dispose() {
    // layoutPageController?.dispose();
    // layoutPageController = null; // reset global
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (shopStatus) {
      final isOnline = state == AppLifecycleState.resumed;
      final newStatus = isOnline
          ? UserActivityStatus.online.name
          : UserActivityStatus.offline.name;

      // Guard: wait until models are ready and isSeller is accurate
      if (currentUserModel.uId.isNotEmpty &&
          (!isSeller || (isSeller && currentShopModel!.shopId.isNotEmpty))) {
        final shopId = isSeller ? currentShopModel!.shopId : null;

        if (shopId != null) {
          UserCubit.get(context).setActivityStatus(
            userId: null,
            statusValue: newStatus,
            shopIdIfSeller: shopId,
          );
          log('Calling setActivityStatus with shopId: $shopId');
        } else {
          UserCubit.get(context).setActivityStatus(
            userId: currentUserModel.uId,
            statusValue: newStatus,
            shopIdIfSeller: null,
          );
          log('Calling setActivityStatus with userId: ${currentUserModel.uId}');
        }
      } else {
        log('❌ Skipped setActivityStatus – user/shop model not ready');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.white,
      ),
    );

    return RepaintBoundary(
      child: BlocConsumer<UserCubit, UserState>(
        listener: (context, state) async {
          if (state is UserGetUserDataSuccessState) {
            if (isSeller) {
              await UserCubit.get(context).getShop();
            }

            if (!isSeller || currentShopModel!.shopId.isNotEmpty) {
              UserCubit.get(context).setActivityStatus(
                userId: currentUserModel.uId,
                statusValue: UserActivityStatus.online.name,
                shopIdIfSeller: isSeller ? currentShopModel!.shopId : null,
              );
            }
          }
        },
        builder: (context, state) {
          return WillPopScope(
            onWillPop: () async {
              if (selectedIcon == 0) {
                final now = DateTime.now();
                if (lastBackPressed == null ||
                    now.difference(lastBackPressed!) >
                        const Duration(seconds: 2)) {
                  lastBackPressed = now;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).go_back_to_leave),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return false; // prevent exit
                }
                return true; // exit on second press
              } else {
                layoutPageController!.jumpToPage(0);
                return false;
              }
            },
            child: Material(
              color: selectedIcon == 4 ? primaryColor : Colors.white,
              child: SafeArea(
                child: Scaffold(
                  extendBody: true,
                  body: PageView(
                    controller: layoutPageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        selectedPage = index;
                        selectedIcon = selectedPage;
                      });
                    },
                    children: pages,
                  ),
                  bottomNavigationBar: ConditionalBuilder(
                    condition: display,
                    builder: (context) => Column(
                      spacing: 10,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (selectedIcon == 2 && !isSeller)
                          // Cart Checkout Navigation Bar
                          BlocBuilder<ProductCubit, ProductState>(
                            builder: (context, state) {
                              if (ProductCubit.get(
                                context,
                              ).cartProducts.isEmpty) {
                                return const SizedBox();
                              }
                              return SizedBox(
                                width: 0.97.sw,
                                child: Material(
                                  borderRadius: BorderRadius.circular(17),
                                  color: primaryColor,
                                  elevation: 15,
                                  shadowColor: primaryColor.withOpacity(0.8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(17),
                                    onTap: () {
                                      slideAnimation(
                                        context: context,
                                        destination: Basket(
                                          shopId: cartShopId!,
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                S.of(context).total_amount,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                'AED ${formatNumberWithCommas(ProductCubit.get(context).totalCartPrice.toDouble())}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                S.of(context).checkout,
                                                style: TextStyle(
                                                  height: 0.8,
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 13,
                                                  vertical: 18,
                                                ),
                                                child: SizedBox(
                                                  width: 2,
                                                  height: 0.04.sh,
                                                  child: Material(
                                                    color: primaryDarkColor
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                IconlyLight.message,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // Navigation Bar
                        CustomBottomNavBar(
                          currentIndex: selectedIcon,
                          isSeller: isSeller, // 👈 pass the flag
                          onTap: (value) {
                            setState(() {
                              if (!isSeller && value == 0) {
                                if (homeKey.currentState?.mounted ?? false) {
                                  homeKey.currentState!.scrollToTop();
                                }
                              }
                              if (isSeller && value == 2) {
                                slideAnimation(
                                  context: context,
                                  destination: AddProducts(
                                    shopModel: currentShopModel!,
                                  ),
                                );
                                Future.delayed(
                                  const Duration(milliseconds: 200),
                                ).then((value) {
                                  setState(() {
                                    selectedIcon = selectedPage;
                                  });
                                });
                              } else {
                                selectedIcon = value;
                                layoutPageController!.jumpToPage(selectedIcon);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    fallback: (context) => const SizedBox(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
