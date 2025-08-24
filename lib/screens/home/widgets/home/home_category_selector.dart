import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/home/widgets/category_animated_items.dart';

class HomeCategorySelector extends StatelessWidget {
  final int selectedCategory;
  final Function(int) onCategorySelected;
  final bool displayShops;
  final Function(bool) setDisplayShops;

  const HomeCategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.displayShops,
    required this.setDisplayShops,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> categoriesList = [
      S.of(context).matajer,
      ...matajerEnglishCategories.map((e) => e["name"] as String),
    ];

    return SliverToBoxAdapter(
      child: RepaintBoundary(
        child: Container(
          height: 105,
          color: Colors.white,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.only(bottom: 15),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            cacheExtent: 300,
            itemCount: categoriesList.length,
            itemBuilder: (context, index) {
              final category = categoriesList[index];
              final isSelected = selectedCategory == index;
              final icon = categoryEnglishIcons[category];

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 7 : 0,
                  right: index == categoriesList.length - 1 ? 7 : 3,
                ),
                child: AnimatedCategoryItem(
                  isSelected: isSelected,
                  onTap: () {
                    onCategorySelected(index);
                    print('Selected Category: $category');
                    if (category == S.of(context).matajer) {
                      ProductCubit.get(context).getSellers(shopType: '');
                    } else {
                      final englishCategory =
                          matajerEnglishCategories[index - 1]['name'];
                      ProductCubit.get(
                        context,
                      ).getSellers(shopType: englishCategory);
                    }

                    setDisplayShops(true);
                  },
                  icon: category == S.of(context).matajer
                      ? Image.asset('images/shop.png', height: 30)
                      : Icon(
                          icon,
                          size: 30,
                          color: isSelected ? primaryColor : textColor,
                        ),
                  text: category,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
