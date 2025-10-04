import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/chat/chat_cubit.dart';
import 'package:matajer/cubit/comments/comments_cubit.dart';
import 'package:matajer/cubit/comments/comments_state.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/favorites/favorites_state.dart';
import 'package:matajer/cubit/user/user_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/comments_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/models/user_model.dart';
import 'package:matajer/screens/favourites/fav_shops.dart';
import 'package:matajer/screens/home/categories/shop_grid_card.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/shop/shop_comments.dart';
import 'package:matajer/screens/home/widgets/favorites_icon.dart';
import 'package:matajer/screens/whatsApp/chat_page.dart';
import 'package:matajer/seller_search_screen.dart';
import 'package:matajer/widgets/delete_shop_prodcuts_dialog.dart';

class ShopAppBar extends StatefulWidget {
  final num rating;
  final ShopModel shopModel;
  final List<String> productsList;
  final ValueListenable<double> shopScrollOffsetNotifier;

  const ShopAppBar({
    super.key,
    required this.rating,
    required this.shopModel,
    required this.productsList,
    required this.shopScrollOffsetNotifier,
  });

  @override
  State<ShopAppBar> createState() => _ShopAppBarState();
}

class _ShopAppBarState extends State<ShopAppBar> {
  bool? _isFavoritedLocal;
  bool display = false;

  final userEmirate = currentUserModel.emirate;
  late Map<String, dynamic> option;
  late num deliveryDays;

  @override
  void initState() {
    super.initState();

    option = widget.shopModel.deliveryOptions
        .cast<Map<String, dynamic>>()
        .firstWhere((opt) => opt['emirate'] == userEmirate);

    deliveryDays = option['days'] ?? 0;

    final favCubit = FavoritesCubit.get(context);
    final shopId = widget.shopModel.shopId;
    _isFavoritedLocal =
        favCubit.favouritesModel?.favShops.contains(shopId) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.shopScrollOffsetNotifier,
      builder: (context, shopScrollOffset, _) {
        return SliverAppBar(
          pinned: true,
          floating: false,
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          titleSpacing: 0,
          expandedHeight: CommentsCubit.get(context).comments.isNotEmpty
              ? 0.47.sh
              : 0.47.sh - 140.h,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarBrightness: shopScrollOffset >= 430.h
                ? Brightness.dark
                : Brightness.light,
            systemNavigationBarColor: transparentColor,
          ),
          flexibleSpace: Stack(
            children: [
              SizedBox(
                height: 255,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    widget.shopModel.shopBannerUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.shopModel.shopBannerUrl,
                            fit: BoxFit.cover,
                            progressIndicatorBuilder:
                                (context, url, progress) => shimmerPlaceholder(
                                  width: double.infinity,
                                  height: 255,
                                  radius: 0,
                                ),
                            errorWidget: (context, url, error) =>
                                buildBannerFallback(context, 255),
                          )
                        : buildBannerFallback(context, 255),
                    Material(color: textColor.withOpacity(0.4)),

                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 100.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.white],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: shopScrollOffset >= 430.h ? 70 : 0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Center(
                  child: Column(
                    spacing: 5.h,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 0.15.sh),

                      // Shop Details
                      RepaintBoundary(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 700),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            heightFactor: shopScrollOffset >= 350.h ? 0 : 1,
                            widthFactor: shopScrollOffset >= 350.h ? 0 : 1,
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeInOut,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 7),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.2),
                                    // strokeAlign: BorderSide.strokeAlignOutside,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // --- Shop logo and name ---
                                    Row(
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            15.r,
                                          ),
                                          onTap: () {},
                                          child: Container(
                                            height: 90,
                                            clipBehavior: Clip.antiAlias,
                                            decoration: BoxDecoration(
                                              color: primaryColor.withOpacity(
                                                0.1,
                                              ),
                                              border: Border.all(
                                                color: Colors.grey.withOpacity(
                                                  0.2,
                                                ),
                                                strokeAlign: BorderSide
                                                    .strokeAlignOutside,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(15.r),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl:
                                                  widget.shopModel.shopLogoUrl,
                                              progressIndicatorBuilder:
                                                  (context, url, progress) =>
                                                      shimmerPlaceholder(
                                                        width: 90,
                                                        height: 90,
                                                        radius: 15.r,
                                                      ),
                                              width: 90,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 8,
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              left: lang == 'en' ? 10 : 0,
                                              right: lang == 'ar' ? 10 : 0,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        spacing: 5,
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              widget
                                                                  .shopModel
                                                                  .shopName,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                color:
                                                                    textColor,
                                                              ),
                                                            ),
                                                          ),
                                                          Icon(
                                                            Icons.verified,
                                                            color: primaryColor,
                                                            size: 19,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          "(${widget.shopModel.numberOfRating})",
                                                          style: TextStyle(
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          widget.rating
                                                              .toStringAsFixed(
                                                                1,
                                                              ),
                                                          style: TextStyle(
                                                            color: textColor,
                                                          ),
                                                        ),
                                                        SizedBox(width: 2),
                                                        Icon(
                                                          Icons.star_rounded,
                                                          color: CupertinoColors
                                                              .systemYellow,
                                                          size: 22.h,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  widget
                                                      .shopModel
                                                      .shopDescription,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10),
                                    Divider(
                                      color: greyColor.withOpacity(0.2),
                                      thickness: 2,
                                    ),

                                    // --- Tags section ---
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.start,
                                      children: [
                                        buildTag(
                                          Icons.verified_outlined,
                                          S.of(context).good_quality,
                                        ),
                                        buildTag(
                                          Icons.access_time,
                                          '${S.of(context).avg_time}: ${widget.shopModel.formattedAvgResponseTime}',
                                        ),
                                        buildTag(
                                          Icons.local_shipping_outlined,
                                          '${deliveryDays} ${S.of(context).days}',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Shop Comments
                      BlocConsumer<CommentsCubit, CommentsState>(
                        listener: (context, state) {
                          if (state is CommentsSuccessState) {
                            display = !display;
                          }
                        },
                        builder: (context, state) {
                          // 🔹 Case 1: Loading → show shimmer placeholders
                          if (state is CommentsLoadingState) {
                            return Center(
                              child: SizedBox(
                                height: 130.h,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 3,
                                  separatorBuilder: (_, __) =>
                                      SizedBox(width: 10.w),
                                  itemBuilder: (context, index) {
                                    return shopAppBarCommentShimmer(
                                      shopScrollOffset,
                                    );
                                  },
                                ),
                              ),
                            );
                          }

                          // 🔹 Case 2: Success → show comments
                          if (state is CommentsSuccessState &&
                              CommentsCubit.get(context).comments.isNotEmpty) {
                            final comments = CommentsCubit.get(
                              context,
                            ).comments;

                            return Center(
                              child: SizedBox(
                                height: 130.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: comments.length,
                                  itemBuilder: (context, index) {
                                    final comment = comments[index];

                                    return FutureBuilder<UserModel>(
                                      future: UserCubit.get(
                                        context,
                                      ).getUserInfoById(comment.userId),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return SizedBox(
                                            width: 100.w,
                                            child: const Center(
                                              child:
                                                  CupertinoActivityIndicator(),
                                            ),
                                          );
                                        }

                                        if (!snapshot.hasData) {
                                          debugPrint(
                                            "⚠️ No user found for userId: ${comment.userId}",
                                          );
                                          return SizedBox(
                                            width: 100.w,
                                            child: const Center(
                                              child: Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            ),
                                          );
                                        }

                                        final user = snapshot.data!;

                                        // 🔹 Log the user info
                                        debugPrint(
                                          "Fetched User Info => ${user.toMap()}",
                                        );

                                        return _buildCommentCard(
                                          user,
                                          comment,
                                          index,
                                          shopScrollOffset,
                                          widget.shopModel,
                                          context,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                          }

                          // 🔹 Case 3: No comments → return nothing
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          title: Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 7),
            color: Colors.white.withOpacity(
              shopScrollOffset >= 430.h ? 1 : 0,
            ), // Optional
            child: Row(
              spacing: 20,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    spacing: 8,
                    children: [
                      Material(
                        color: formFieldColor,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Center(child: Icon(backIcon(), size: 26)),
                          ),
                        ),
                      ),
                      if (shopScrollOffset >= 430.h)
                        Expanded(
                          child: Row(
                            spacing: 5,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.shopModel.shopName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 21,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.verified,
                                color: primaryColor,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                Row(
                  spacing: 5,
                  children: [
                    // comment icon button
                    if (widget.shopModel.sellerId != currentUserModel.uId &&
                        currentUserModel.shopsVisibleToComment.contains(
                          widget.shopModel.shopId,
                        ))
                      Material(
                        color: formFieldColor,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () {
                            navigateTo(
                              context: context,
                              screen: ShopComments(shopModel: widget.shopModel),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              IconlyLight.chat,
                              size: 22,
                              color: textColor,
                            ),
                          ),
                        ),
                      ),

                    // search icon button
                    Material(
                      color: formFieldColor,
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () {
                          navigateTo(
                            context: context,
                            screen: ShopSearchScreen(shop: widget.shopModel),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            "images/search-outlined.svg",
                            height: 22,
                          ),
                        ),
                      ),
                    ),
                    if (!isGuest)
                      if (currentUserModel.uId != widget.shopModel.sellerId)
                        Material(
                          color: formFieldColor,
                          borderRadius: BorderRadius.circular(12.r),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.r),
                            onTap: () async {
                              final shopId = widget.shopModel.shopId;
                              final userId = currentUserModel.uId;
                              final chatId = '${userId}_$shopId';

                              await ChatsCubit.instance.createChatRoom(
                                userId: userId,
                                // userName: currentUserModel.username,
                                // userImage: currentUserModel.profilePicture!,
                                shopId: shopId,
                                // shopName: widget.shopModel.shopName,
                                // shopImage: widget.shopModel.shopLogoUrl,
                              );

                              log(
                                'chat between: ${currentUserModel.username} and ${widget.shopModel.shopName}',
                              );
                              log(
                                'chatId: $chatId, userId: $userId, shopId: $shopId, userName: ${currentUserModel.username}, userImage: ${currentUserModel.profilePicture}, shopName: ${widget.shopModel.shopName}, shopLogo: ${widget.shopModel.shopLogoUrl} ',
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailPage(
                                    chatId: chatId,
                                    receiverId: shopId,
                                    receiverName: widget.shopModel.shopName,
                                    receiverImage: widget.shopModel.shopLogoUrl,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Icon(IconlyLight.message, size: 22),
                            ),
                          ),
                        ),

                    // delete icon button
                    if (widget.shopModel.sellerId == currentUserModel.uId)
                      Material(
                        color: formFieldColor,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () {
                            DeleteShopAndAllProductsDialog.show(
                              context: context,
                              shopModel: widget.shopModel,
                              currentUserId: uId,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              IconlyLight.delete,
                              size: 22,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),

                    // favourite icon button
                    if (!isGuest)
                      if (widget.shopModel.sellerId != currentUserModel.uId)
                        BlocBuilder<FavoritesCubit, FavoritesStates>(
                          builder: (context, state) {
                            final favCubit = FavoritesCubit.get(context);
                            final shopId = widget.shopModel.shopId;

                            final isSyncedWithFirebase =
                                favCubit.favouritesModel?.favShops.contains(
                                  shopId,
                                ) ??
                                false;

                            return FavoriteHeartIcon(
                              iconSize: 22,
                              padding: 10,
                              radius: 12.r,
                              color: formFieldColor,
                              isFavorited:
                                  _isFavoritedLocal ?? isSyncedWithFirebase,
                              onTap: () async {
                                final scaffold = ScaffoldMessenger.of(context);

                                // ✅ خطوة 1: Optimistic UI (محلي)
                                setState(() {
                                  _isFavoritedLocal =
                                      !(_isFavoritedLocal ??
                                          isSyncedWithFirebase);
                                });

                                scaffold.hideCurrentSnackBar();

                                // ✅ خطوة 2: ارفع التغيير فعليًا
                                await favCubit.toggleFavoriteShop(
                                  userId: currentUserModel.uId,
                                  shopId: shopId,
                                );

                                // ✅ خطوة 3: لما التحديث يخلص، خليك متأكد إنك ترجع تقرا القيمة الصح من Firebase
                                setState(() {
                                  _isFavoritedLocal =
                                      null; // نخليها null عشان نستخدم القيمة الحقيقية
                                });

                                // ✅ خطوة 4: Show SnackBar
                                final isNowFav =
                                    favCubit.favouritesModel?.favShops.contains(
                                      shopId,
                                    ) ??
                                    false;

                                scaffold.showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 20.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    backgroundColor: Colors.white,
                                    content: Row(
                                      children: [
                                        Icon(
                                          isNowFav
                                              ? CupertinoIcons.heart_fill
                                              : CupertinoIcons.heart,
                                          color: isNowFav
                                              ? primaryColor
                                              : Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            isNowFav
                                                ? S
                                                      .of(context)
                                                      .added_to_favorites
                                                : S
                                                      .of(context)
                                                      .removed_from_favorites,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (isNowFav)
                                          InkWell(
                                            onTap: () {
                                              slideAnimation(
                                                context: context,
                                                destination: Favourites(),
                                                rightSlide: true,
                                              );
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Text(
                                                S.of(context).view_all,
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget shopAppBarCommentShimmer(double shopScrollOffset) {
  return RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        heightFactor: shopScrollOffset >= 150.h ? 0 : 1,
        widthFactor: shopScrollOffset >= 150.h ? 0 : 1,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: Center(
            child: Container(
              width: 0.97.sw,
              height: 130,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              margin: const EdgeInsets.fromLTRB(7, 10, 7, 10),
              decoration: BoxDecoration(
                color: scaffoldColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: textColor.withOpacity(0.1)),
              ),
              child: Column(
                spacing: 15,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Avatar + Name/Location + Stars/Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar shimmer
                      shimmerPlaceholder(height: 44, width: 44, radius: 100),
                      const SizedBox(width: 10),
                      // Username & emirate
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            shimmerPlaceholder(
                              width: 100,
                              height: 16,
                              radius: 4,
                            ),
                            const SizedBox(height: 4),
                            shimmerPlaceholder(
                              width: 60,
                              height: 13,
                              radius: 4,
                            ),
                          ],
                        ),
                      ),
                      // Stars & Date
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (index) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                child: shimmerPlaceholder(
                                  width: 16,
                                  height: 16,
                                  radius: 4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          shimmerPlaceholder(width: 80, height: 12, radius: 4),
                        ],
                      ),
                    ],
                  ),

                  // Comment shimmer (3 lines)
                  shimmerPlaceholder(
                    width: double.infinity,
                    height: 14,
                    radius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildCommentCard(
  UserModel user,
  CommentsModel comment,
  int index,
  double shopScrollOffset,
  ShopModel shopModel,
  BuildContext context,
) {
  return RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        heightFactor: shopScrollOffset >= 150.h ? 0 : 1,
        widthFactor: shopScrollOffset >= 150.h ? 0 : 1,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 7.h : 0,
                right: 10.h,
                top: 10.h,
              ),
              child: Material(
                color: scaffoldColor,
                borderRadius: BorderRadius.circular(15),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    navigateTo(
                      context: context,
                      screen: ShopComments(shopModel: shopModel),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(10.h),
                    width: CommentsCubit.get(context).comments.length == 1
                        ? 0.96.sw
                        : 300.w,
                    height: 0.32.sh,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: textColor.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD7E0FF),
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 23.h,
                                  backgroundImage: NetworkImage(
                                    user.profilePicture!,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.username,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                  Text(
                                    user.emirate,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(comment.rating.toString()),
                                  const Icon(
                                    Icons.star_rounded,
                                    color: CupertinoColors.systemYellow,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            comment.comment,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
