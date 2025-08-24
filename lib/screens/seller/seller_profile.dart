import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/profile/widget/profile_app_settings.dart';
import 'package:matajer/screens/profile/widget/profile_custom_appBar.dart';
import 'package:matajer/screens/profile/widget/profile_shop_buttons.dart';
import 'package:matajer/screens/profile/widget/profile_user_settings.dart';
import 'package:matajer/screens/seller/widgets/profile_product_settings.dart';
import 'package:matajer/screens/seller/widgets/profile_seller_settings.dart';
import 'package:matajer/screens/seller/widgets/profile_shop_settings.dart';

class SellerProfile extends StatefulWidget {
  const SellerProfile({super.key, required this.shopModel});

  final ShopModel shopModel;

  @override
  State<SellerProfile> createState() => _SellerProfileState();
}

class _SellerProfileState extends State<SellerProfile> {
  final ScrollController _scrollController = ScrollController();
  bool showCollapsedActions = false;

  @override
  void initState() {
    super.initState();

    _setStatusBarStyle();
    _scrollController.addListener(_handleScroll);
  }

  void _setStatusBarStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
  }

  void _handleScroll() {
    final threshold = currentUserModel.shops.isNotEmpty ? 0.33.sh : 0.43.sh;
    final offset = _scrollController.position.pixels;

    if (offset >= threshold && !showCollapsedActions) {
      setState(() => showCollapsedActions = true);
    } else if (offset < threshold && showCollapsedActions) {
      setState(() => showCollapsedActions = false);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            ProfileCustomAppBar(showCollapsedActions: showCollapsedActions),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  spacing: 10,
                  children: [
                    const ShopManagement(),
                    const SizedBox(height: 1),
                    const UserSettings(),
                    SellerSettings(),
                    ShopSettings(),
                    ProductSettings(shopModel: widget.shopModel),
                    AppSettings(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildTabButton({
  required String label,
  required dynamic icon,
  required bool isActive,
  required VoidCallback onTap,
  bool isSvg = true,
}) {
  return Material(
    color: isActive ? primaryColor : formFieldColor,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isSvg
                ? SvgPicture.asset(
                  icon,
                  height: 20,
                  color: isActive ? Colors.white : textColor,
                )
                : Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : textColor,
                ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
