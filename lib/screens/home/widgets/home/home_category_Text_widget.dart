import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/home/widgets/sticky_header_delegate.dart';

class HomeCategoryTextWidget extends StatelessWidget {
  final int selectedCategory;
  final bool landscapeMode;
  final Function(int) onCategorySelected;
  final Function(bool) onViewModeChanged;
  final ValueListenable<double> homeScrollOffsetNotifier;

  const HomeCategoryTextWidget({
    super.key,
    required this.selectedCategory,
    required this.landscapeMode,
    required this.onCategorySelected,
    required this.onViewModeChanged,
    required this.homeScrollOffsetNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: homeScrollOffsetNotifier,
      builder: (context, homeScrollOffset, _) {
        return SliverPersistentHeader(
          pinned: true,
          delegate: StickyHeaderDelegate(
            height: 60,
            child: RepaintBoundary(
              child: Container(
                height: 60,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          final List<String> categoriesText = [
                            S.of(context).matajer,
                            ...matajerEnglishCategories.map(
                              (e) => e['name'] as String,
                            ),
                          ];

                          final selected = await showDialog<int>(
                            context: context,
                            builder: (context) {
                              return Dialog(
                                insetPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 100,
                                ),
                                backgroundColor: Colors.white,
                                clipBehavior: Clip.antiAliasWithSaveLayer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.5,
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    radius: const Radius.circular(8),
                                    thickness: 6,
                                    trackVisibility: true,
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: categoriesText.length,
                                      separatorBuilder: (_, __) => Padding(
                                        padding: EdgeInsetsGeometry.directional(
                                          end: 0.2.sw,
                                        ),
                                        child: const Divider(
                                          height: 1,
                                          color: secondaryColor,
                                        ),
                                      ),
                                      itemBuilder: (context, index) {
                                        final text = categoriesText[index];
                                        final isSelected =
                                            index == selectedCategory;
                                        final icon = categoryEnglishIcons[text];

                                        return InkWell(
                                          onTap: () =>
                                              Navigator.pop(context, index),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? primaryColor.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.transparent,
                                            ),
                                            child: Row(
                                              children: [
                                                text == S.of(context).matajer
                                                    ? Image.asset(
                                                        'images/shop.png',
                                                        height: 24,
                                                        width: 24,
                                                      )
                                                    : Icon(
                                                        icon,
                                                        size: 24,
                                                        color: isSelected
                                                            ? primaryColor
                                                            : textColor,
                                                      ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    text,
                                                    style: TextStyle(
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      color: isSelected
                                                          ? primaryColor
                                                          : textColor,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: primaryColor,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );

                          if (selected != null) {
                            onCategorySelected(selected);

                            final selectedText = categoriesText[selected];
                            ProductCubit.get(context).getSellers(
                              shopType: selectedText == S.of(context).matajer
                                  ? ''
                                  : selectedText,
                            );
                          }
                        },
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(-0.3, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Builder(
                              builder: (context) {
                                final categoriesText = [
                                  S.of(context).matajer,
                                  ...matajerEnglishCategories.map(
                                    (e) => e['name'] as String,
                                  ),
                                ];

                                return Row(
                                  key: ValueKey(
                                    homeScrollOffset >= homeCategoriesOffset
                                        ? "selected_${categoriesText[selectedCategory]}"
                                        : 'default_Categories',
                                  ),
                                  children: [
                                    if (homeScrollOffset >=
                                        homeCategoriesOffset)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 6,
                                        ),
                                        child:
                                            categoriesText[selectedCategory] ==
                                                S.of(context).matajer
                                            ? Image.asset(
                                                'images/shop.png',
                                                height: 20,
                                              )
                                            : Icon(
                                                categoryEnglishIcons[categoriesText[selectedCategory]],
                                                size: 20,
                                                color: textColor,
                                              ),
                                      ),
                                    Flexible(
                                      child: Text(
                                        homeScrollOffset >= homeCategoriesOffset
                                            ? categoriesText[selectedCategory]
                                            : S.of(context).categories,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                    if (homeScrollOffset >=
                                        homeCategoriesOffset)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 5),
                                        child: Icon(
                                          Icons.swap_vert_circle_outlined,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // View mode switch
                    Container(
                      width: 90,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: primaryColor),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            left: lang == 'en'
                                ? landscapeMode
                                      ? 0
                                      : 45
                                : landscapeMode
                                ? 45
                                : 0,
                            top: 0,
                            bottom: 0,
                            width: 45,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => onViewModeChanged(true),
                                  child: Center(
                                    child: Icon(
                                      CupertinoIcons.tv_fill,
                                      size: 18,
                                      color: landscapeMode
                                          ? Colors.white
                                          : primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => onViewModeChanged(false),
                                  child: Center(
                                    child: Icon(
                                      CupertinoIcons.square_grid_2x2_fill,
                                      size: 18,
                                      color: !landscapeMode
                                          ? Colors.white
                                          : primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
