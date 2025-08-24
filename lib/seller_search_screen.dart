import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/screens/home/categories/shop_products_card.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:matajer/screens/search/search.dart';

class ShopSearchScreen extends StatefulWidget {
  const ShopSearchScreen({super.key, required this.shop});
  final ShopModel shop;

  @override
  State<ShopSearchScreen> createState() => _ShopSearchScreenState();
}

class _ShopSearchScreenState extends State<ShopSearchScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  List<String> productSearchHistory = [];
  bool showFullHistory = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    ProductCubit.get(context).getProductsByShopId(shopId: widget.shop.shopId);
  }

  @override
  bool get wantKeepAlive => true;

  void _onSearchChanged(String value) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        searchController;
      });
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.isNotEmpty) {
        ProductCubit.get(
          context,
        ).searchProductsByShopId(value, shopId: widget.shop.shopId);
      }
    });
  }

  void _handleSearch(String value) {
    if (value.isNotEmpty) {
      ProductCubit.get(
        context,
      ).searchProductsByShopId(value, shopId: widget.shop.shopId);
      if (!productSearchHistory.contains(value)) {
        productSearchHistory.insert(0, value);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        automaticallyImplyLeading: false,
        toolbarHeight: 105,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Row(
                  children: [
                    Material(
                      color: lightGreyColor.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(7),
                          child: Icon(backIcon(), size: 26),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${widget.shop.shopName} ${S.of(context).products}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Stack(
                  children: [
                    TextField(
                      controller: searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: S.of(context).search_placeholder,
                        contentPadding: const EdgeInsets.all(15),
                        filled: true,
                        fillColor: greyColor.withOpacity(0.1),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close),
                          color: greyColor,
                          onPressed: () =>
                              setState(() => searchController.clear()),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _handleSearch,
                      onChanged: _onSearchChanged,
                    ),
                    if (searchController.text.startsWith('#') ||
                        searchController.text.startsWith('\$'))
                      buildSearchTagOverlay(
                        searchController.text,
                        context,
                        _searchFocusNode,
                        padding: 10,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<ProductCubit, ProductState>(
        builder: (context, state) {
          final cubit = ProductCubit.get(context);
          final allItems = cubit.allProducts;
          final searchResults = cubit.productsSearchResults;
          final dataList = searchController.text.isEmpty
              ? allItems
              : searchResults;

          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                buildSearchHistory(
                  history: productSearchHistory,
                  onClear: () => setState(() => productSearchHistory.clear()),
                  onTap: (value) {
                    searchController.text = value;
                    ProductCubit.get(
                      context,
                    ).searchProductsByShopId(value, shopId: widget.shop.shopId);
                    setState(() {});
                  },
                ),
                if (dataList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        S.of(context).no_products_found,
                        style: TextStyle(fontSize: 16, color: greyColor),
                      ),
                    ),
                  ),
                ...dataList.map(
                  (product) => ShopProductsCard(
                    productModel: product,
                    isSelected: false,
                    onTap: () {
                      navigateTo(
                        context: context,
                        screen: ProductDetailsScreen(
                          productModel: product,
                          shopModel: widget.shop,
                        ),
                      );
                    },
                    deleteButton: null,
                    onLongPress: null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildSearchHistory({
    required List<String> history,
    required VoidCallback onClear,
    required ValueChanged<String> onTap,
  }) {
    final displayHistory = showFullHistory ? history : history.take(8).toList();
    if (history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).search_history,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    S.of(context).clear,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            children: displayHistory
                .map(
                  (item) => GestureDetector(
                    onTap: () => onTap(item),
                    child: Chip(
                      label: Text(item, style: TextStyle(color: textColor)),
                      backgroundColor: formFieldColor,
                      side: BorderSide.none,
                    ),
                  ),
                )
                .toList(),
          ),
          if (history.length > 8 && !showFullHistory)
            Center(
              child: TextButton(
                onPressed: () => setState(() => showFullHistory = true),
                child: Text(S.of(context).view_more),
              ),
            ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
