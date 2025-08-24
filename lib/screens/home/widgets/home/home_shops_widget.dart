import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gif/gif.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/auth/register_as_seller.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/categories/shop_grid_card.dart';
import 'package:matajer/screens/home/shop/shop_grid_shimmer.dart';
import 'package:matajer/screens/home/shop/shop_list_shimmer.dart';
import 'package:matajer/widgets/no_internet.dart';

class HomeShopsWidget extends StatefulWidget {
  final bool displayShops;
  final bool landscapeMode;
  final Function(bool) onSuccess;
  final int shopType;
  final ScrollController scrollController;

  const HomeShopsWidget({
    super.key,
    required this.displayShops,
    required this.landscapeMode,
    required this.onSuccess,
    this.shopType = 0,
    required this.scrollController, // ← add this
  });

  @override
  State<HomeShopsWidget> createState() => _HomeShopsWidgetState();
}

class _HomeShopsWidgetState extends State<HomeShopsWidget>
    with
        TickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<HomeShopsWidget> {
  late final GifController controller1;
  late final ImageProvider gifImage;

  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;
  bool isConnected = true;

  Future<void> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
    print("isConnected: $isConnected");
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    controller1 = GifController(vsync: this);
    gifImage = const AssetImage('images/closed-stores.gif');

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
      print("Home Shops Connectivity changed: isConnected = $connected");
    });

    widget.scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return; // ✅ Safely ignore if widget is disposed
    final cubit = ProductCubit.get(context);
    log('Scroll position: ${widget.scrollController.position.pixels}');
    log('Max extent: ${widget.scrollController.position.maxScrollExtent}');
    log(
      'isLoadingMore: ${cubit.isLoadingMore}, reachedEnd: ${cubit.reachedEnd}',
    );

    if (widget.scrollController.position.pixels >=
            widget.scrollController.position.maxScrollExtent - 200 &&
        !cubit.isLoadingMore &&
        !cubit.reachedEnd) {
      final List<String> categoriesList = [
        S.of(context).matajer,
        ...matajerEnglishCategories.map((e) => e["name"] as String),
      ];
      cubit.getMoreSellers(
        shopType: widget.shopType == 0 ? '' : categoriesList[widget.shopType],
        context: context,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(gifImage, context);
  }

  @override
  void dispose() {
    controller1.dispose();
    _connectivitySubscription.cancel();
    // _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cubit = ProductCubit.get(context);
    final sellers = cubit.shops;

    return SliverPadding(
      padding: EdgeInsets.only(bottom: sellers.isEmpty ? 160 : 100),
      sliver: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductGetSellersSuccessState) {
            widget.onSuccess(true);
          }
        },
        builder: (context, state) {
          // 1️⃣ No Internet
          if (!isConnected) {
            return SliverToBoxAdapter(
              child: NoInternetWidget(
                onRetry: () async {
                  await checkConnectivity();
                  if (isConnected) {
                    cubit.getSellers(shopType: '');
                  }
                },
              ),
            );
          }

          // 2️⃣ Show shimmer only if actually loading first fetch
          if (state is ProductGetSellersLoadingState && sellers.isEmpty) {
            return widget.landscapeMode
                ? const ShopListShimmer()
                : const ShopGridShimmer();
          }

          // 3️⃣ Show "no shops" if the list is empty after success
          if (sellers.isEmpty) {
            return SliverToBoxAdapter(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    child: Gif(
                      width: 0.95.sw,
                      controller: controller1,
                      autostart: Autostart.loop,
                      placeholder: (context) =>
                          shimmerPlaceholder(width: 0.95.sw, height: 300),
                      image: gifImage,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      S.of(context).no_shops_found,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 0.7.sw,
                    child: Material(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterAsSeller(),
                            ),
                          ).then((value) {
                            cubit.getSellers(shopType: '');
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                S.of(context).start_selling,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 17.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_right_alt_rounded,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // 4️⃣ Display shops with pagination indicator if loading more
          return widget.landscapeMode
              ? SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == sellers.length &&
                          state is ProductGetMoreSellersLoadingState) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return RepaintBoundary(
                        child: ShopListCard(shopModel: sellers[index]),
                      );
                    },
                    childCount:
                        sellers.length +
                        (state is ProductGetMoreSellersLoadingState ? 1 : 0),
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 0,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == sellers.length &&
                          state is ProductGetMoreSellersLoadingState) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return RepaintBoundary(
                        child: ShopGridCard(shopModel: sellers[index]),
                      );
                    },
                    childCount:
                        sellers.length +
                        (state is ProductGetMoreSellersLoadingState ? 1 : 0),
                  ),
                );
        },
      ),
    );
  }
}
