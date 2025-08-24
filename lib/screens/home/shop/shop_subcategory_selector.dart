import 'package:flutter/material.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/screens/home/widgets/sticky_header_delegate.dart';

class ShopSubcategorySelector extends StatelessWidget {
  final int selectedSubCategory;
  final List<String> productsList;
  final Function(int) onSubCategorySelected;
  final String shopCategory;

  const ShopSubcategorySelector({
    super.key,
    required this.productsList,
    required this.selectedSubCategory,
    required this.onSubCategorySelected,
    required this.shopCategory,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: StickyHeaderDelegate(
        height: 50,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: productsList.length,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              itemBuilder: (context, index) {
                final isSelected = selectedSubCategory == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: isSelected ? primaryColor : formFieldColor,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSubCategorySelected(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Center(
                          child: Text(
                            productsList[index],
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
