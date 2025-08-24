
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
import 'package:matajer/screens/profile/widget/profile_shop_buttons.dart';

class ProfileCustomAppBar extends StatefulWidget {
  const ProfileCustomAppBar({super.key, required this.showCollapsedActions});

  final bool showCollapsedActions;

  @override
  State<ProfileCustomAppBar> createState() => _ProfileCustomAppBarState();
}

class _ProfileCustomAppBarState extends State<ProfileCustomAppBar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260.h,
      pinned: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final shouldCollapse = top <= kToolbarHeight + 30;

          if (_isCollapsed != shouldCollapse) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _isCollapsed = shouldCollapse);
            });
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                color: _isCollapsed ? primaryColor : Colors.transparent,
              ),
              FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                title: _isCollapsed ? _buildCollapsedHeader() : null,
                background: _buildExpandedBackground(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCollapsedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            spacing: isSeller ? 30 : 10,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (isSeller)
                    Positioned(
                      left: lang == 'en' ? 0 : -50,
                      right: lang == 'en' ? -50 : 0,
                      child: Container(
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
                                    (context, url, progress) =>
                                        shimmerPlaceholder(
                                          height: 50,
                                          width: 50,
                                          radius: 200.r,
                                        ),
                                height: 50,
                                width: 30,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                            imageUrl: currentUserModel.profilePicture!,
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
                  isSeller
                      ? "${currentUserModel.username} & ${currentShopModel!.shopName}"
                      : isGuest
                      ? S.of(context).guest
                      : currentUserModel.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (!isGuest)
              if (widget.showCollapsedActions) ...[
                IconButton(
                  tooltip: S.of(context).new_shop,
                  onPressed: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterAsSeller(),
                        ),
                      ).then((value) {
                        UserCubit.get(context).markShouldRefreshSellers();
                      }),
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SvgPicture.asset(
                        "images/shop-icon-outlined.svg",
                        color: Colors.white,
                        height: 24,
                        width: 24,
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: -8,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: primaryColor,
                          child: Text(
                            "+",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentUserModel.shops.isNotEmpty &&
                    widget.showCollapsedActions)
                  IconButton(
                    tooltip: S.of(context).switch_to_shop,
                    onPressed: () => handleSwitchTap(context),
                    icon: SvgPicture.asset(
                      "images/switch-shops.svg",
                      color: Colors.white,
                      height: 23,
                      width: 23,
                    ),
                  ),
              ],
            if (isGuest)
              Row(
                spacing: 5,
                children: [
                  GestureDetector(
                    onTap: () {
                      navigateTo(context: context, screen: SignUp());
                    },
                    child: Chip(
                      label: Text(
                        S.of(context).sign_up,
                        style: TextStyle(color: primaryColor),
                      ),
                      side: BorderSide.none,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      LoginCubit.get(context).deleteAnonymousGuest(context);
                    },
                    child: Chip(
                      label: Text(
                        S.of(context).sign_in,
                        style: TextStyle(color: primaryColor),
                      ),
                      side: BorderSide.none,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedBackground() {
    return Column(
      children: [
        SizedBox(
          height: 230.h,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 0.15.sh,
                color: primaryColor,
                width: double.infinity,
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset('images/shape.png', fit: BoxFit.cover),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 10.h,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  forceMaterialTransparency: true,
                  title: Text(
                    S.of(context).settings,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    if (!isGuest)
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(
                          IconlyLight.logout,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -10,
                child: Center(
                  child: Column(
                    children: [
                      isSeller
                          ? SizedBox(
                              width: 220.h,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  if (isSeller)
                                    Positioned(
                                      left: lang == 'en' ? 0 : -110,
                                      right: lang == 'en' ? -110 : 0,
                                      child: GestureDetector(
                                        onTap: () => showProfilePreview(
                                          context: context,
                                          imageUrl: isSeller
                                              ? currentShopModel!.shopLogoUrl
                                              : currentUserModel
                                                    .profilePicture!,
                                        ),
                                        child: Hero(
                                          tag: isSeller
                                              ? currentShopModel!.shopLogoUrl
                                              : currentUserModel
                                                    .profilePicture!,
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
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        200.r,
                                                      ),
                                                  child: CachedNetworkImage(
                                                    imageUrl: isSeller
                                                        ? currentShopModel!
                                                              .shopLogoUrl
                                                        : currentUserModel
                                                              .profilePicture!,
                                                    progressIndicatorBuilder:
                                                        (
                                                          context,
                                                          url,
                                                          progress,
                                                        ) => shimmerPlaceholder(
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
                                    ),
                                  GestureDetector(
                                    onTap: () => showProfilePreview(
                                      context: context,
                                      imageUrl:
                                          currentUserModel.profilePicture!,
                                    ),
                                    child: Hero(
                                      tag: currentUserModel.profilePicture!,
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
                                              borderRadius:
                                                  BorderRadius.circular(200.r),
                                              child: CachedNetworkImage(
                                                imageUrl: currentUserModel
                                                    .profilePicture!,
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
                            )
                          : Stack(
                              clipBehavior: Clip.none,
                              children: [
                                if (isSeller)
                                  Positioned(
                                    left: 0,
                                    right: -110,
                                    child: GestureDetector(
                                      onTap: () => showProfilePreview(
                                        context: context,
                                        imageUrl: isSeller
                                            ? currentShopModel!.shopLogoUrl
                                            : currentUserModel.profilePicture!,
                                      ),
                                      child: Hero(
                                        tag:
                                            "${isSeller ? currentShopModel!.shopLogoUrl : currentUserModel.profilePicture}",
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
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      200.r,
                                                    ),
                                                child: CachedNetworkImage(
                                                  imageUrl: isSeller
                                                      ? currentShopModel!
                                                            .shopLogoUrl
                                                      : currentUserModel
                                                            .profilePicture!,
                                                  progressIndicatorBuilder:
                                                      (
                                                        context,
                                                        url,
                                                        progress,
                                                      ) => shimmerPlaceholder(
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
                                  ),
                                GestureDetector(
                                  onTap: () => showProfilePreview(
                                    context: context,
                                    imageUrl: currentUserModel.profilePicture!,
                                  ),
                                  child: Hero(
                                    tag: currentUserModel.profilePicture!,
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
                                              imageUrl: currentUserModel
                                                  .profilePicture!,
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
                            isGuest
                                ? S.of(context).guest
                                : currentUserModel.username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isSeller)
                            Text(
                              '&',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (isSeller)
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
