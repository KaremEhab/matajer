import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/home/widgets/home/home_appBar.dart';
import 'package:matajer/screens/home/widgets/home/home_category_Text_widget.dart';
import 'package:matajer/screens/home/widgets/home/home_category_selector.dart';
import 'package:matajer/screens/home/widgets/home/home_last_order_widget.dart';
import 'package:matajer/screens/home/widgets/home/home_shops_widget.dart';
import 'package:matajer/screens/home/widgets/home/home_subcategory_selector.dart';
import 'package:matajer/screens/home/widgets/home/home_welcome_widget.dart';
import 'package:matajer/widgets/no_internet.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.goToSearch});
  final VoidCallback? goToSearch;

  @override
  State<Home> createState() => HomeState();
}

class HomeState extends State<Home> with AutomaticKeepAliveClientMixin {
  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;
  ValueNotifier<double> homeScrollOffsetNotifier = ValueNotifier(0);
  final ScrollController _scrollController = ScrollController();

  bool isConnected = true;

  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
    print("isConnected: $isConnected");
  }

  int selectedCategory = 0;
  int selectedSubCategory = 0;
  bool landscapeMode = true;
  bool displayShops = false;

  void scrollToTop() {
    if (_scrollController.offset > 1) {
      _scrollController
          .animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            checkConnectivity();
            ProductCubit.get(context).getSellers(shopType: '');
            OrderCubit.get(context).getBuyerOrders();
            _showSnack(S.of(context).scrolled_to_top);
          });
    } else {
      _showSnack(S.of(context).already_at_top);
      checkConnectivity();
      ProductCubit.get(context).getSellers(shopType: '');
      OrderCubit.get(context).getBuyerOrders();
    }
  }

  void scrollToShops() {
    if (_scrollController.offset < 300) {
      _scrollController
          .animateTo(
            300,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          )
          .then((_) {
            _showSnack(S.of(context).scrolled_to_shops);
          });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void initState() {
    super.initState();
    isSeller = false;

    checkConnectivity(); // Initial check

    // ✅ Start listening to changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final connected = results.any((r) => r != ConnectivityResult.none);
      if (connected != isConnected) {
        setState(() {
          isConnected = connected;
        });
      }
      print("Home Connectivity changed: isConnected = $connected");
    });

    ProductCubit.get(context).getSellers(shopType: '');

    _scrollController.addListener(() {
      homeScrollOffsetNotifier.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel(); // ✅ clean up
    _scrollController.dispose();
    homeScrollOffsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sticky AppBar
          const HomeAppBar(),

          // Welcome Text & Search Bar
          HomeWelcomeWidget(),

          // Last Order
          const HomeLastOrderWidget(),

          // Category Text & Shop View Mode
          HomeCategoryTextWidget(
            homeScrollOffsetNotifier: homeScrollOffsetNotifier,
            selectedCategory: selectedCategory,
            landscapeMode: landscapeMode,
            onCategorySelected: (index) {
              setState(() {
                selectedCategory = index;
                displayShops = false;
              });
            },
            onViewModeChanged: (isLandscape) {
              setState(() => landscapeMode = isLandscape);
            },
          ),

          // Categories
          HomeCategorySelector(
            selectedCategory: selectedCategory,
            displayShops: displayShops,
            setDisplayShops: (val) => setState(() => displayShops = val),
            onCategorySelected: (index) => setState(() {
              selectedSubCategory = 0;
              selectedCategory = index;
            }),
          ),

          // Sticky Sub-Categories
          HomeSubcategorySelector(
            selectedSubCategory: selectedSubCategory,
            selectedCategoryName: selectedCategory,
            onSubCategorySelected: (index) {
              setState(() => selectedSubCategory = index);
            },
          ),

          // All Matajer Shops
          // ✅ INTERNET CHECK
          !isConnected
              ? SliverToBoxAdapter(
                  child: NoInternetWidget(
                    onRetry: () async {
                      await checkConnectivity();
                      if (isConnected) {
                        ProductCubit.get(context).getSellers(shopType: '');
                      }
                    },
                  ),
                )
              : HomeShopsWidget(
                  displayShops: displayShops,
                  landscapeMode: landscapeMode,
                  shopType: selectedCategory,
                  scrollController: _scrollController,
                  onSuccess: (value) {
                    setState(() => displayShops = value);
                  },
                ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
