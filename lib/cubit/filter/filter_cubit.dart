import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/cubit/filter/filter_state.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';

class FilterCriteria {
  String? category;
  String? sortBy;
  Set<String> emirates = {};
  RangeValues? priceRange;

  FilterCriteria({
    this.category,
    this.sortBy,
    Set<String>? emirates,
    this.priceRange,
  }) {
    this.emirates = emirates ?? {};
  }
}

class FilterCubit extends Cubit<FiltersState> {
  FilterCubit() : super(FiltersInitialState());

  static FilterCubit get(BuildContext context) => BlocProvider.of(context);

  FilterCriteria shopFilters = FilterCriteria();
  FilterCriteria productFilters = FilterCriteria();

  void updateFilter({
    required bool isShop,
    String? sortBy,
    String? category,
    Set<String>? emirates,
    RangeValues? priceRange,
  }) {
    final filter = isShop ? shopFilters : productFilters;
    if (sortBy != null) filter.sortBy = sortBy;
    if (category != null) filter.category = category;
    if (emirates != null) filter.emirates = emirates;
    if (priceRange != null) filter.priceRange = priceRange;

    emit(FiltersUpdatedState());
  }

  void clearFilters({required bool isShop}) {
    if (isShop) {
      shopFilters = FilterCriteria();
    } else {
      productFilters = FilterCriteria();
    }
    emit(FiltersClearedState());
  }

  Future<List<ShopModel>> fetchFilteredShops() async {
    final filters = shopFilters;
    Query shopQuery = FirebaseFirestore.instance.collection('shops');

    if (filters.category?.trim().isNotEmpty ?? false) {
      shopQuery = shopQuery.where('shopCategory', isEqualTo: filters.category);
    }

    if (filters.emirates.isNotEmpty) {
      shopQuery = shopQuery.where(
        'emirate',
        whereIn: filters.emirates.toList(),
      );
    }

    switch (filters.sortBy) {
      case 'A -> Z':
        shopQuery = shopQuery.orderBy('shopName');
        break;
      case 'Top Rated':
        shopQuery = shopQuery.orderBy('sumOfRating', descending: true);
        break;
      case 'Newest':
        shopQuery = shopQuery.orderBy('sellerCreatedAt', descending: true);
        break;
      case 'Oldest':
        shopQuery = shopQuery.orderBy('sellerCreatedAt', descending: false);
        break;
      default:
        break;
    }

    final snapshot = await shopQuery.get();
    print("🏪 Filtered shops: ${snapshot.docs.length}");

    return snapshot.docs
        .map((doc) => ShopModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> fetchFilteredProducts() async {
    final filters = productFilters;
    Query productQuery = FirebaseFirestore.instance.collection('products');

    if (filters.category?.trim().isNotEmpty ?? false) {
      if (filters.category!.contains(' > ')) {
        productQuery = productQuery.where(
          'fullCategory',
          isEqualTo: filters.category,
        );
      } else {
        productQuery = productQuery.where(
          'sellerCategory',
          isEqualTo: filters.category,
        );
      }
    }

    if (filters.priceRange != null) {
      productQuery = productQuery
          .where('price', isGreaterThanOrEqualTo: filters.priceRange!.start)
          .where('price', isLessThanOrEqualTo: filters.priceRange!.end);
    }

    if (filters.emirates.isNotEmpty) {
      final shopSnapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('emirate', whereIn: filters.emirates.toList())
          .get();

      final matchingShopIds = shopSnapshot.docs
          .map((doc) => doc['shopId'] as String)
          .toList();

      if (matchingShopIds.isEmpty) {
        print('⚠️ No shops match the selected emirates');
        return [];
      }

      productQuery = productQuery.where('shopId', whereIn: matchingShopIds);
    }

    // Apply sorting based on filters
    try {
      switch (filters.sortBy) {
        case 'A -> Z':
          productQuery = productQuery.orderBy('title');
          break;
        case 'Top Rated':
          productQuery = productQuery.orderBy('sumOfRating', descending: true);
          break;
        case 'Price: Low -> High':
          productQuery = productQuery.orderBy('price');
          break;
        case 'Price: High -> Low':
          productQuery = productQuery.orderBy('price', descending: true);
          break;
        case 'Newest':
          productQuery = productQuery.orderBy('createdAt', descending: true);
          break;
        case 'Oldest':
          productQuery = productQuery.orderBy('createdAt', descending: false);
          break;
        case 'Most Viewed':
          productQuery = productQuery.orderBy('clicks', descending: true);
          break;
        default:
          break;
      }
    } catch (e) {
      print('⚠️ Error applying sort: $e');
    }

    final snapshot = await productQuery.get();
    print("🔍 Filtered products: ${snapshot.docs.length}");

    final products = snapshot.docs
        .map((doc) => ProductModel.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    print("🔍 Filtered Products Count: ${products.length}");
    for (final product in products) {
      print(
        "📦 Product: ${product.title}, ${product.fullCategory ?? 'No fullCategory'}",
      );
    }

    return products;
  }
}
