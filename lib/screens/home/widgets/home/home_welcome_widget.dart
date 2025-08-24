import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/filters/filters.dart';
import 'package:matajer/screens/layout.dart';

class HomeWelcomeWidget extends StatelessWidget {
  HomeWelcomeWidget({super.key});

  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(7, 0, 7, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeTexts(context),
            SizedBox(height: 15),
            Form(
              key: formKey,
              child: Row(
                children: [
                  Expanded(flex: 5, child: _buildSearchField(context)),
                  SizedBox(width: 8),
                  _buildFilterButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeTexts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).connecting_you,
            style: TextStyle(
              fontSize: 32,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            S.of(context).celebrating_homegrown,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: greyColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextFormField(
      controller: searchController,
      readOnly: true,
      decoration: InputDecoration(
        hintText: S.of(context).searching_for,
        hintStyle: TextStyle(fontSize: 15, color: Colors.grey),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: SvgPicture.asset(
            "images/search-outlined.svg",
            color: Colors.grey,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
      onTap: () {
        layoutPageController!.jumpToPage(1);
        FocusScope.of(context).unfocus();
      },
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return Material(
      color: formFieldColor,
      borderRadius: BorderRadius.circular(15.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(15.r),
        onTap: () {
          slideAnimation(
            context: context,
            destination: const Filters(),
            rightSlide: true,
          );
        },
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Icon(Icons.filter_list_alt, color: primaryColor, size: 28),
        ),
      ),
    );
  }
}
