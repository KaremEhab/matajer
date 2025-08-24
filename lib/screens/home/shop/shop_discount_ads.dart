import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/models/shop_model.dart';

class ShopDiscountAds extends StatelessWidget {
  final ShopModel shopModel;
  final Function() discountButton;

  const ShopDiscountAds({
    super.key,
    required this.shopModel,
    required this.discountButton,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(7, 5, 7, 10),
        child: Column(
          spacing: 5,
          children: [
            Material(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: discountButton,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    spacing: 10,
                    children: [
                      Icon(IconlyLight.discount, color: primaryColor, size: 22),
                      Flexible(
                        child: Text(
                          "Subscribe now and save 15% on all products",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
