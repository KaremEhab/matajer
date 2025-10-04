import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/favorites/favorites_cubit.dart';
import 'package:matajer/cubit/favorites/favorites_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/favourites/fav_shops.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/widgets/favorites_icon.dart';

class ProductDetailsAppBar extends StatefulWidget {
  const ProductDetailsAppBar({
    super.key,
    required this.productModel,
    required this.productScrollOffsetNotifier,
  });

  final ProductModel productModel;
  final ValueListenable<double> productScrollOffsetNotifier;

  @override
  State<ProductDetailsAppBar> createState() => _ProductDetailsAppBarState();
}

class _ProductDetailsAppBarState extends State<ProductDetailsAppBar>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  bool? _isFavoritedLocal;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isFavoritedLocal = FavoritesCubit.get(
      context,
    ).favouritesModel?.favProducts.contains(widget.productModel.id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    if (index >= 0 && index < widget.productModel.images.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<double>(
      valueListenable: widget.productScrollOffsetNotifier,
      builder: (context, productScrollOffset, _) {
        return SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          titleSpacing: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: transparentColor,
            systemNavigationBarColor: transparentColor,
          ),
          expandedHeight: 0.4.sh,
          flexibleSpace: RepaintBoundary(
            child: Stack(
              children: [
                _buildImageCarousel(),
                _buildScrollBackground(productScrollOffset),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBackButton(productScrollOffset),
                        Row(
                          spacing: 5,
                          children: [
                            if (!isGuest) _buildFavoriteIcon(),
                            _buildShareButton(),
                            _buildCopyButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScrollBackground(double offset) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: offset >= 300.h ? 130 : 0,
        color: scaffoldColor,
      ),
    );
  }

  Widget _buildBackButton(double offset) {
    return Row(
      children: [
        _roundedIconButton(
          icon: backIcon(),
          onTap: () => Navigator.pop(context),
        ),
        if (offset > 370.h)
          Padding(
            padding: EdgeInsets.only(
              left: lang == 'en' ? 8 : 0,
              right: lang == 'en' ? 0 : 8,
            ),
            child: Text(
              widget.productModel.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteIcon() {
    return BlocBuilder<FavoritesCubit, FavoritesStates>(
      builder: (context, state) {
        final favCubit = FavoritesCubit.get(context);
        final productId = widget.productModel.id;
        final isSynced =
            favCubit.favouritesModel?.favProducts.contains(productId) ?? false;

        return FavoriteHeartIcon(
          iconSize: 22,
          padding: 10,
          radius: 12.r,
          color: Colors.white,
          hasBorder: true,
          isFavorited: _isFavoritedLocal ?? isSynced,
          onTap: () async {
            setState(
              () => _isFavoritedLocal = !(_isFavoritedLocal ?? isSynced),
            );

            await favCubit.toggleFavoriteProduct(
              userId: currentUserModel.uId,
              productId: productId,
            );

            setState(() => _isFavoritedLocal = null);

            final isNowFav =
                favCubit.favouritesModel?.favProducts.contains(productId) ??
                false;

            _showFavoriteSnackBar(isNowFav);
          },
        );
      },
    );
  }

  void _showFavoriteSnackBar(bool isNowFav) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 20.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        content: Row(
          children: [
            Icon(
              isNowFav ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: isNowFav ? primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isNowFav
                    ? S.of(context).added_to_favorites
                    : S.of(context).removed_from_favorites,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isNowFav)
              InkWell(
                onTap: () => slideAnimation(
                  context: context,
                  destination: Favourites(initialIndex: 1),
                  rightSlide: true,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
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
  }

  Widget _buildShareButton() {
    return _roundedIconButton(icon: Icons.share, onTap: () {});
  }

  Widget _buildCopyButton() {
    return _roundedIconButton(
      icon: Icons.copy,
      onTap: () async {
        await Clipboard.setData(
          ClipboardData(text: "#${widget.productModel.id}"),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).productId_copied_to_clipboard),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _roundedIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: textColor.withOpacity(0.2)),
          ),
          child: Icon(icon, color: textColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.productModel.images.isEmpty
            ? Material(
                color: lightGreyColor.withOpacity(0.4),
                child: Center(child: Icon(IconlyLight.image, size: 75)),
              )
            : PageView.builder(
                controller: _pageController,
                itemCount: widget.productModel.images.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (_, index) => GestureDetector(
                  onTap: () => showProfilePreview(
                    context: context,
                    isProfile: false,
                    imageUrl: widget.productModel.images[index],
                  ),
                  child: Hero(
                    tag: widget.productModel.images[index],
                    child: CachedNetworkImage(
                      imageUrl: widget.productModel.images[index],
                      fit: BoxFit.cover,
                      progressIndicatorBuilder: (_, __, ___) =>
                          shimmerPlaceholder(
                            width: double.infinity,
                            height: double.infinity,
                            radius: 0,
                          ),
                      errorWidget: (_, __, ___) => const Icon(Icons.error),
                    ),
                  ),
                ),
              ),
        if (_currentPage > 0)
          _carouselArrow(
            alignment: lang == 'en'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            icon: backIcon(),
            onTap: () => _goToPage(_currentPage - 1),
          ),
        if (_currentPage < widget.productModel.images.length - 1)
          _carouselArrow(
            alignment: lang == 'ar'
                ? Alignment.centerLeft
                : Alignment.centerRight,
            icon: forwardIcon(),
            onTap: () => _goToPage(_currentPage + 1),
          ),
      ],
    );
  }

  Widget _carouselArrow({
    required Alignment alignment,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 30),
          onPressed: onTap,
        ),
      ),
    );
  }
}
