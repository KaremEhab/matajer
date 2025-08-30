import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/login/login_cubit.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/auth/login.dart';
import 'package:matajer/screens/auth/register_as_seller.dart';
import 'package:matajer/screens/auth/signup.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/layout.dart';
import 'package:matajer/screens/profile/widget/profile_shop_buttons.dart';
import 'package:matajer/widgets/delete_shop_prodcuts_dialog.dart';

class ManageShopAppBar extends StatefulWidget {
  const ManageShopAppBar({
    super.key,
    required this.showCollapsedActions,
    required this.changeBannerButton,
    required this.changeLogoButton,
  });

  final bool showCollapsedActions;
  final void Function() changeBannerButton, changeLogoButton;

  @override
  State<ManageShopAppBar> createState() => _ManageShopAppBarState();
}

class _ManageShopAppBarState extends State<ManageShopAppBar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final isCollapsed =
            constraints.scrollOffset >
            (260.h - kToolbarHeight); // collapse threshold

        if (_isCollapsed != isCollapsed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isCollapsed = isCollapsed;
                log('AppBar collapsed state changed: $_isCollapsed');
              });
            }
          });
        }

        return SliverAppBar(
          expandedHeight: 260.h,
          pinned: true,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: false,
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            title: _isCollapsed ? _buildCollapsedHeader() : null,
            background: !_isCollapsed ? _buildExpandedBackground() : null,
          ),
        );
      },
    );
  }

  Widget _buildCollapsedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            spacing: 5,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: senderColor,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 15,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(200.r),
                          child: CachedNetworkImage(
                            imageUrl: currentShopModel!.shopLogoUrl,
                            progressIndicatorBuilder:
                                (context, url, progress) => shimmerPlaceholder(
                                  height: 50,
                                  width: 50,
                                  radius: 200.r,
                                ),
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: Text(
                  currentShopModel!.shopName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: formFieldColor,
          borderRadius: BorderRadius.circular(12.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(12.r),
            onTap: () {
              DeleteShopAndAllProductsDialog.show(
                context: context,
                shopModel: currentShopModel!,
                currentUserId: uId,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(IconlyLight.delete, size: 22, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedBackground() {
    return Column(
      children: [
        SizedBox(
          height: 270.h,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onLongPress: () => showProfilePreview(
                  context: context,
                  isProfile: false,
                  imageUrl: currentShopModel!.shopBannerUrl,
                ),
                onTap: widget.changeBannerButton,
                child: SizedBox(
                  height: 0.2.sh,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: currentShopModel!.shopBannerUrl,
                    progressIndicatorBuilder: (context, url, progress) =>
                        shimmerPlaceholder(
                          height: double.infinity,
                          width: double.infinity,
                          radius: 0,
                        ),
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -10,
                child: Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onLongPress: () => showProfilePreview(
                              context: context,
                              imageUrl: currentShopModel!.shopLogoUrl,
                            ),
                            onTap: widget.changeLogoButton,
                            child: Hero(
                              tag: currentShopModel!.shopLogoUrl,
                              child: Container(
                                padding: EdgeInsets.all(5.h),
                                decoration: BoxDecoration(
                                  color: senderColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(4.h),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: CircleAvatar(
                                    radius: 55.h,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        200.r,
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: currentShopModel!.shopLogoUrl,
                                        progressIndicatorBuilder:
                                            (context, url, progress) =>
                                                shimmerPlaceholder(
                                                  height: 110.h,
                                                  width: 110.h,
                                                  radius: 200.r,
                                                ),
                                        height: 110.h,
                                        width: 110.h,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        spacing: 5,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentShopModel!.shopName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
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
        FirebaseFirestore.instance.collection('users').doc(uId).update({
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
  }
}
