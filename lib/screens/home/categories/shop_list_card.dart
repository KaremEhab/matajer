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
import 'package:matajer/screens/home/categories/shop_grid_card.dart';
import 'package:matajer/screens/home/shop_screen.dart';
import 'package:matajer/screens/home/widgets/favorites_icon.dart';
import 'package:matajer/widgets/delete_shop_prodcuts_dialog.dart';
import 'package:shimmer/shimmer.dart';
import '../../../constants/colors.dart';

class ShopListCard extends StatefulWidget {
  const ShopListCard({super.key, required this.shopModel});

  final ShopModel shopModel;

  @override
  State<ShopListCard> createState() => _ShopListCardState();
}

class _ShopListCardState extends State<ShopListCard> {
  bool? _isFavoritedLocal;

  late final num rating;
  late final num numberOfRating;
  late final num sumOfRating;

  @override
  void initState() {
    super.initState();
    final favCubit = FavoritesCubit.get(context);
    final shopId = widget.shopModel.shopId;

    _isFavoritedLocal =
        favCubit.favouritesModel?.favShops.contains(shopId) ?? false;
    sumOfRating = widget.shopModel.sumOfRating;
    numberOfRating = widget.shopModel.numberOfRating == 0
        ? 1
        : widget.shopModel.numberOfRating;
    rating = sumOfRating / numberOfRating;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 2, 7, 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            slideAnimation(
              context: context,
              destination: ShopScreen(shopModel: widget.shopModel),
              rightSlide: true,
            );
          },
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: greyColor.withOpacity(0.2),
                width: 2,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    // Banner
                    RepaintBoundary(
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        clipBehavior: Clip.antiAliasWithSaveLayer,
                        decoration: const BoxDecoration(),
                        child: widget.shopModel.shopBannerUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.shopModel.shopBannerUrl,
                                fit: BoxFit.cover,
                                progressIndicatorBuilder:
                                    (context, url, progress) =>
                                        shimmerPlaceholder(
                                          width: double.infinity,
                                          height: 180,
                                          radius: 22.r,
                                        ),
                                errorWidget: (context, url, error) =>
                                    buildBannerFallback(context, 180),
                              )
                            : buildBannerFallback(context, 180),
                      ),
                    ),

                    // Details
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 20,
                      ),
                      child: Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 5,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.shopModel.shopName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.verified_rounded,
                                color: primaryColor,
                                size: 20,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Subcategories
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: widget.shopModel.subcategories
                                    .map((e) => e.trim().toLowerCase())
                                    .toSet() // Remove duplicates
                                    .map((sub) {
                                      final capitalized = sub.isNotEmpty
                                          ? sub[0].toUpperCase() +
                                                sub.substring(1)
                                          : '';
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: greyColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            5.r,
                                          ),
                                        ),
                                        child: Text(
                                          capitalized,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: greyColor,
                                          ),
                                        ),
                                      );
                                    })
                                    .toList(),
                              ),

                              // Rating
                              Row(
                                spacing: 2,
                                children: [
                                  Text(rating.toStringAsFixed(1)),
                                  Text('(${widget.shopModel.numberOfRating})'),
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 22,
                                    color: CupertinoColors.systemYellow,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Logo
                Positioned(
                  bottom: 60,
                  right: lang == 'en' ? 11 : null,
                  left: lang == 'ar' ? 11 : null,
                  child: RepaintBoundary(
                    child: GestureDetector(
                      onTap: () => showProfilePreview(
                        context: context,
                        imageUrl: widget.shopModel.shopLogoUrl,
                      ),
                      child: Hero(
                        tag: widget.shopModel.shopLogoUrl,
                        child: Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15.r),
                            border: Border.all(
                              color: greyColor.withOpacity(0.4),
                              strokeAlign: BorderSide.strokeAlignOutside,
                            ),
                          ),
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          child: CachedNetworkImage(
                            imageUrl: widget.shopModel.shopLogoUrl,
                            fit: BoxFit.cover,
                            progressIndicatorBuilder:
                                (context, url, progress) => shimmerPlaceholder(
                                  width: 90,
                                  height: 90,
                                  radius: 15.r,
                                ),
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Favorite/Delete icon
                Positioned(
                  top: 0.01.sh,
                  right: 0.015.sw,
                  child: widget.shopModel.sellerId == currentUserModel.uId
                      ? RepaintBoundary(
                          child: Material(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(200),
                            child: InkWell(
                              onTap: () {
                                DeleteShopAndAllProductsDialog.show(
                                  context: context,
                                  shopModel: widget.shopModel,
                                  currentUserId: uId,
                                );
                              },
                              borderRadius: BorderRadius.circular(200),
                              child: const Padding(
                                padding: EdgeInsets.all(9),
                                child: Icon(
                                  IconlyBold.delete,
                                  color: Colors.white,
                                  size: 23,
                                ),
                              ),
                            ),
                          ),
                        )
                      : BlocBuilder<FavoritesCubit, FavoritesStates>(
                          builder: (context, state) {
                            final favCubit = FavoritesCubit.get(context);
                            final shopId = widget.shopModel.shopId;

                            final isFavorited =
                                _isFavoritedLocal ??
                                favCubit.favouritesModel!.favShops.contains(
                                  shopId,
                                );

                            return FavoriteHeartIcon(
                              iconSize: 23,
                              padding: 9,
                              isFavorited: isFavorited,
                              onTap: isGuest
                                  ? () {
                                      final scaffold = ScaffoldMessenger.of(
                                        context,
                                      );
                                      scaffold.hideCurrentSnackBar();
                                      scaffold.showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 20.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
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
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w600,
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
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(
                                                    S.of(context).sign_up,
                                                    style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.w600,
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
                                      final scaffold = ScaffoldMessenger.of(
                                        context,
                                      );
                                      setState(() {
                                        _isFavoritedLocal = !isFavorited;
                                      });
                                      scaffold.hideCurrentSnackBar();

                                      await favCubit.toggleFavoriteShop(
                                        userId: currentUserModel.uId,
                                        shopId: shopId,
                                      );

                                      setState(() => _isFavoritedLocal = null);

                                      final isNowFav =
                                          favCubit.favouritesModel?.favShops
                                              .contains(shopId) ??
                                          false;

                                      scaffold.showSnackBar(
                                        SnackBar(
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 20.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
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
                                                      destination:
                                                          const Favourites(),
                                                      rightSlide: true,
                                                    );
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.all(
                                                      8.0,
                                                    ),
                                                    child: Text(
                                                      S.of(context).view_all,
                                                      style: TextStyle(
                                                        color: primaryColor,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget shimmerPlaceholder({double? width, double? height, double? radius}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius ?? 12),
      ),
    ),
  );
}
