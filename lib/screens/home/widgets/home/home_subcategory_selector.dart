import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/screens/home/widgets/sticky_header_delegate.dart';

class HomeSubcategorySelector extends StatelessWidget {
  final int selectedSubCategory;
  final Function(int) onSubCategorySelected;
  final int selectedCategoryName;

  const HomeSubcategorySelector({
    super.key,
    required this.selectedSubCategory,
    required this.onSubCategorySelected,
    required this.selectedCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    final List categories = matajerEnglishCategories;
    final List<String> subCategories = selectedCategoryName == 0
        ? []
        : [
            "ALL",
            ...List<String>.from(
              categories[selectedCategoryName - 1]["subCategories"] ?? [],
            ),
          ];

    if (subCategories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: StickyHeaderDelegate(
        height: 50,
        child: RepaintBoundary(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              cacheExtent: 300,
              itemCount: subCategories.length,
              itemBuilder: (context, index) {
                final isSelected = selectedSubCategory == index;

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 7 : 0,
                    right: index == subCategories.length - 1 ? 7 : 3,
                  ),
                  child: Material(
                    color: isSelected ? primaryColor : formFieldColor,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        onSubCategorySelected(index);
                        final category =
                            matajerEnglishCategories[selectedCategoryName -
                                1]["name"];
                        final subCat = subCategories[index];

                        if (index == 0) {
                          ProductCubit.get(
                            context,
                          ).getSellers(shopType: category);
                        } else {
                          ProductCubit.get(
                            context,
                          ).getSellers(shopType: subCat);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Center(
                          child: Text(
                            subCategories[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
