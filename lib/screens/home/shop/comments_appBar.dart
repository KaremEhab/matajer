import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';

class CommentsAppBar extends StatefulWidget {
  const CommentsAppBar({
    super.key,
    required this.shopModel,
    required this.totalRatings,
    required this.commentsScrollOffsetNotifier,
  });

  final ShopModel shopModel;
  final int totalRatings;
  final ValueListenable<double> commentsScrollOffsetNotifier;

  @override
  State<CommentsAppBar> createState() => _CommentsAppBarState();
}

class _CommentsAppBarState extends State<CommentsAppBar>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<double>(
      valueListenable: widget.commentsScrollOffsetNotifier,
      builder: (context, shopScrollOffset, _) {
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
                CachedNetworkImage(
                  imageUrl: widget.shopModel.shopLogoUrl,
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (_, __, ___) => shimmerPlaceholder(
                    width: double.infinity,
                    height: double.infinity,
                    radius: 0,
                  ),
                  width: double.infinity,
                  height: double.infinity,
                  errorWidget: (_, __, ___) => const Icon(Icons.error),
                ),
                _buildScrollBackground(shopScrollOffset),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: AppBar(
                    forceMaterialTransparency: true,
                    leadingWidth: 53,
                    leading: _roundedIconButton(
                      icon: backIcon(),
                      onTap: () => Navigator.pop(context),
                    ),
                    title: shopScrollOffset >= 300.h
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
                      if (shopScrollOffset >= 300.h)
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
                                          : (widget.shopModel.sumOfRating /
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
}
