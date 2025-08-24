import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/cubit/order/order_cubit.dart';
import 'package:matajer/cubit/product/product_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/cart_product_item_model.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

List<Map<String, dynamic>> filterShopsInIsolate(Map<String, dynamic> args) {
  final List<Map<String, dynamic>> shops = List<Map<String, dynamic>>.from(
    args['shops'],
  );
  final String shopType = args['shopType'] ?? '';

  final lowerShopType = shopType.toLowerCase();

  return shops.where((shop) {
    final category = (shop['shopCategory'] ?? '').toString().toLowerCase();
    final subcategories = List<String>.from(shop['subcategories'] ?? []);

    return category == lowerShopType ||
        subcategories.map((e) => e.toLowerCase()).contains(lowerShopType);
  }).toList();
}

List<ProductModel> parseProductsFromDocs(List<Map<String, dynamic>> rawList) {
  return rawList.map((e) => ProductModel.fromJson(e)).toList();
}

// Parse Firestore doc in background isolate
OrderModel parseOrder(Map<String, dynamic> data) {
  return OrderModel.fromJson(data, data['id']);
}

// Build the order object in isolate
OrderModel buildOrder(Map<String, dynamic> args) {
  return OrderModel(
    id: args['id'],
    buyerId: args['buyerId'],
    buyerName: args['buyerName'],
    buyerPhone: args['buyerPhone'],
    buyerAddress: args['buyerAddress'],
    sellerId: args['sellerId'],
    shopId: args['shopId'],
    sellerName: args['sellerName'],
    sellerPhone: args['sellerPhone'],
    orderStatus: args['orderStatus'],
    deliveryTime: args['deliveryTime'],
    price: args['price'],
    products: args['products'],
    createdAt: args['createdAt'],
  );
}

class ProductCubit extends Cubit<ProductState> {
  ProductCubit() : super(ProductInitialState());

  static ProductCubit get(context) => BlocProvider.of(context);

  List<ShopModel> shops = [];

  // NEW STATE VARIABLES for pagination
  bool isLoadingMore = false;
  bool reachedEnd = false;
  DocumentSnapshot? lastShopDocument;
  final int limit = 3;

  /// Initial fetch of sellers with optional shopType
  Future<void> getSellers({required String shopType}) async {
    emit(ProductGetSellersLoadingState());

    try {
      // Reset state
      shops.clear();
      reachedEnd = false;
      isLoadingMore = false;
      lastShopDocument = null;

      Query query = FirebaseFirestore.instance
          .collection('shops')
          .orderBy('sellerCreatedAt', descending: true)
          .limit(limit);

      final result = await query.get();
      lastShopDocument = result.docs.isNotEmpty ? result.docs.last : null;

      final fetchedShops = result.docs
          .map((e) => ShopModel.fromJson(e.data() as Map<String, dynamic>))
          .toList();

      List<ShopModel> filteredShops;

      if (shopType.trim().isEmpty) {
        filteredShops = fetchedShops;
      } else {
        final shopJsonList = fetchedShops.map((e) => e.toMap()).toList();
        final filteredJsonList = await compute(
          filterShopsInIsolate,
          <String, dynamic>{'shops': shopJsonList, 'shopType': shopType},
        );
        filteredShops = filteredJsonList
            .map((e) => ShopModel.fromJson(e))
            .toList();
      }

      shops = filteredShops;

      // ✅ Stop pagination if there are no shops at all
      if (shops.isEmpty || fetchedShops.length < limit) {
        reachedEnd = true;
      }

      log('Fetched ${shops.length} initial shops (paginated)');

      emit(ProductGetSellersSuccessState());
    } catch (e) {
      log('Error fetching sellers: $e');
      emit(ProductGetSellersErrorState(e.toString()));
    }
  }

  /// Pagination method: Fetch more sellers
  Future<void> getMoreSellers({
    required String shopType,
    required BuildContext context,
  }) async {
    if (isLoadingMore || reachedEnd || lastShopDocument == null) return;

    isLoadingMore = true;
    emit(ProductGetMoreSellersLoadingState());

    try {
      Query query = FirebaseFirestore.instance
          .collection('shops')
          .orderBy('sellerCreatedAt', descending: true)
          .startAfterDocument(lastShopDocument!)
          .limit(limit);

      final result = await query.get();

      final fetchedShops = result.docs
          .map((e) => ShopModel.fromJson(e.data() as Map<String, dynamic>))
          .toList();

      lastShopDocument = result.docs.isNotEmpty ? result.docs.last : null;

      List<ShopModel> newShops;

      if (shopType.trim().isEmpty) {
        newShops = fetchedShops;
      } else {
        final shopJsonList = fetchedShops.map((e) => e.toMap()).toList();

        final filteredJsonList = await compute(
          filterShopsInIsolate,
          <String, dynamic>{'shops': shopJsonList, 'shopType': shopType},
        );

        newShops = filteredJsonList
            .map((e) => ShopModel.fromJson(e))
            .toList();
      }

      shops.addAll(newShops);

      if (fetchedShops.length < limit) {
        reachedEnd = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).no_more_shops),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      emit(ProductGetMoreSellersSuccessState());
    } catch (e) {
      log('Error fetching more sellers: $e');
      emit(ProductGetMoreSellersErrorState(e.toString()));
    } finally {
      isLoadingMore = false;
    }
  }

  Future<void> getSellersByCategory({
    required String shopType,
    int limit = 10,
  }) async {
    emit(ProductGetSellersLoadingState());

    try {
      // Reset state
      shops.clear();
      reachedEnd = false;
      isLoadingMore = false;
      lastShopDocument = null;
      // currentShopType = shopType;

      Query query = FirebaseFirestore.instance
          .collection('shops')
          .where('shopCategory', isEqualTo: shopType)
          .orderBy('sellerCreatedAt', descending: true)
          .limit(limit);

      final result = await query.get();
      lastShopDocument = result.docs.isNotEmpty ? result.docs.last : null;

      shops = result.docs
          .map((e) => ShopModel.fromJson(e.data() as Map<String, dynamic>))
          .toList();

      if (result.docs.length < limit) reachedEnd = true;

      emit(ProductGetSellersSuccessState());
    } catch (e) {
      emit(ProductGetSellersErrorState(e.toString()));
    }
  }

  /// Pagination method: Fetch more sellers by category
  Future<void> getMoreSellersByCategory({
    required String shopType,
    int limit = 10,
    required BuildContext context,
  }) async {
    if (isLoadingMore || reachedEnd || lastShopDocument == null) return;
    // if (currentShopType != shopType) return;

    isLoadingMore = true;
    emit(ProductGetMoreSellersLoadingState());

    try {
      Query query = FirebaseFirestore.instance
          .collection('shops')
          .where('shopCategory', isEqualTo: shopType)
          .orderBy('sellerCreatedAt', descending: true)
          .startAfterDocument(lastShopDocument!)
          .limit(limit);

      final result = await query.get();

      lastShopDocument = result.docs.isNotEmpty ? result.docs.last : null;

      final newShops = result.docs
          .map((e) => ShopModel.fromJson(e.data() as Map<String, dynamic>))
          .toList();

      shops.addAll(newShops);

      if (newShops.length < limit) {
        reachedEnd = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).no_more_shops),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      emit(ProductGetMoreSellersSuccessState());
    } catch (e) {
      emit(ProductGetMoreSellersErrorState(e.toString()));
    } finally {
      isLoadingMore = false;
    }
  }

  String? uploadedProductImage;
  Future<String> uploadImage({
    required XFile image,
    required String docId,
    required String imageName,
  }) async {
    try {
      String downloadURL = '';
      emit(ProductUploadImageLoadingState());
      FirebaseStorage storageRef = FirebaseStorage.instance;
      String imagePath =
          'products/$docId/$imageName.${image.path.split('.').last}';
      Reference reference = storageRef.ref().child(imagePath);
      UploadTask uploadTask = reference.putFile(File(image.path));
      // Wait for the upload task to complete
      TaskSnapshot taskSnapshot = await uploadTask;
      // Get the download URL for the current image
      downloadURL = await taskSnapshot.ref.getDownloadURL();
      emit(ProductUploadImageSuccessState());
      return downloadURL;
    } catch (error) {
      log('Error uploading images: $error');
      emit(ProductUploadImageErrorState(error.toString()));
      return '';
    }
  }

  Future<XFile> compressImage(XFile file) async {
    final dir = await getTemporaryDirectory();
    final targetPath = join(
      dir.path,
      '${DateTime.now().millisecondsSinceEpoch}.jpg', // <-- ends with .jpg
    );

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 60,
      format: CompressFormat.jpeg, // <-- optional but good practice
    );

    return XFile(result!.path); // return a valid XFile
  }

  Future<void> addProduct({
    required BuildContext context,
    required String title,
    required String description,
    required List<XFile> images,
    required num price,
    int discount = 0,
    required num quantity,
    required List<ProductSpecificationModel> specifications,
    required String productCategory,
    required ShopModel shopModel,
  }) async {
    emit(ProductAddProductLoadingState());

    List<String> uploadedImages = [];
    final productRef = FirebaseFirestore.instance.collection('products').doc();
    late ProductModel productModel;

    final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

    late OverlayEntry? loaderEntry; // nullable

    void showUploadOverlay() {
      final overlay = Overlay.of(context); // No overlay available

      loaderEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(10),
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, value, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${S.of(context).uploading} ${(value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      S.of(context).keep_screen_open,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      overlay.insert(loaderEntry!);
    }

    void hideUploadOverlay() {
      if (loaderEntry != null) {
        try {
          loaderEntry!.remove();
        } catch (_) {
          // already removed or overlay gone
        }
        loaderEntry = null;
      }
    }

    // Generate search keywords from title
    List<String> searchKeywords = title
        .toLowerCase()
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList();

    try {
      await productRef.set({
        'isFinished': false,
        'title': title,
        'description': description,
        'price': price,
        'discount': discount,
        'images': [],
        'sellerId': shopModel.sellerId,
        'shopId': shopModel.shopId,
        'quantity': quantity,
        'specifications': specifications.map((e) => e.toMap()).toList(),
        'sellerName': shopModel.shopName,
        'sellerPhone': currentUserModel.phoneNumber,
        'sellerLogo': shopModel.shopLogoUrl,
        'sumOfRating': 0,
        'numberOfRating': 0,
        'clicks': 0,
        'productCategory': productCategory,
        'sellerCategory': shopModel.shopCategory,
        'fullCategory': "${shopModel.shopCategory} > $productCategory",
        'createdAt': FieldValue.serverTimestamp(),
        'searchKeywords': searchKeywords, // 👈 ADDED
      });

      int total = images.length;

      showUploadOverlay(); // 👈 Start overlay progress UI

      for (int i = 0; i < total; i++) {
        progressNotifier.value = (i / total);

        final compressed = await compressImage(images[i]);
        final imageUrl = await uploadImage(
          image: compressed,
          docId: productRef.id,
          imageName: 'product_image_$i',
        );
        uploadedImages.add(imageUrl);
      }

      progressNotifier.value = 1.0;

      await productRef.update({
        'id': productRef.id,
        'images': uploadedImages,
        'isFinished': true,
      });

      productModel = ProductModel(
        id: productRef.id,
        title: title,
        description: description,
        price: price,
        discount: discount,
        images: uploadedImages,
        sellerId: shopModel.sellerId,
        shopId: shopModel.shopId,
        specifications: specifications,
        quantity: quantity,
        shopName: shopModel.shopName,
        sellerPhone: currentUserModel.phoneNumber,
        shopLogo: shopModel.shopLogoUrl,
        sumOfRating: 0,
        numberOfRating: 0,
        clicks: 0,
        productCategory: productCategory,
        sellerCategory: shopModel.shopCategory,
        fullCategory: "${shopModel.shopCategory} > $productCategory",
        createdAt: DateTime.now(),
        searchKeywords: searchKeywords, // 👈 ADDED
      );

      // Update shop subcategories if needed
      final shopRef = FirebaseFirestore.instance
          .collection('shops')
          .doc(shopModel.shopId);
      final shopSnapshot = await shopRef.get();

      if (shopSnapshot.exists) {
        final List<dynamic> existingSubcategories =
            shopSnapshot.data()?['subcategories'] ?? [];
        if (!existingSubcategories.contains(productCategory)) {
          existingSubcategories.add(productCategory);
          await shopRef.update({'subcategories': existingSubcategories});
        }
      }

      hideUploadOverlay();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).product_added_successfully),
          backgroundColor: Colors.green,
        ),
      );

      emit(ProductAddProductSuccessState());
    } catch (e) {
      hideUploadOverlay();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${S.of(context).something_went_wrong}'),
          backgroundColor: Colors.red,
        ),
      );
      emit(ProductAddProductErrorState(e.toString()));
    }

    // === NOTIFICATION SENDING ===
    try {
      if (shopModel.usersSetAsFavorite.isNotEmpty) {
        for (final userId in shopModel.usersSetAsFavorite) {
          if (userId == currentUserModel.uId) continue;

          await NotificationCubit.instance.sendNotification(
            title: shopModel.shopName,
            body: "${S.of(context).new_product_added}: $title",
            userId: userId,
            imageUrl: uploadedImages.isNotEmpty ? uploadedImages.first : null,
            notificationType: NotificationTypes.newProduct,
            payload: jsonEncode({
              'type': NotificationTypes.newProduct.name,
              'productId': productRef.id,
              'productModel': productModel.toMap(),
              'shopModel': shopModel.toMap(),
              'specifications': specifications.map((e) => e.toMap()).toList(),
            }),
          );

          await NotificationCubit.instance.createNotification(
            receiverId: userId,
            receiverType: 'user',
            title: shopModel.shopName,
            body:
                "${shopModel.shopName} added a new product place your order now",
            type: NotificationTypes.newProduct,
            payload: {
              'productId': productRef.id,
              'productModel': productModel.toMap(),
              'shopModel': shopModel.toMap(),
              'specifications': specifications.map((e) => e.toMap()).toList(),
            },
          );
        }
      }
    } catch (e) {
      log("⚠️ Notification sending failed: $e");
    }
  }

  Future<void> editProduct({
    required BuildContext context,
    required ProductModel productModel,
    required String newTitle,
    required String newDescription,
    required num newPrice,
    required int newDiscount,
    required num newQuantity,
    required List<ProductSpecificationModel> newSpecifications,
    required String newProductCategory,
    required List<String> remainingNetworkImages,
    required List<XFile> newFileImages,
  }) async {
    emit(ProductAddProductLoadingState());

    final overlay = Overlay.of(context);
    late OverlayEntry loaderEntry;
    final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

    void showUploadOverlay() {
      loaderEntry = OverlayEntry(
        builder: (context) => Positioned(
          top: 50,
          left: 20,
          right: 20,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(10),
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: ValueListenableBuilder<double>(
                valueListenable: progressNotifier,
                builder: (context, value, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey[300],
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${S.of(context).uploading} ${(value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      S.of(context).keep_screen_open,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      overlay.insert(loaderEntry);
    }

    void hideUploadOverlay() {
      loaderEntry.remove();
    }

    try {
      final productRef = FirebaseFirestore.instance
          .collection('products')
          .doc(productModel.id);

      List<String> finalImages = [...remainingNetworkImages];
      int total = newFileImages.length;

      if (total > 0) showUploadOverlay();

      for (int i = 0; i < total; i++) {
        progressNotifier.value = (i / total);

        final compressed = await compressImage(newFileImages[i]);
        final imageUrl = await uploadImage(
          image: compressed,
          docId: productModel.id,
          imageName: 'edited_image_$i',
        );
        finalImages.add(imageUrl);
      }

      progressNotifier.value = 1.0;

      // Update Firestore doc
      await productRef.update({
        'title': newTitle,
        'description': newDescription,
        'price': newPrice,
        'discount': newDiscount,
        'images': finalImages,
        'quantity': newQuantity,
        'specifications': newSpecifications.map((e) => e.toMap()).toList(),
        'productCategory': newProductCategory,
        'fullCategory': "${productModel.sellerCategory} > $newProductCategory",
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Optionally update shop subcategories
      final shopRef = FirebaseFirestore.instance
          .collection('shops')
          .doc(productModel.shopId);
      final shopSnapshot = await shopRef.get();

      if (shopSnapshot.exists) {
        final List<dynamic> existingSubcategories =
            shopSnapshot.data()?['subcategories'] ?? [];
        if (!existingSubcategories.contains(newProductCategory)) {
          existingSubcategories.add(newProductCategory);
          await shopRef.update({'subcategories': existingSubcategories});
        }
      }

      if (total > 0) hideUploadOverlay();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Product updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      emit(ProductAddProductSuccessState());
    } catch (e) {
      hideUploadOverlay();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).something_went_wrong),
          backgroundColor: Colors.red,
        ),
      );
      emit(ProductAddProductErrorState(e.toString()));
    }
  }

  List<ProductModel> products = [];
  bool isLoadingMoreProducts = false;
  bool reachedEndProduct = false;
  String? currentCategory; // track active category
  DocumentSnapshot? lastProductDocument;
  static const kDefaultProductLimit = 10;
  late int productLimit = kDefaultProductLimit;

  Future<void> getProducts({
    required String sellerId,
    required String sellerCategory,
    int limit = 10,
  }) async {
    emit(ProductGetProductsLoadingState());

    try {
      productLimit = limit;
      products.clear();
      isLoadingMoreProducts = false;
      reachedEndProduct = false;
      lastProductDocument = null;

      final query = FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .where('sellerCategory', isEqualTo: sellerCategory)
          .orderBy('createdAt', descending: true)
          .limit(productLimit);

      final result = await query.get();
      lastProductDocument = result.docs.isNotEmpty ? result.docs.last : null;

      products = result.docs
          .map((e) => ProductModel.fromJson(e.data()))
          .toList();
      if (result.docs.length < productLimit) reachedEndProduct = true;

      emit(ProductGetProductsSuccessState());
    } catch (e) {
      emit(ProductGetProductsErrorState(e.toString()));
    }
  }

  Future<void> getMoreProducts({
    required String sellerId,
    required String sellerCategory,
    required BuildContext context,
    int limit = 10,
  }) async {
    if (isLoadingMoreProducts ||
        reachedEndProduct ||
        lastProductDocument == null) {
      return;
    }

    isLoadingMoreProducts = true;
    emit(ProductGetMoreProductsLoadingState());

    try {
      productLimit = limit;
      final query = FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .where('sellerCategory', isEqualTo: sellerCategory)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastProductDocument!)
          .limit(productLimit);

      final result = await query.get();

      // ✅ Offload mapping to isolate
      final rawProducts = result.docs.map((doc) => doc.data()).toList();
      final fetchedProducts = await compute(parseProductsFromDocs, rawProducts);

      lastProductDocument = result.docs.isNotEmpty ? result.docs.last : null;
      products.addAll(fetchedProducts);

      if (fetchedProducts.length < productLimit) {
        reachedEndProduct = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).no_more_products),
            duration: Duration(seconds: 2),
          ),
        );
      }

      emit(ProductGetMoreProductsSuccessState());
    } catch (e) {
      emit(ProductGetMoreProductsErrorState(e.toString()));
    } finally {
      isLoadingMoreProducts = false;
    }
  }

  Future<void> getProductsByCategory({
    required String sellerId,
    required String category,
    required BuildContext context,
    int limit = 10,
  }) async {
    emit(ProductGetProductsByCategoryLoadingState());

    try {
      /// Always reset on fresh category fetch
      productLimit = limit;
      products.clear();
      isLoadingMoreProducts = false;
      reachedEndProduct = false;
      lastProductDocument = null;

      // 🔥 Save current category to a field to ensure consistency
      currentCategory = category;

      final query = FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .where('productCategory', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .limit(productLimit);

      final result = await query.get();
      lastProductDocument = result.docs.isNotEmpty ? result.docs.last : null;

      products = result.docs
          .map((e) => ProductModel.fromJson(e.data()))
          .toList();

      if (result.docs.length < productLimit) {
        reachedEndProduct = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).no_more_products),
            duration: Duration(seconds: 2),
          ),
        );
      }

      emit(ProductGetProductsByCategorySuccessState());
    } catch (e) {
      emit(ProductGetProductsByCategoryErrorState(e.toString()));
    }
  }

  Future<void> getMoreProductsByCategory({
    required String sellerId,
    required String category,
    int limit = 10,
  }) async {
    if (currentCategory != category) return;
    if (isLoadingMoreProducts ||
        reachedEndProduct ||
        lastProductDocument == null) {
      return;
    }

    isLoadingMoreProducts = true;
    emit(ProductGetMoreProductsLoadingState());

    try {
      productLimit = limit;
      final query = FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: sellerId)
          .where('productCategory', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(lastProductDocument!)
          .limit(productLimit);

      final result = await query.get();

      // Extract raw data from the docs to a List<Map<String, dynamic>>
      final rawProducts = result.docs.map((doc) => doc.data()).toList();

      // Offload parsing to background isolate
      final fetchedProducts = await compute(parseProductsFromDocs, rawProducts);

      lastProductDocument = result.docs.isNotEmpty ? result.docs.last : null;
      products.addAll(fetchedProducts);

      if (fetchedProducts.length < productLimit) reachedEndProduct = true;

      emit(ProductGetMoreProductsSuccessState());
    } catch (e) {
      emit(ProductGetMoreProductsErrorState(e.toString()));
    } finally {
      isLoadingMoreProducts = false;
    }
  }

  Future<void> deleteProductsAndRefreshUI({
    required ShopModel shopModel,
    required List<String> productIds,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    try {
      // 1️⃣ Remove products from Firestore first
      for (final productId in productIds) {
        await firestore.collection('products').doc(productId).delete();
        log('✅ Deleted product document: $productId');
      }

      // 2️⃣ Refresh products for the shop immediately
      await getProducts(sellerId: uId, sellerCategory: shopModel.shopCategory);

      // 3️⃣ Delete images in the background (non-blocking)
      for (final productId in productIds) {
        _deleteProductImagesInBackground(storage, productId);
      }
    } catch (e) {
      log('❌ Error deleting products: $e');
    }
  }

  // Helper function for background deletion
  Future<void> _deleteProductImagesInBackground(
    FirebaseStorage storage,
    String productId,
  ) async {
    try {
      final folderRef = storage.ref().child('products/$productId');
      final files = await folderRef.listAll();

      for (final item in files.items) {
        await item.delete();
        log('🗑️ Deleted image: ${item.fullPath}');
      }
    } catch (e) {
      log('❌ Error deleting images for $productId: $e');
    }
  }

  Future<void> deleteAllProductsAndRefreshUI({
    required ShopModel shopModel,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;

    try {
      // 1️⃣ Get all products for this shop
      final snapshot = await firestore
          .collection('products')
          .where('shopId', isEqualTo: shopModel.shopId)
          .get();

      // Collect product IDs
      final productIds = snapshot.docs.map((doc) => doc.id).toList();

      if (productIds.isEmpty) return;

      // 2️⃣ Delete product documents from Firestore
      for (final productId in productIds) {
        await firestore.collection('products').doc(productId).delete();
        log('✅ Deleted product document: $productId');
      }

      // 3️⃣ Refresh UI immediately
      await getProducts(sellerId: uId, sellerCategory: shopModel.shopCategory);

      // 4️⃣ Delete product images asynchronously in the background
      for (final productId in productIds) {
        _deleteProductImagesInBackground(storage, productId);
      }

      log(
        '🧹 All products deleted and UI refreshed for shop: ${shopModel.shopId}',
      );
    } catch (e) {
      log('❌ Error deleting all products for shop ${shopModel.shopId}: $e');
    }
  }

  // SHOPS
  List<ShopModel> allShops = [];
  DocumentSnapshot? lastShopDoc;
  bool hasMoreShops = true;

  Future<void> getAllShops({bool isFirstLoad = false, int pageSize = 3}) async {
    if (isFirstLoad) {
      allShops.clear();
      lastShopDoc = null;
      hasMoreShops = true;
      emit(ProductGetAllSellersLoadingState());
    }

    if (!hasMoreShops) return;

    try {
      Query query = FirebaseFirestore.instance
          .collection('shops')
          .orderBy('sellerCreatedAt', descending: true)
          .limit(pageSize);

      if (lastShopDoc != null) {
        query = query.startAfterDocument(lastShopDoc!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastShopDoc = snapshot.docs.last;
        allShops.addAll(
          snapshot.docs
              .map((e) => ShopModel.fromJson(e.data() as Map<String, dynamic>))
              .toList(),
        );
      }

      if (snapshot.docs.length < pageSize) hasMoreShops = false;

      emit(ProductGetAllSellersSuccessState());
    } catch (e) {
      log('Error paginating shops: $e');
      emit(ProductGetAllSellersErrorState(e.toString()));
    }
  }

  List<ShopModel> sellersSearchResults = [];

  Future<void> searchSellers(String queryText) async {
    emit(ProductSearchLoadingState());

    try {
      final List<String> searchKeywords = queryText
          .toLowerCase()
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toSet()
          .toList()
          .take(10)
          .toList();

      if (searchKeywords.isEmpty) {
        sellersSearchResults = [];
        emit(ProductSearchSuccessState());
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('shops')
          .where('searchKeywords', arrayContainsAny: searchKeywords)
          .limit(20)
          .get();

      sellersSearchResults = snapshot.docs
          .map((doc) => ShopModel.fromJson(doc.data()))
          .toList();

      emit(ProductSearchSuccessState());
    } catch (e) {
      emit(ProductSearchErrorState(e.toString()));
    }
  }

  // List<ShopModel> sellersSearchResults = [];
  // void searchSellers(String query) {
  //   final lowerQuery = query.toLowerCase();
  //   sellersSearchResults = allShops
  //       .where((element) => element.shopName.toLowerCase().contains(lowerQuery))
  //       .toList();
  //   emit(ProductSearchSellersSuccessState());
  // }

  // PRODUCTS
  List<ProductModel> allProducts = [];
  DocumentSnapshot? lastProductDoc;
  bool hasMoreProducts = true;

  Future<void> getAllProducts({
    bool isFirstLoad = false,
    int pageSize = 3,
  }) async {
    if (isFirstLoad) {
      allProducts.clear();
      lastProductDoc = null;
      hasMoreProducts = true;
      emit(ProductGetAllProductsLoadingState());
    }

    if (!hasMoreProducts) return;

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .limit(pageSize);

      if (lastProductDoc != null) {
        query = query.startAfterDocument(lastProductDoc!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        lastProductDoc = snapshot.docs.last;
        allProducts.addAll(
          snapshot.docs
              .map(
                (e) => ProductModel.fromJson(e.data() as Map<String, dynamic>),
              )
              .toList(),
        );
      }

      if (snapshot.docs.length < pageSize) hasMoreProducts = false;

      emit(ProductGetAllProductsSuccessState(allProducts));
    } catch (e) {
      log('Error paginating products: $e');
      emit(ProductGetAllProductsErrorState(e.toString()));
    }
  }

  List<ProductModel> productsSearchResults = [];

  Future<void> searchProducts(String queryText) async {
    emit(ProductSearchLoadingState());

    try {
      // Trim and normalize
      final query = queryText.trim();

      // If empty, return
      if (query.isEmpty) {
        productsSearchResults = [];
        emit(ProductSearchSuccessState());
        return;
      }

      Query<Map<String, dynamic>> firestoreQuery = FirebaseFirestore.instance
          .collection('products');

      // $ → search by price
      if (query.startsWith('\$')) {
        final priceValue = num.tryParse(query.substring(1));
        if (priceValue != null) {
          firestoreQuery = firestoreQuery.where('price', isEqualTo: priceValue);
        } else {
          productsSearchResults = [];
          emit(ProductSearchSuccessState());
          return;
        }
      }
      // # → search by product ID
      else if (query.startsWith('#')) {
        final productId = query.substring(1);
        firestoreQuery = firestoreQuery.where('id', isEqualTo: productId);
      }
      // Normal keyword search
      else {
        final List<String> searchKeywords = query
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .toSet()
            .toList()
            .take(10)
            .toList();

        if (searchKeywords.isEmpty) {
          productsSearchResults = [];
          emit(ProductSearchSuccessState());
          return;
        }

        firestoreQuery = firestoreQuery
            .where('searchKeywords', arrayContainsAny: searchKeywords)
            .limit(20);
      }

      // Execute query
      final snapshot = await firestoreQuery.get();

      productsSearchResults = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();

      emit(ProductSearchSuccessState());
    } catch (e) {
      emit(ProductSearchErrorState(e.toString()));
    }
  }

  Future<void> searchProductsByShopId(
    String queryText, {
    required String shopId,
  }) async {
    emit(ProductSearchLoadingState());

    try {
      // Trim and normalize
      final query = queryText.trim();

      // If empty, return
      if (query.isEmpty) {
        productsSearchResults = [];
        emit(ProductSearchSuccessState());
        return;
      }

      Query<Map<String, dynamic>> firestoreQuery = FirebaseFirestore.instance
          .collection('products')
          .where('shopId', isEqualTo: shopId); // filter by shopId

      // $ → search by price
      if (query.startsWith('\$')) {
        final priceValue = num.tryParse(query.substring(1));
        if (priceValue != null) {
          firestoreQuery = firestoreQuery.where('price', isEqualTo: priceValue);
        } else {
          productsSearchResults = [];
          emit(ProductSearchSuccessState());
          return;
        }
      }
      // # → search by product ID
      else if (query.startsWith('#')) {
        final productId = query.substring(1);
        firestoreQuery = firestoreQuery.where('id', isEqualTo: productId);
      }
      // Normal keyword search
      else {
        final List<String> searchKeywords = query
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .toSet()
            .toList()
            .take(10)
            .toList();

        if (searchKeywords.isEmpty) {
          productsSearchResults = [];
          emit(ProductSearchSuccessState());
          return;
        }

        firestoreQuery = firestoreQuery
            .where('searchKeywords', arrayContainsAny: searchKeywords)
            .limit(20);
      }

      // Execute query
      final snapshot = await firestoreQuery.get();

      productsSearchResults = snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();

      emit(ProductSearchSuccessState());
    } catch (e) {
      emit(ProductSearchErrorState(e.toString()));
    }
  }

  Future<void> getProductsByShopId({required String shopId}) async {
    emit(ProductGetAllProductsLoadingState());
    allProducts = [];

    try {
      final result = await FirebaseFirestore.instance
          .collection('products')
          .where('shopId', isEqualTo: shopId)
          .get();

      allProducts = result.docs
          .map((e) => ProductModel.fromJson(e.data()))
          .toList();

      emit(ProductGetAllProductsSuccessState(allProducts));
    } catch (e) {
      log('❌ Failed to get products for shop $shopId: $e');
      emit(ProductGetAllProductsErrorState(e.toString()));
    }
  }

  // List<ProductModel> productsSearchResults = [];
  // void searchProducts(String query) {
  //   final lowerQuery = query.toLowerCase();
  //
  //   if (query.startsWith('#') && query.length > 1) {
  //     final productId = query.substring(1); // remove `#`
  //
  //     productsSearchResults = allProducts.where((product) {
  //       return product.id.toLowerCase().contains(
  //         productId.toLowerCase(),
  //       ); // ✅ هنا التعديل
  //     }).toList();
  //   } else if (query.startsWith('\$') && query.length > 1) {
  //     final productPrice = query.substring(1); // remove `$`
  //
  //     productsSearchResults = allProducts.where((product) {
  //       return product.price.toDouble().toString().contains(productPrice);
  //     }).toList();
  //   } else {
  //     productsSearchResults = allProducts.where((product) {
  //       return product.title.toLowerCase().contains(lowerQuery);
  //     }).toList();
  //   }
  //
  //   emit(ProductSearchProductsSuccessState());
  // }

  Future<void> addProductToCart({required CartProductItemModel product}) async {
    emit(ProductAddProductToCartLoadingState());

    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('cart')
          .where('product.id', isEqualTo: product.product.id)
          .where(
            'selectedSpecifications',
            isEqualTo: product.selectedSpecifications,
          )
          .get();

      if (result.docs.isNotEmpty) {
        // ✅ Just update the quantity
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uId)
            .collection('cart')
            .doc(result.docs.first.id)
            .update({'quantity': FieldValue.increment(product.quantity)});
      } else {
        // ✅ Add the product with base price and quantity
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uId)
            .collection('cart')
            .add(product.toMap());
      }

      await getCartProducts();
      emit(ProductAddProductToCartSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductAddProductToCartErrorState(e.toString()));
    }
  }

  Future<void> editCartProduct({required CartProductItemModel newItem}) async {
    emit(ProductEditCartProductLoadingState());

    try {
      // 🔍 Find the existing cart document by product ID
      final result = await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('cart')
          .where('product.id', isEqualTo: newItem.product.id)
          .get();

      if (result.docs.isEmpty) {
        throw Exception("Product not found in cart");
      }

      // 📝 Update the found document with the new values
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('cart')
          .doc(result.docs.first.id)
          .update({
            ...newItem.toMap(),
            'product.price': newItem.product.price * newItem.quantity,
          });

      await getCartProducts();
      emit(ProductEditCartProductSuccessState());
    } catch (e) {
      log('Edit cart error: $e');
      emit(ProductEditCartProductErrorState(e.toString()));
    }
  }

  List<CartProductItemModel> cartProducts = [];
  num totalCartPrice = 0;
  num totalCartQuantity = 0;
  Future<void> getCartProducts() async {
    emit(ProductGetCartProductsLoadingState());
    cartProducts = [];
    totalCartPrice = 0;
    totalCartQuantity = 0;

    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('cart')
          .get();

      cartProducts = result.docs
          .map((e) => CartProductItemModel.fromJson(e.data(), e.id))
          .toList();

      for (CartProductItemModel product in cartProducts) {
        // Use the model's calculated totalPrice
        totalCartPrice += product.totalPrice;
        totalCartQuantity += product.quantity;
      }

      emit(ProductGetCartProductsSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductGetCartProductsErrorState(e.toString()));
    }
  }

  Future<void> removeProductFromCart({required int index}) async {
    emit(ProductRemoveProductFromCartLoadingState());
    CartProductItemModel product = cartProducts[index];

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('cart')
          .doc(product.id)
          .delete();

      cartProducts.removeAt(index);
      totalCartQuantity -= product.quantity;
      totalCartPrice -= product.totalPrice; // ✅ استخدم totalPrice

      emit(ProductRemoveProductFromCartSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductRemoveProductFromCartErrorState(e.toString()));
    }
  }

  Future<void> decreaseProductQuantityInCart({required int index}) async {
    emit(ProductDecreaseProductQuantityInCartLoadingState());
    CartProductItemModel product = cartProducts[index];

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('cart')
          .doc(product.id)
          .update({
            'quantity': FieldValue.increment(-1),
            'totalPrice': FieldValue.increment(-product.piecePrice), // ✅
          });

      cartProducts[index].quantity--;
      cartProducts[index].totalPrice -= product.piecePrice;
      totalCartQuantity--;
      totalCartPrice -= product.piecePrice;

      emit(ProductDecreaseProductQuantityInCartSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductDecreaseProductQuantityInCartErrorState(e.toString()));
    }
  }

  Future<void> increaseProductQuantityInCart({required int index}) async {
    emit(ProductIncreaseProductQuantityInCartLoadingState());
    CartProductItemModel product = cartProducts[index];

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('cart')
          .doc(product.id)
          .update({
            'quantity': FieldValue.increment(1),
            'totalPrice': FieldValue.increment(product.piecePrice), // ✅
          });

      cartProducts[index].quantity++;
      cartProducts[index].totalPrice += product.piecePrice;
      totalCartQuantity++;
      totalCartPrice += product.piecePrice;

      emit(ProductIncreaseProductQuantityInCartSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductIncreaseProductQuantityInCartErrorState(e.toString()));
    }
  }

  Future<void> clearCart() async {
    emit(ProductClearCartLoadingState());
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uId)
          .collection('cart')
          .get()
          .then((snapshot) {
            for (DocumentSnapshot doc in snapshot.docs) {
              doc.reference.delete();
            }
          });
      cartProducts = [];
      totalCartPrice = 0;
      totalCartQuantity = 0;
      emit(ProductClearCartSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductClearCartErrorState(e.toString()));
    }
  }

  Future<void> placeOrder({
    required String docId,
    required String shopId,
    required num deliveryTime,
    required double price,
    required BuildContext context,
  }) async {
    emit(ProductPlaceOrderLoadingState());
    try {
      final currentAddress = currentUserModel.currentAddress;

      final order = await compute(buildOrder, {
        "id": docId,
        "buyerId": uId,
        "buyerName": currentUserModel.username,
        "buyerPhone": currentUserModel.phoneNumber,
        "buyerAddress": currentAddress,
        "sellerId": cartProducts.first.product.sellerId,
        "shopId": shopId,
        "sellerName": cartProducts.first.product.shopName,
        "sellerPhone": cartProducts.first.product.sellerPhone,
        "orderStatus": OrderStatus.pending,
        "deliveryTime": deliveryTime,
        "price": price,
        "products": cartProducts,
        "createdAt": Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uId).set({
        'shopsVisibleToComment': FieldValue.arrayUnion([shopId]),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(docId)
          .set(order.toMap(), SetOptions(merge: true));

      // Notifications (keep on main isolate, network-bound anyway)
      await NotificationCubit.instance.sendNotification(
        title: currentUserModel.username,
        body: lang == 'en' ? "New order" : "طلب جديد",
        userId: shopId,
        notificationType: NotificationTypes.newOrder,
        payload: jsonEncode({
          'type': NotificationTypes.newOrder.name,
          'orderModel': order.toMap(),
        }),
      );

      await NotificationCubit.instance.createNotification(
        receiverId: shopId,
        receiverType: 'shop',
        title: currentUserModel.username,
        body:
            "${currentUserModel.username} has just ordered a new product from you",
        type: NotificationTypes.newOrder,
        payload: {
          'senderProfile': currentUserModel.profilePicture,
          'orderModel': order.toMap(),
        },
      );

      await clearCart();
      emit(ProductPlaceOrderSuccessState());
      await OrderCubit.get(context).getOrderById(order.id);
    } catch (e) {
      log(e.toString());
      emit(ProductPlaceOrderErrorState(e.toString()));
    }
  }

  Future<void> addNewAddress({required String address}) async {
    emit(ProductSaveAddressLoadingState());
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uId);
      await userDoc.set({
        'addresses': FieldValue.arrayUnion([address]),
      }, SetOptions(merge: true));
      // Also update local model
      currentUserModel.addresses.add(address);
      // await refreshUserModel(); // new function
      emit(ProductSaveAddressSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductSaveAddressErrorState(e.toString()));
    }
  }

  Future<void> changeSpecificAddress({
    required int index,
    required String newAddress,
  }) async {
    emit(ProductSaveAddressLoadingState());
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uId);

      // Remove the old address and add the new one
      String oldAddress = currentUserModel.addresses[index];
      currentUserModel.addresses[index] = newAddress;

      await userDoc.update({'addresses': currentUserModel.addresses});

      // If this address was the current one, update it as well
      if (currentUserModel.currentAddress == oldAddress) {
        await userDoc.set({
          'currentAddress': newAddress,
        }, SetOptions(merge: true));
        currentUserModel.currentAddress = newAddress;
      }
      // await refreshUserModel(); // new function
      emit(ProductSaveAddressSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductSaveAddressErrorState(e.toString()));
    }
  }

  Future<void> setCurrentAddress({required String address}) async {
    emit(ProductSaveAddressLoadingState());
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uId);
      await userDoc.set({'currentAddress': address}, SetOptions(merge: true));
      currentUserModel.currentAddress = address;
      // await refreshUserModel(); // new function
      emit(ProductSaveAddressSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductSaveAddressErrorState(e.toString()));
    }
  }

  // Future<void> refreshUserModel() async {
  //   final userDoc =
  //       await FirebaseFirestore.instance.collection('users').doc(uId).get();
  //   currentUserModel = UserModel.fromJson(
  //     userDoc.data()!,
  //   ); // or however you parse
  // }

  // Future<void> saveAddress({required String address}) async {
  //   emit(ProductSaveAddressLoadingState());
  //   try {
  //     await FirebaseFirestore.instance.collection('users').doc(uId).set({
  //       'address': address,
  //     }, SetOptions(merge: true));
  //     currentUserModel.address = address;
  //     emit(ProductSaveAddressSuccessState());
  //   } catch (e) {
  //     log(e.toString());
  //     emit(ProductSaveAddressErrorState(e.toString()));
  //   }
  // }

  Future<void> increaseProductClicks({required String productId}) async {
    emit(ProductIncreaseProductClicksLoadingState());
    try {
      FirebaseFirestore.instance.collection('products').doc(productId).update({
        'clicks': FieldValue.increment(1),
        'clickEvents': FieldValue.arrayUnion([
          {'timestamp': Timestamp.now()},
        ]),
      });
      emit(ProductIncreaseProductClicksSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductIncreaseProductClicksErrorState(e.toString()));
    }
  }

  List<ProductModel> filteredProducts = [];
  Future<void> filterProducts({
    required String sellerCategory,
    required String productCategory,
    required RangeValues priceRange,
  }) async {
    emit(ProductFilterProductsLoadingState());
    try {
      final result = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerCategory', isEqualTo: sellerCategory)
          .where('productCategory', isEqualTo: productCategory)
          .where('price', isGreaterThanOrEqualTo: priceRange.start)
          .where('price', isLessThanOrEqualTo: priceRange.end)
          .get();
      filteredProducts = [];
      filteredProducts = result.docs
          .map((e) => ProductModel.fromJson(e.data()))
          .toList();
      emit(ProductFilterProductsSuccessState());
    } catch (e) {
      log(e.toString());
      emit(ProductFilterProductsErrorState(e.toString()));
    }
  }

  void setFilteredProducts(List<ProductModel> products) {
    filteredProducts = products;
    emit(FilteredProductsUpdatedState());
  }

  Future<void> paypal({required num val}) async {
    emit(ProductPaypalPayLoadingState());
    try {
      String url = 'https://paypal-zfje.onrender.com/pay?value=$val';
      final response = await Dio().post(url);
      if (response.statusCode == 200) {
        emit(ProductPaypalPaySuccessState(response.data['payLink']));
      } else {
        emit(ProductPaypalPayErrorState('Error creating payment link'));
      }
    } catch (e) {
      log('Error creating contract: $e');
      emit(ProductPaypalPayErrorState(e.toString()));
    }
  }

  Future<ShopModel?> getShop({required String sellerId}) async {
    emit(ProductGetSellerLoadingState());
    try {
      final result = await FirebaseFirestore.instance
          .collection('shops')
          .where('shopId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        ShopModel seller = ShopModel.fromJson(result.docs.first.data());
        emit(ProductGetSellerSuccessState());
        return seller;
      } else {
        emit(ProductGetSellerErrorState('No shop found for this seller.'));
        return null;
      }
    } catch (e) {
      log('Error fetching seller shop: $e');
      emit(ProductGetSellerErrorState(e.toString()));
      return null;
    }
  }

  List<ProductModel> searchSellerProducts = [];
  Future<void> searchInSellerProducts({required String regex}) async {
    // search in products list
    searchSellerProducts = products
        .where((element) => element.title.toLowerCase().contains(regex))
        .toList();
    emit(ProductSearchSellerProductsSuccessState());
  }

  Future<void> getAppCommission() async {
    emit(ProductGetAppCommissionLoadingState());
    try {
      final result = await FirebaseFirestore.instance
          .collection('admins')
          .doc('commission')
          .get();
      num commission = num.parse(result.data()!['commission']);
      emit(ProductGetAppCommissionSuccessState(commission));
    } catch (e) {
      log(e.toString());
      emit(ProductGetAppCommissionErrorState(e.toString()));
    }
  }
}
