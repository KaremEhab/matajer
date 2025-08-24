import 'package:conditional_builder_null_safety/conditional_builder_null_safety.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/screens/filters/filters.dart';
import 'package:matajer/screens/search/widgets/search_product_card.dart';
import 'package:matajer/screens/search/widgets/search_product_shimmer.dart';
import 'package:matajer/screens/search/widgets/search_shop_shimmer.dart';
import 'package:matajer/screens/search/widgets/serach_shop_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  int currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<String> shopSearchHistory = [];
  List<String> productSearchHistory = [];
  bool showFullHistory = false;
  bool isPaginating = false;

  @override
  void initState() {
    super.initState();
    final cubit = ProductCubit.get(context);
    cubit.getAllShops(isFirstLoad: true, pageSize: 8);
    cubit.getAllProducts(isFirstLoad: true);

    _scrollController.addListener(_onScroll);
    loadSearchHistory();
    _loadSearchHistories();
  }

  Future<void> saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(shopSearchHistoryKey, shopSearchHistory);
    await prefs.setStringList(productSearchHistoryKey, productSearchHistory);
  }

  Future<void> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    shopSearchHistory = prefs.getStringList(shopSearchHistoryKey) ?? [];
    productSearchHistory = prefs.getStringList(productSearchHistoryKey) ?? [];
    setState(() {}); // Refresh UI
  }

  Future<void> _loadSearchHistories() async {
    final prefs = await SharedPreferences.getInstance();
    shopSearchHistory = prefs.getStringList('shopSearchHistory') ?? [];
    productSearchHistory = prefs.getStringList('productSearchHistory') ?? [];
    setState(() {});
  }

  void _onTabSelected(int index) => setState(() => currentIndex = index);

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !isPaginating) {
      isPaginating = true;
      final cubit = ProductCubit.get(context);
      if (_searchController.text.isEmpty) {
        if (currentIndex == 0) {
          cubit.getAllShops().whenComplete(() {
            setState(() => isPaginating = false);
          });
        } else {
          cubit.getAllProducts().whenComplete(() {
            setState(() => isPaginating = false);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isShopTab = currentIndex == 0;
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Column(
                children: [
                  _buildSearchHistory(),
                  BlocConsumer<ProductCubit, ProductState>(
                    listener: (_, __) {},
                    builder: (context, state) {
                      final cubit = ProductCubit.get(context);
                      final dataList = _searchController.text.isEmpty
                          ? (isShopTab ? cubit.allShops : cubit.allProducts)
                          : (isShopTab
                                ? cubit.sellersSearchResults
                                : cubit.productsSearchResults);
                      final isLoading =
                          state is ProductGetAllSellersLoadingState ||
                          state is ProductGetAllProductsLoadingState;

                      return ConditionalBuilder(
                        condition: !isLoading,
                        builder: (_) => _buildDataList(dataList),
                        fallback: (_) => _buildShimmerList(),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: 140,
      backgroundColor: Colors.white,
      flexibleSpace: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        color: scaffoldColor,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              spacing: 5,
              children: [
                Expanded(
                  child: buildTabButton(
                    label: S.of(context).matajer,
                    icon: "images/shop-icon-outlined.svg",
                    isActive: currentIndex == 0,
                    onTap: () => _onTabSelected(0),
                  ),
                ),
                Expanded(
                  child: buildTabButton(
                    label: S.of(context).products,
                    icon: IconlyLight.bag,
                    isActive: currentIndex == 1,
                    onTap: () => _onTabSelected(1),
                    isSvg: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSearchField(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final hintText = currentIndex == 0
        ? S.of(context).searching_for
        : S.of(context).search_placeholder;

    return Stack(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: hintText,
            contentPadding: const EdgeInsets.all(15),
            border: OutlineInputBorder(borderSide: BorderSide.none),
            filled: true,
            fillColor: greyColor.withOpacity(0.1),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: greyColor),
              onPressed: () => setState(() => _searchController.clear()),
            ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => _submitSearch(value),
          onChanged: (value) => _onSearchChanged(value),
        ),
        if (_searchController.text.startsWith('#') ||
            _searchController.text.startsWith('\$'))
          buildSearchTagOverlay(
            _searchController.text,
            context,
            _searchFocusNode,
          ),
      ],
    );
  }

  void _submitSearch(String value) async {
    if (value.isEmpty) return;

    final cubit = ProductCubit.get(context);
    final prefs = await SharedPreferences.getInstance();

    if (currentIndex == 0) {
      cubit.searchSellers(value);
      if (!shopSearchHistory.contains(value)) {
        shopSearchHistory.insert(0, value);
        prefs.setStringList('shopSearchHistory', shopSearchHistory);
      }
    } else {
      cubit.searchProducts(value);
      if (!productSearchHistory.contains(value)) {
        productSearchHistory.insert(0, value);
        prefs.setStringList('productSearchHistory', productSearchHistory);
      }
    }

    setState(() {});
  }

  void _onSearchChanged(String value) {
    final cubit = ProductCubit.get(context);
    if (value.isNotEmpty) {
      if (currentIndex == 0) {
        cubit.searchSellers(value);
      } else {
        cubit.searchProducts(value);
      }
    }
    setState(() {}); // 🔥 Always refresh UI so overlay shows instantly
  }

  Widget _buildSearchHistory() {
    final history = currentIndex == 0
        ? shopSearchHistory
        : productSearchHistory;
    final displayHistory = showFullHistory ? history : history.take(8).toList();
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
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
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  if (currentIndex == 0) {
                    shopSearchHistory.clear();
                    prefs.remove('shopSearchHistory');
                  } else {
                    productSearchHistory.clear();
                    prefs.remove('productSearchHistory');
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                child: Text(
                  S.of(context).clear,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
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
                  onTap: () {
                    _searchController.text = item;
                    _submitSearch(item);
                  },
                  child: Chip(
                    label: Text(
                      item,
                      style: const TextStyle(color: primaryDarkColor),
                    ),
                    backgroundColor: secondaryColor,
                  ),
                ),
              )
              .toList(),
        ),
        if (history.length > 8)
          Center(
            child: TextButton(
              onPressed: () =>
                  setState(() => showFullHistory = !showFullHistory),
              child: Text(
                !showFullHistory
                    ? S.of(context).view_more
                    : S.of(context).see_less,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDataList(List<dynamic> dataList) {
    final isShopTab = currentIndex == 0;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dataList.length + (isPaginating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == dataList.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: isShopTab
              ? SearchShopCard(shop: dataList[index])
              : SearchProductCard(product: dataList[index]),
        );
      },
    );
  }

  Widget _buildShimmerList() {
    final isShopTab = currentIndex == 0;
    return ListView.separated(
      padding: const EdgeInsets.only(top: 10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => isShopTab
          ? const SearchShopCardShimmer()
          : const SearchProductCardShimmer(),
    );
  }
}

Widget buildSearchTagOverlay(
  String value,
  BuildContext context,
  FocusNode focusNode, {
  double verticalMargin = 5,
  double padding = 12,
}) {
  return GestureDetector(
    onTap: () {
      FocusScope.of(context).requestFocus(focusNode);
    },
    child: Container(
      constraints: BoxConstraints(maxWidth: 0.81.sw),
      margin: EdgeInsets.symmetric(vertical: verticalMargin, horizontal: 5),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue),
      ),
      child: Text(
        value.startsWith('\$')
            ? '${S.of(context).price}: ${value.substring(1)}'
            : '${S.of(context).product_id}: ${value.substring(1)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ),
  );
}
