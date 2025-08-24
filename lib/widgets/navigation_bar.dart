import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/auth/login.dart';
import 'package:matajer/screens/auth/register_as_seller.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/layout.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isSeller; // ✅ added

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isSeller, // ✅ required flag
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    List<Widget> customerIcons = [
      _navItem(
        lightIcons: IconlyLight.home,
        boldIcons: IconlyBold.home,
        index: 0,
      ),
      _navItem(
        lightIcons: IconlyLight.search,
        boldIcons: IconlyBold.search,
        index: 1,
      ),
      _navItem(
        lightIcons: IconlyLight.bag,
        boldIcons: IconlyBold.bag,
        index: 2,
      ),
      _navItem(
        lightIcons: IconlyLight.message,
        boldIcons: IconlyBold.message,
        index: 3,
      ),
      _profileItem(index: 4),
    ];

    List<Widget> sellerIcons = [
      _navItem(
        lightIcons: IconlyLight.document,
        boldIcons: IconlyBold.document,
        index: 0,
      ),
      _navItem(
        lightIcons: IconlyLight.chart,
        boldIcons: IconlyBold.chart,
        index: 1,
      ),
      _navItem(
        lightIcons: IconlyLight.paper_plus,
        boldIcons: IconlyBold.paper_plus,
        index: 2,
      ),
      _navItem(
        lightIcons: IconlyLight.message,
        boldIcons: IconlyBold.message,
        index: 3,
      ),
      _profileItem(index: 4),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 0, 7, 10),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 1300),
            curve: Curves.easeInOut,
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xff000D26).withOpacity(0.1),
              ),
              color: const Color(0xffF5F6F7).withOpacity(0.7),
              borderRadius: const BorderRadius.all(Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widget.isSeller
                  ? sellerIcons.map((item) => Expanded(child: item)).toList()
                  : customerIcons.map((item) => Expanded(child: item)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required IconData boldIcons,
    required IconData lightIcons,
    required int index,
  }) {
    const Color activeColor = primaryColor;
    const Color inactiveColor = Color(0xff000D26);

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),

            // 🛒 / 💬 / 📦 badges + loading for home
            if (index == 2 && !widget.isSeller)
              // Cart badge
              BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  int count = ProductCubit.get(
                    context,
                  ).totalCartQuantity.toInt();
                  return _buildIconWithBadge(
                    boldIcons,
                    lightIcons,
                    index,
                    count,
                  );
                },
              )
            else if (index == 3)
              // Chat badge
              StreamBuilder<int>(
                stream: ChatsCubit.instance.getTotalUnseenMessagesCount(
                  widget.isSeller
                      ? currentShopModel!.shopId
                      : currentUserModel.uId,
                ),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  return _buildIconWithBadge(
                    boldIcons,
                    lightIcons,
                    index,
                    count,
                  );
                },
              )
            else if (index == 0 && !widget.isSeller)
              // Home badge + loading state
              BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  final count = 0; // or any badge number for home if needed
                  if (state is ProductGetSellersLoadingState) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: widget.currentIndex == index
                                ? primaryColor
                                : inactiveColor,
                            strokeWidth: 3.5,
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  } else {
                    return _buildIconWithBadge(
                      boldIcons,
                      lightIcons,
                      index,
                      count,
                    );
                  }
                },
              )
            else if (index == 0 && widget.isSeller)
              // Seller active orders badge
              BlocBuilder<ProductCubit, ProductState>(
                builder: (context, state) {
                  final count = OrderCubit.get(context).activeOrdersCount;
                  return _buildIconWithBadge(
                    boldIcons,
                    lightIcons,
                    index,
                    count,
                  );
                },
              )
            else
              Icon(
                widget.currentIndex == index ? boldIcons : lightIcons,
                color: widget.currentIndex == index
                    ? primaryColor
                    : inactiveColor,
                size: widget.currentIndex == index ? 25 : 22,
              ),

            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: widget.currentIndex == index ? 70 : 0,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(
    IconData boldIcons,
    IconData lightIcons,
    int index,
    int count,
  ) {
    const Color activeColor = primaryColor;
    const Color inactiveColor = Color(0xff000D26);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          widget.currentIndex == index ? boldIcons : lightIcons,
          color: widget.currentIndex == index ? activeColor : inactiveColor,
          size: widget.currentIndex == index ? 25 : 22,
        ),
        if (count > 0)
          Positioned(
            right: -6,
            top: -6,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }

  Widget _profileItem({required int index}) {
    return GestureDetector(
      onTap: () {
        if (index != 4) {
          widget.onTap(index);
        } else {
          if (widget.currentIndex == 4) {
            _openShopSwitcherModal(context);
          } else {
            widget.onTap(4);
          }
        }
      },
      onLongPress: () => _openShopSwitcherModal(context),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: widget.currentIndex == index ? 12 : 15),
            // avatar + messages badge
            StreamBuilder<int>(
              stream: ChatsCubit.instance.getTotalUnseenMessagesCount(uId),
              builder: (context, chatSnapshot) {
                final chatCount = chatSnapshot.data ?? 0;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('sellerId', isEqualTo: uId)
                      .where(
                        'orderStatus',
                        whereIn: [
                          OrderStatus.pending.index,
                          OrderStatus.accepted.index,
                          OrderStatus.shipped.index,
                          // add any other non-delivered statuses
                        ],
                      )
                      .snapshots(),
                  builder: (context, orderSnapshot) {
                    int totalProducts = 0;

                    if (orderSnapshot.hasData) {
                      for (var doc in orderSnapshot.data!.docs) {
                        final products =
                            doc['products'] as List<dynamic>? ?? [];
                        totalProducts += products.length;
                      }
                    }

                    final totalCount = totalProducts + chatCount;

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD7E0FF),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: widget.currentIndex == index ? 14 : 12,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(200.r),
                                child: CachedNetworkImage(
                                  imageUrl: currentUserModel.profilePicture!,
                                  progressIndicatorBuilder:
                                      (context, url, progress) =>
                                          shimmerPlaceholder(
                                            height: widget.currentIndex == index
                                                ? 14
                                                : 12,
                                            width: widget.currentIndex == index
                                                ? 14
                                                : 12,
                                            radius: 200.r,
                                          ),
                                  height: widget.currentIndex == index
                                      ? 29
                                      : 27,
                                  width: widget.currentIndex == index ? 29 : 27,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (totalCount > 0)
                          Positioned(
                            right: -3,
                            top: -6,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                totalCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
            // StreamBuilder<int>(
            //   stream: widget.isSeller
            //       ? ChatsCubit.instance.getTotalUnseenMessagesCount(
            //           currentUserModel.uId,
            //         )
            //       : ChatsCubit.instance.getTotalUnseenMessagesForMultipleShops(
            //           currentUserModel.shops
            //               .map((e) => e['id'] as String)
            //               .toList(),
            //         ),
            //   builder: (context, snapshot) {
            //     final count = snapshot.data ?? 0;
            //     return Stack(
            //       clipBehavior: Clip.none,
            //       children: [
            //         Container(
            //           padding: const EdgeInsets.all(2),
            //           decoration: const BoxDecoration(
            //             color: Color(0xFFD7E0FF),
            //             shape: BoxShape.circle,
            //           ),
            //           child: Container(
            //             padding: const EdgeInsets.all(2),
            //             decoration: const BoxDecoration(
            //               color: primaryColor,
            //               shape: BoxShape.circle,
            //             ),
            //             child: CircleAvatar(
            //               radius: widget.currentIndex == index ? 14 : 12,
            //               child: ClipRRect(
            //                 borderRadius: BorderRadius.circular(200.r),
            //                 child: CachedNetworkImage(
            //                   imageUrl: currentUserModel.profilePicture!,
            //                   progressIndicatorBuilder:
            //                       (context, url, progress) =>
            //                           shimmerPlaceholder(
            //                             height: widget.currentIndex == index
            //                                 ? 14
            //                                 : 12,
            //                             width: widget.currentIndex == index
            //                                 ? 14
            //                                 : 12,
            //                             radius: 200.r,
            //                           ),
            //                   height: widget.currentIndex == index ? 29 : 27,
            //                   width: widget.currentIndex == index ? 29 : 27,
            //                   fit: BoxFit.cover,
            //                 ),
            //               ),
            //             ),
            //           ),
            //         ),
            //         if (count > 0)
            //           Positioned(
            //             right: -3,
            //             top: -6,
            //             child: Container(
            //               padding: const EdgeInsets.all(5),
            //               decoration: const BoxDecoration(
            //                 color: Colors.red,
            //                 shape: BoxShape.circle,
            //               ),
            //               child: Text(
            //                 count.toString(),
            //                 style: const TextStyle(
            //                   color: Colors.white,
            //                   fontSize: 10,
            //                 ),
            //               ),
            //             ),
            //           ),
            //       ],
            //     );
            //   },
            // ),
            SizedBox(height: widget.currentIndex == index ? 12 : 15),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: widget.currentIndex == index ? 70 : 0,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openShopSwitcherModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _ShopSwitcherContent(),
    );
  }
}

class _ShopSwitcherContent extends StatefulWidget {
  const _ShopSwitcherContent();

  @override
  State<_ShopSwitcherContent> createState() => _ShopSwitcherContentState();
}

class _ShopSwitcherContentState extends State<_ShopSwitcherContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _switchToShop(String shopId) async {
    OrderCubit.get(context).activeOrdersCount = 0;
    // Check first before updating anything
    if (isSeller &&
        currentShopModel != null &&
        currentShopModel!.shopId == shopId) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).you_are_already_managing_this_shop),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Now it's safe to update
    await UserCubit.get(context).getShopById(shopId);

    Navigator.pop(context);
    isSeller = true;

    navigateAndFinish(
      context: context,
      screen: const Layout(getUserData: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final shops = currentUserModel.shops;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shops.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final shop = shops[index];
                  final shopId = shop['id'];
                  final shopName = shop['name'];
                  final shopLogo = shop['logo'];
                  final shopCategory = shop['category'];

                  final currentShopId = currentShopModel != null
                      ? currentShopModel!.shopId
                      : shopId;
                  final isCounterVisible = currentShopModel != null
                      ? true
                      : false;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    tileColor: currentShopModel == null
                        ? Colors.grey[100]
                        : currentShopModel!.shopId == shopId
                        ? secondaryColor
                        : Colors.grey[100],
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: CachedNetworkImage(
                        imageUrl: shopLogo ?? currentUserModel.profilePicture,
                        progressIndicatorBuilder: (_, __, ___) =>
                            shimmerPlaceholder(
                              height: 60,
                              width: 60,
                              radius: 100,
                            ),
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: currentShopModel == null
                                ? textColor
                                : currentShopModel!.shopId == shopId
                                ? primaryColor
                                : textColor,
                          ),
                        ),
                        Text(
                          '${S.of(context).category}: $shopCategory',
                          style: TextStyle(
                            color: currentShopModel == null
                                ? textColor
                                : currentShopModel!.shopId == shopId
                                ? primaryColor
                                : textColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Builder(
                      builder: (context) {
                        final isCurrentShop =
                            currentShopModel != null &&
                            currentShopModel!.shopId == shopId;

                        // Show check icon if this is the current shop
                        if (isCurrentShop) {
                          return Icon(
                            Icons.check_circle_rounded,
                            color: primaryColor,
                          );
                        }

                        // Otherwise, show counter + forward arrow
                        return StreamBuilder<int>(
                          stream: ChatsCubit.instance
                              .getTotalUnseenMessagesCount(uId),
                          builder: (context, chatSnapshot) {
                            final chatCount = chatSnapshot.data ?? 0;

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('orders')
                                  .where('shopId', isEqualTo: shopId)
                                  .where(
                                    'orderStatus',
                                    whereIn: [
                                      OrderStatus.pending.index,
                                      OrderStatus.accepted.index,
                                      OrderStatus.shipped.index,
                                    ],
                                  )
                                  .snapshots(),
                              builder: (context, orderSnapshot) {
                                int totalProducts = 0;
                                if (orderSnapshot.hasData) {
                                  for (var doc in orderSnapshot.data!.docs) {
                                    final products =
                                        doc['products'] as List<dynamic>? ?? [];
                                    totalProducts += products.length;
                                  }
                                }

                                final totalCount = totalProducts + chatCount;

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Show counter if > 0
                                    if (totalCount > 0)
                                      CircleAvatar(
                                        backgroundColor: Colors.red,
                                        radius: 12,
                                        child: Text(
                                          totalCount > 99
                                              ? '+99'
                                              : '$totalCount',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    Icon(
                                      forwardIcon(),
                                      color: textColor.withOpacity(0.7),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                    onTap: () => _switchToShop(shopId),
                  );
                },
              ),
              const SizedBox(height: 5),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        Row(
          children: [
            Expanded(
              child: ActionButton(
                color: secondaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterAsSeller(),
                    ),
                  ).then((value) {
                    // After RegisterSellerPage pops, refresh sellers
                    ProductCubit.get(context).getSellers(shopType: '');
                  });
                },
                child: Row(
                  spacing: 5,
                  mainAxisAlignment: isSeller
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 10,
                      children: [
                        if (isSeller) _buildAddShopIcon(),
                        Text(
                          isSeller
                              ? S.of(context).new_shop
                              : currentUserModel.shops.isEmpty
                              ? S.of(context).establish_your_first_shop
                              : S.of(context).create_a_new_shop,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (!isSeller) _buildAddShopIcon(),
                  ],
                ),
              ),
            ),
            if (isSeller) const SizedBox(width: 10),
            if (isSeller)
              Expanded(
                child: ActionButton(
                  color: primaryColor,
                  onTap: () {
                    if (!currentUserModel.hasShop) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterAsSeller(),
                        ),
                      ).then((value) {
                        // After RegisterSellerPage pops, refresh sellers
                        ProductCubit.get(context).getSellers(shopType: '');
                      });
                    } else {
                      isSeller = false;

                      CacheHelper.removeData(key: 'currentShopModel');

                      // Set in-memory model to null
                      currentShopModel = null;

                      // Navigate to buyer layout
                      navigateAndFinish(
                        context: context,
                        screen: const Layout(getUserData: false),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "images/switch-shops.svg",
                        color: Colors.white,
                        height: 23,
                        width: 23,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        S.of(context).buyer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: ActionButton(
            color: Colors.red,
            isOutlined: true,
            onTap: () async {
              if (!context.mounted) return;
              isSeller = false;
              isGuest = false;
              currentShopModel = null;
              navigateAndFinish(context: context, screen: const Login());
              await GoogleSignIn().signOut(); // force account picker
              try {
                await Future.wait([
                  CacheHelper.removeData(key: 'uId'),
                  CacheHelper.removeData(key: 'currentShopModel'),
                  CacheHelper.removeData(key: 'currentUserModel'),
                  UserCubit.get(context).setActivityStatus(
                    userId: uId,
                    statusValue: UserActivityStatus.offline.name,
                  ),
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uId)
                      .update({
                        'fcmTokens': FieldValue.arrayRemove([fcmDeviceToken]),
                      }),
                  FirebaseFirestore.instance
                      .collection('shop')
                      .doc(currentShopModel!.shopId)
                      .update({
                        'fcmTokens': FieldValue.arrayRemove([fcmDeviceToken]),
                      }),
                ]);
              } catch (e) {
                debugPrint('Logout error: \$e');
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(IconlyLight.logout, color: Colors.red, size: 23),
                const SizedBox(width: 8),
                Text(
                  S.of(context).logout,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddShopIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SvgPicture.asset(
          "images/shop-icon-outlined.svg",
          color: primaryColor,
          height: 24,
          width: 24,
        ),
        const Positioned(
          top: 0,
          bottom: 0,
          right: -8,
          child: CircleAvatar(
            radius: 8,
            backgroundColor: secondaryColor,
            child: Text(
              "+",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color color;
  final bool isOutlined;
  final Color? borderColor;

  const ActionButton({super.key, 
    required this.onTap,
    required this.child,
    required this.color,
    this.isOutlined = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? color;

    return Material(
      color: isOutlined ? Colors.transparent : color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: isOutlined
            ? BorderSide(color: effectiveBorderColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: child,
        ),
      ),
    );
  }
}
