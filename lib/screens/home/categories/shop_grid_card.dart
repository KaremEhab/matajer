import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/favorites/favorites_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/favourites/fav_shops.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/shop_screen.dart';
import 'package:matajer/screens/home/widgets/favorites_icon.dart';
import 'package:matajer/widgets/delete_shop_prodcuts_dialog.dart';
import '../../../../../constants/colors.dart';

class ShopGridCard extends StatefulWidget {
  const ShopGridCard({super.key, required this.shopModel});
  final ShopModel shopModel;

  @override
  State<ShopGridCard> createState() => _ShopGridCardState();
}

class _ShopGridCardState extends State<ShopGridCard> {
  bool? _isFavoritedLocal;
  List uniqueSubcategories = [];
  late num rating;

  @override
  void initState() {
    super.initState();
    final favCubit = FavoritesCubit.get(context);
    final shopId = widget.shopModel.shopId;
    _isFavoritedLocal =
        favCubit.favouritesModel?.favShops.contains(shopId) ?? false;
    final sum = widget.shopModel.sumOfRating;
    final count = widget.shopModel.numberOfRating == 0
        ? 1
        : widget.shopModel.numberOfRating;
    rating = sum / count;

    uniqueSubcategories = widget.shopModel.subcategories
        .map((e) => e.trim().toLowerCase())
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(7, 2, 7, 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          splashColor: Colors.purpleAccent.withOpacity(0.1),
          highlightColor: Colors.transparent,
          onTap: () {
            slideAnimation(
              context: context,
              destination: ShopScreen(shopModel: widget.shopModel),
              rightSlide: true,
            );
          },
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  strokeAlign: BorderSide.strokeAlignOutside,
                  color: formFieldColor,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Banner
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: widget.shopModel.shopBannerUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.shopModel.shopBannerUrl,
                                  fit: BoxFit.cover,
                                  progressIndicatorBuilder:
                                      (context, url, progress) =>
                                          shimmerPlaceholder(
                                            width: double.infinity,
                                            height: double.infinity,
                                            radius: 0,
                                          ),
                                  errorWidget: (context, url, error) =>
                                      buildBannerFallback(
                                        context,
                                        double.infinity,
                                      ),
                                )
                              : buildBannerFallback(context, double.infinity),
                        ),
                      ),

                      // Logo
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0.195.sw,
                        child: Center(
                          child: RepaintBoundary(
                            child: Container(
                              padding: EdgeInsets.all(3.w),
                              width: 0.15.sw,
                              height: 0.15.sw,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                  strokeAlign: BorderSide.strokeAlignOutside,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(100.r),
                                child: CachedNetworkImage(
                                  imageUrl: widget.shopModel.shopLogoUrl,
                                  fit: BoxFit.cover,
                                  progressIndicatorBuilder: (context, url, _) =>
                                      shimmerPlaceholder(
                                        width: 0.15.sw,
                                        height: 0.15.sh,
                                        radius: 100.r,
                                      ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Left Rating
                      Positioned(
                        left: 4.w,
                        bottom: 5.h,
                        child: Row(
                          spacing: 5,
                          children: [
                            Icon(
                              IconlyBold.star,
                              size: 13.w,
                              color: CupertinoColors.systemYellow,
                            ),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Favorite/Delete Icons
                      Positioned(
                        top: 0.01.sh,
                        right: 0.015.sw,
                        child: widget.shopModel.sellerId == currentUserModel.uId
                            ? RepaintBoundary(
                                child: Material(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: const OvalBorder(),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(100.r),
                                    onTap: () {
                                      DeleteShopAndAllProductsDialog.show(
                                        context: context,
                                        shopModel: widget.shopModel,
                                        currentUserId: uId,
                                      );
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(6.w),
                                      child: Icon(
                                        IconlyBold.delete,
                                        color: Colors.red,
                                        size: 18.w,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : BlocBuilder<FavoritesCubit, FavoritesStates>(
                                builder: (context, state) {
                                  final favCubit = FavoritesCubit.get(context);
                                  final shopId = widget.shopModel.shopId;
                                  final synced =
                                      favCubit.favouritesModel?.favShops
                                          .contains(shopId) ??
                                      false;

                                  return RepaintBoundary(
                                    child: FavoriteHeartIcon(
                                      iconSize: 18.h,
                                      padding: 7,
                                      isFavorited: _isFavoritedLocal ?? synced,
                                      onTap: isGuest
                                          ? () {
                                              final scaffold =
                                                  ScaffoldMessenger.of(context);
                                              scaffold.hideCurrentSnackBar();
                                              scaffold.showSnackBar(
                                                SnackBar(
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  margin: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 20.h,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                  ),
                                                  backgroundColor: Colors.white,
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        IconlyBold.login,
                                                        color: primaryColor,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          S
                                                              .of(context)
                                                              .create_an_account,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          slideAnimation(
                                                            context: context,
                                                            destination:
                                                                const Favourites(),
                                                            rightSlide: true,
                                                          );
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsets.all(
                                                                8.0,
                                                              ),
                                                          child: Text(
                                                            S
                                                                .of(context)
                                                                .sign_up,
                                                            style: TextStyle(
                                                              color:
                                                                  primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }
                                          : () async {
                                              final scaffold =
                                                  ScaffoldMessenger.of(context);
                                              setState(() {
                                                _isFavoritedLocal =
                                                    !(_isFavoritedLocal ??
                                                        synced);
                                              });
                                              scaffold.hideCurrentSnackBar();
                                              await favCubit.toggleFavoriteShop(
                                                userId: currentUserModel.uId,
                                                shopId: shopId,
                                              );
                                              setState(
                                                () => _isFavoritedLocal = null,
                                              );
                                              final isNowFav =
                                                  favCubit
                                                      .favouritesModel
                                                      ?.favShops
                                                      .contains(shopId) ??
                                                  false;
                                              scaffold.showSnackBar(
                                                SnackBar(
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  margin: EdgeInsets.symmetric(
                                                    horizontal: 10.w,
                                                    vertical: 20.h,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                  ),
                                                  backgroundColor: Colors.white,
                                                  content: Row(
                                                    children: [
                                                      Icon(
                                                        isNowFav
                                                            ? CupertinoIcons
                                                                  .heart_fill
                                                            : CupertinoIcons
                                                                  .heart,
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
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ),
                                                      if (isNowFav)
                                                        InkWell(
                                                          onTap: () {
                                                            slideAnimation(
                                                              context: context,
                                                              destination:
                                                                  const Favourites(),
                                                              rightSlide: true,
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  8.0,
                                                                ),
                                                            child: Text(
                                                              S
                                                                  .of(context)
                                                                  .view_all,
                                                              style: TextStyle(
                                                                color:
                                                                    primaryColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

                // Text Info
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(5.w, 18.h, 5.w, 7.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          spacing: 5.w,
                          children: [
                            Flexible(
                              child: Text(
                                widget.shopModel.shopName,
                                style: TextStyle(
                                  color: const Color(0xFF241838),
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.verified,
                              size: 18.sp,
                              color: primaryColor,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                spacing: 3.w,
                                children: [
                                  Icon(
                                    Icons.verified_outlined,
                                    size: 13.w,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    S.of(context).good_quality,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 13.w,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    '${widget.shopModel.deliveryDays} ${S.of(context).days}',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 13.w,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              '${S.of(context).response_time}: ${widget.shopModel.avgResponseTime} ${S.of(context).minutes}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        SizedBox(
                          height: 28.h,
                          child: ListView.builder(
                            itemCount: uniqueSubcategories.length,
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final subCategory = uniqueSubcategories[index];
                              final capitalized = subCategory.isNotEmpty
                                  ? subCategory[0].toUpperCase() +
                                        subCategory.substring(1)
                                  : '';

                              return Container(
                                margin: const EdgeInsets.only(right: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                decoration: BoxDecoration(
                                  color: formFieldColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    capitalized,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildBannerFallback(BuildContext context, double height) {
  return Stack(
    children: [
      Container(
        height: height,
        color: primaryColor,
        width: double.infinity,
        child: Opacity(
          opacity: 0.1,
          child: Image.asset('images/shape.png', fit: BoxFit.cover),
        ),
      ),
      Center(
        child: Text(
          S.of(context).no_banner,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
