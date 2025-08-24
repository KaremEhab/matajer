// favorites_cubit.dart

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/models/favorites_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/models/product_model.dart';
import '../../constants/vars.dart';
import 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesStates> {
  FavoritesCubit() : super(FavoritesInitialState());
  static FavoritesCubit get(context) => BlocProvider.of(context);

  FavouritesModel? favouritesModel;
  List<ShopModel> favShopsList = [];
  List<ProductModel> favProductsList = [];

  Future<void> getFavorites({required String userId}) async {
    emit(FavoritesLoadingState());

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('favorites')
          .get();

      if (doc.exists) {
        favouritesModel = FavouritesModel.fromJson(doc.data()!);
      } else {
        favouritesModel = FavouritesModel(favShops: [], favProducts: []);
      }

      await getFavoriteShops();
      await getFavoriteProducts();

      emit(FavoritesSuccessState());
    } catch (e) {
      log('Error fetching favorites: $e');
      emit(FavoritesErrorState(e.toString()));
    }
  }

  Future<void> getFavoriteShops() async {
    favShopsList = [];

    final ids = favouritesModel?.favShops ?? [];

    if (ids.isEmpty) {
      log('💡 No favorite shops to fetch.');
      return;
    }

    try {
      log('🔍 Fetching shops with document IDs: $ids');

      final result = await FirebaseFirestore.instance
          .collection('shops')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      favShopsList = result.docs
          .map((e) => ShopModel.fromJson(e.data()))
          .toList();

      log('✅ Fetched ${favShopsList.length} favorite shops.');
    } catch (e) {
      log('❌ Error fetching favorite shops: $e');
    }
  }

  Future<void> getFavoriteProducts() async {
    favProductsList = [];

    final ids = favouritesModel?.favProducts ?? [];

    if (ids.isEmpty) {
      log('💡 No favorite products to fetch.');
      return;
    }

    try {
      log('🔍 Fetching products with document IDs: $ids');

      final result = await FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      favProductsList = result.docs
          .map((e) => ProductModel.fromJson(e.data()))
          .toList();

      log('✅ Fetched ${favProductsList.length} favorite products.');
    } catch (e) {
      log('❌ Error fetching favorite products: $e');
    }
  }

  Future<void> toggleFavoriteShop({
    required String userId,
    required String shopId,
  }) async {
    try {
      final isFav = favouritesModel?.favShops.contains(shopId) ?? false;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('favorites');

      final shopRef = FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId);

      // Update user favorites
      await userRef.set({
        'favShops': isFav
            ? FieldValue.arrayRemove([shopId])
            : FieldValue.arrayUnion([shopId]),
      }, SetOptions(merge: true));

      // Update shop favorites
      await shopRef.set({
        'usersSetAsFavorite': isFav
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true));

      await getFavorites(userId: userId);
    } catch (e) {
      log('❌ Error toggling favorite shop: $e');
    }
  }

  Future<void> toggleFavoriteProduct({
    required String userId,
    required String productId,
  }) async {
    try {
      final isFav = favouritesModel?.favProducts.contains(productId) ?? false;
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('favorites');

      await ref.set({
        'favProducts': isFav
            ? FieldValue.arrayRemove([productId])
            : FieldValue.arrayUnion([productId]),
      }, SetOptions(merge: true));

      await getFavorites(userId: userId);
    } catch (e) {
      log('Error toggling favorite product: $e');
    }
  }

  Future<void> addShopToFavorites({required String shopDocId}) async {
    emit(FavoritesUpdatingState());

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserModel.uId)
        .collection('data')
        .doc('favorites');

    final shopDocRef = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopDocId);

    await userDocRef.set({
      'favShops': FieldValue.arrayUnion([shopDocId]),
    }, SetOptions(merge: true));

    await shopDocRef.set({
      'usersSetAsFavorite': FieldValue.arrayUnion([currentUserModel.uId]),
    }, SetOptions(merge: true));

    favouritesModel?.favShops.add(shopDocId);
    emit(FavoritesUpdatedState());
  }

  Future<void> removeShopFromFavorites({required String shopDocId}) async {
    emit(FavoritesUpdatingState());

    final userDocRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserModel.uId)
        .collection('data')
        .doc('favorites');

    final shopDocRef = FirebaseFirestore.instance
        .collection('shops')
        .doc(shopDocId);

    await userDocRef.set({
      'favShops': FieldValue.arrayRemove([shopDocId]),
    }, SetOptions(merge: true));

    await shopDocRef.set({
      'usersSetAsFavorite': FieldValue.arrayRemove([uId]),
    }, SetOptions(merge: true));

    favouritesModel?.favShops.remove(shopDocId);
    emit(FavoritesUpdatedState());
  }
}
