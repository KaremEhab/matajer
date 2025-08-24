import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/reviews/reviews.dart';

class ProductDetailsReviews extends StatefulWidget {
  const ProductDetailsReviews({super.key, required this.productModel});

  final ProductModel productModel;

  @override
  State<ProductDetailsReviews> createState() => _ProductDetailsReviewsState();
}

class _ProductDetailsReviewsState extends State<ProductDetailsReviews>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 350;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIllustration(isNarrow),
                  const SizedBox(width: 15),
                  _buildReviewTextAndButton(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(bool isNarrow) {
    return SvgPicture.asset(
      "images/reviews-illustration.svg",
      height: isNarrow ? 100 : 130,
    );
  }

  Widget _buildReviewTextAndButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).go_to_reviews_tip,
          textAlign: TextAlign.start,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _buildGoToReviewsButton(),
      ],
    );
  }

  Widget _buildGoToReviewsButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        navigateTo(
          context: context,
          screen: Reviews(productModel: widget.productModel),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.of(context).go_to_reviews,
              style: TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.arrow_right_alt_rounded, color: primaryColor),
          ],
        ),
      ),
    );
  }
}
