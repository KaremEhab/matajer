import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class ReviewsAppBar extends StatefulWidget {
  const ReviewsAppBar({
    super.key,
    required this.productModel,
    required this.totalRatings,
    required this.reviewsScrollOffsetNotifier,
  });

  final ProductModel productModel;
  final int totalRatings;
  final ValueListenable<double> reviewsScrollOffsetNotifier;

  @override
  State<ReviewsAppBar> createState() => _ReviewsAppBarState();
}

class _ReviewsAppBarState extends State<ReviewsAppBar>
    with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
      valueListenable: widget.reviewsScrollOffsetNotifier,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: AppBar(
                    forceMaterialTransparency: true,
                    leadingWidth: 53,
                    leading: _roundedIconButton(
                      icon: backIcon(),
                      onTap: () => Navigator.pop(context),
                    ),
                    title: productScrollOffset >= 300.h
                        ? Text(
                            S.of(context).reviews,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          )
                        : null,
                    centerTitle: true,
                    actions: [
                      if (productScrollOffset >= 300.h)
                        Row(
                          spacing: 5,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Rating section
                            Row(
                              spacing: 5,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "(${widget.totalRatings})",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  (widget.totalRatings == 0
                                          ? 0
                                          : (widget.productModel.sumOfRating /
                                                widget.totalRatings))
                                      .toStringAsFixed(1),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Icon(IconlyBold.star, color: Colors.amber),
                          ],
                        ),
                    ],
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
        height: offset >= 300.h ? 100.h : 0,
        color: scaffoldColor,
      ),
    );
  }

  Widget _roundedIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: Material(
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
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.productModel.images.isEmpty
            ? shimmerPlaceholder(
                width: double.infinity,
                height: double.infinity,
                radius: 0,
              )
            : PageView.builder(
                controller: _pageController,
                itemCount: widget.productModel.images.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (_, index) => CachedNetworkImage(
                  imageUrl: widget.productModel.images[index],
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (_, __, ___) => shimmerPlaceholder(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 0,
                  ),
                  errorWidget: (_, __, ___) => const Icon(Icons.error),
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
