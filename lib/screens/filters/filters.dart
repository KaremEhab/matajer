import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/filter/filter_cubit.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/filters/widgets/filter_products.dart';
import 'package:matajer/screens/filters/widgets/filter_shops.dart';

class Filters extends StatefulWidget {
  const Filters({super.key});

  @override
  State<Filters> createState() => _FiltersState();
}

class _FiltersState extends State<Filters> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  RangeValues currentRangeValues = const RangeValues(0, 1000000);
  String? selectedMainCategory;
  String? selectedSubCategory;
  int currentFilterPage = 0;

  String selectedOption = 'Recommended';
  Set<String> selectedCities = {};

  late PageController pageController;

  void _onTabTapped(int index) {
    setState(() {
      currentFilterPage = index;
      selectedCities.clear();
      selectedSubCategory = null;
      selectedMainCategory = null;
      selectedOption = 'Recommended';
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: currentFilterPage);
  }

  @override
  void dispose() {
    selectedCities.clear();
    selectedMainCategory = null;
    selectedSubCategory = null;
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leadingWidth: 50,
        leading: Padding(
          padding: EdgeInsets.fromLTRB(7, 7, 0, 7),
          child: Material(
            color: formFieldColor,
            borderRadius: BorderRadius.circular(12.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () {
                Navigator.pop(context);
              },
              child: Center(child: Icon(Icons.close, size: 22)),
            ),
          ),
        ),
        title: Text(
          S.of(context).filters,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🟦 Buttons = Fake TabBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: buildTabButton(
                    label: S.of(context).matajer,
                    icon: "images/shop-icon-outlined.svg",
                    isActive: currentFilterPage == 0,
                    onTap: () => _onTabTapped(0),
                  ),
                ),
                Expanded(
                  child: buildTabButton(
                    label: S.of(context).products,
                    icon: IconlyLight.bag,
                    isActive: currentFilterPage == 1,
                    onTap: () => _onTabTapped(1),
                    isSvg: false,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          // 🟨 Page Content
          Expanded(
            child: PageView(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  currentFilterPage = index;
                });
              },
              children: [
                // 🛒 Matajer Filters Page
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sorting Options
                      Column(
                        spacing: 5,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).sort_by,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: formFieldColor,
                              borderRadius: BorderRadius.circular(10),
                            ),

                            child: ListView.builder(
                              itemCount: matajerSortOptions.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final option = matajerSortOptions[index];
                                final isSelected = selectedOption == option;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    setState(() {
                                      selectedOption = option;
                                    });
                                  },
                                  title: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryColor
                                          : textColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Radio<String>(
                                    value: option,
                                    groupValue: selectedOption,
                                    activeColor: primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedOption = value!;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // Emirates Options
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                S.of(context).emirates,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),

                              // Checkbox to select all Emirates
                              Checkbox(
                                value: selectedCities.length == cities.length
                                    ? true
                                    : selectedCities.isEmpty
                                    ? false
                                    : null, // Partially selected
                                tristate: true,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedCities = Set<String>.from(cities);
                                    } else {
                                      selectedCities.clear();
                                    }
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: formFieldColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.builder(
                              itemCount: cities.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final city = cities[index];
                                final isChecked = selectedCities.contains(city);

                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedCities.add(city);
                                      } else {
                                        selectedCities.remove(city);
                                      }
                                    });
                                  },
                                  title: Text(
                                    city,
                                    style: TextStyle(
                                      color: isChecked
                                          ? primaryColor
                                          : textColor,
                                      fontWeight: isChecked
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  activeColor: primaryColor,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // Categories
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 5,
                        children: [
                          Text(
                            S.of(context).categories,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: formFieldColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.builder(
                              itemCount: matajerEnglishCategories.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final categoryName =
                                    matajerEnglishCategories[index]['name']
                                        as String;
                                final isSelected =
                                    selectedMainCategory == categoryName;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    setState(() {
                                      selectedMainCategory = categoryName;
                                      selectedSubCategory = null;
                                    });
                                  },
                                  title: Text(
                                    categoryName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryColor
                                          : textColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Radio<String>(
                                    value: categoryName,
                                    groupValue: selectedMainCategory,
                                    activeColor: primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedMainCategory = value!;
                                        selectedSubCategory = null;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // spacing at the end
                      SizedBox(height: 130),
                    ],
                  ),
                ),

                // 🧾 Products Filter Page
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 7),
                  child: Column(
                    spacing: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sorting Options
                      Column(
                        spacing: 5,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).sort_by,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: formFieldColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.builder(
                              itemCount: productsSortOptions.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final option = productsSortOptions[index];
                                final isSelected = selectedOption == option;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    setState(() {
                                      selectedOption = option;
                                    });
                                  },
                                  title: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryColor
                                          : textColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Radio<String>(
                                    value: option,
                                    groupValue: selectedOption,
                                    activeColor: primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedOption = value!;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // Price Range
                      Column(
                        spacing: 5,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).price_range,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 13,
                            ),
                            decoration: BoxDecoration(
                              color: formFieldColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    currentRangeValues.start.round() < 1
                                        ? "AED Zero"
                                        : "AED ${currentRangeValues.start.round()}",
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: RangeSlider(
                                    values: currentRangeValues,
                                    min: 0,
                                    max: 1000000,
                                    divisions: 20,
                                    labels: RangeLabels(
                                      currentRangeValues.start
                                          .round()
                                          .toString(),
                                      currentRangeValues.end.round().toString(),
                                    ),
                                    onChanged: (RangeValues values) {
                                      setState(() {
                                        currentRangeValues = values;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "AED ${currentRangeValues.end.round()}",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Emirates
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                S.of(context).emirates,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),

                              // Checkbox to select all Emirates
                              Checkbox(
                                value: selectedCities.length == cities.length
                                    ? true
                                    : selectedCities.isEmpty
                                    ? false
                                    : null, // Partially selected
                                tristate: true,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedCities = Set<String>.from(cities);
                                    } else {
                                      selectedCities.clear();
                                    }
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: formFieldColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.builder(
                              itemCount: cities.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final city = cities[index];
                                final isChecked = selectedCities.contains(city);

                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: isChecked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      if (value == true) {
                                        selectedCities.add(city);
                                      } else {
                                        selectedCities.remove(city);
                                      }
                                    });
                                  },
                                  title: Text(
                                    city,
                                    style: TextStyle(
                                      color: isChecked
                                          ? primaryColor
                                          : textColor,
                                      fontWeight: isChecked
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  activeColor: primaryColor,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      // Shop Categories
                      Column(
                        spacing: 5,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.of(context).shop_categories,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: formFieldColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.builder(
                              itemCount: matajerEnglishCategories.length,
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final categoryName =
                                    matajerEnglishCategories[index]['name']
                                        as String;
                                final isSelected =
                                    selectedMainCategory == categoryName;

                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  onTap: () {
                                    setState(() {
                                      selectedMainCategory = categoryName;
                                      selectedSubCategory = null;
                                    });
                                  },
                                  title: Text(
                                    categoryName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? primaryColor
                                          : textColor,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  trailing: Radio<String>(
                                    value: categoryName,
                                    groupValue: selectedMainCategory,
                                    activeColor: primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedMainCategory = value!;
                                        selectedSubCategory = null;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      if (selectedMainCategory != null)
                        // Product Categories
                        Column(
                          spacing: 5,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).product_categories,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: formFieldColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Builder(
                                builder: (_) {
                                  final selectedCategoryMap =
                                      matajerEnglishCategories.firstWhere(
                                        (cat) =>
                                            cat['name'] == selectedMainCategory,
                                        orElse: () => {
                                          'name': '',
                                          'subCategories': [],
                                        },
                                      );

                                  final subCategories =
                                      selectedCategoryMap['subCategories']
                                          as List<dynamic>;

                                  if (subCategories.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                        S
                                            .of(context)
                                            .no_subcategories_available,
                                        style: TextStyle(
                                          color: textColor.withOpacity(0.6),
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: subCategories.length,
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final sub = subCategories[index];
                                      final isSelected =
                                          selectedSubCategory == sub;

                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        onTap: () {
                                          setState(() {
                                            selectedSubCategory = sub;
                                          });
                                        },
                                        title: Text(
                                          sub,
                                          style: TextStyle(
                                            color: isSelected
                                                ? primaryColor
                                                : textColor,
                                            fontWeight: isSelected
                                                ? FontWeight.w800
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        trailing: Radio<String>(
                                          value: sub,
                                          groupValue: selectedSubCategory,
                                          activeColor: primaryColor,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedSubCategory = value!;
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                      // spacing at the end
                      SizedBox(height: 130),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
          child: Material(
            borderRadius: BorderRadius.circular(17.r),
            color: primaryColor,
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: InkWell(
                borderRadius: BorderRadius.circular(17.r),
                onTap: () async {
                  final isShop = currentFilterPage == 0;

                  // ✅ Compose the full category if both selected
                  final fullCategory =
                      (selectedMainCategory != null &&
                          selectedSubCategory != null)
                      ? "${selectedMainCategory!} > ${selectedSubCategory!}"
                      : selectedMainCategory;

                  print("fullCategory: $fullCategory");

                  FilterCubit.get(context).updateFilter(
                    isShop: isShop,
                    category:
                        fullCategory, // ✅ Now passes the proper category string
                    sortBy: selectedOption,
                    emirates: selectedCities,
                    priceRange: isShop ? null : currentRangeValues,
                  );

                  if (!context.mounted) return;

                  if (isShop) {
                    final shops = await FilterCubit.get(
                      context,
                    ).fetchFilteredShops();
                    // TODO: navigate to shop filters result screen if needed
                    if (!context.mounted) return;

                    navigateTo(
                      context: context,
                      screen: FilterShopsListScreen(shops: shops),
                    );
                    return;
                  }

                  final products = await FilterCubit.get(
                    context,
                  ).fetchFilteredProducts();
                  ProductCubit.get(context).setFilteredProducts(products);

                  final product = await FilterCubit.get(
                    context,
                  ).fetchFilteredProducts();
                  print("🔍 Filtered Products Count: ${product.length}");
                  for (var p in product) {
                    print(
                      "📦 Product: ${p.title}, ${p.sellerCategory} > ${p.productCategory}",
                    );
                  }

                  if (!context.mounted) return;

                  navigateTo(
                    context: context,
                    screen: FilterProductsListScreen(products: products),
                  );
                },
                child: Center(
                  child: Text(
                    S.of(context).submit,
                    style: TextStyle(
                      height: 0.8,
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
