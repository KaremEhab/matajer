import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:matajer/constants/cache_helper.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/product/product_cubit.dart';
import 'package:matajer/cubit/user/user_state.dart';
import 'package:matajer/models/shop_model.dart';
import 'package:matajer/models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserInitialState());

  static UserCubit get(context) => BlocProvider.of(context);

  final firestore = FirebaseFirestore.instance;

  List<Map<String, String>> currentUserShops = [];

  Future<void> getUserData() async {
    emit(UserGetUserDataLoadingState());
    try {
      var result = await firestore.collection('users').doc(uId).get();

      currentUserModel = UserModel.fromJson(result.data()!);
      await CacheHelper.saveData(
        key: 'currentUserModel',
        value: currentUserModel.toMap(), // ✅ Map<String, dynamic>
      );

      if (currentUserModel.shops.isNotEmpty) {
        for (final shop in currentUserModel.shops) {
          final shopRef = FirebaseFirestore.instance
              .collection('shops')
              .doc(shop['id']);
          final shopSnapshot = await shopRef.get();

          if (shopSnapshot.exists) {
            final shopData = shopSnapshot.data();
            final List<dynamic>? existingTokens = shopData?['fcmTokens'];

            // If fcmTokens doesn't exist or does not contain the new token, update it
            if (existingTokens == null ||
                !existingTokens.contains(fcmDeviceToken)) {
              await shopRef.update({
                'fcmTokens': [fcmDeviceToken],
                'activityStatus': UserActivityStatus.online.name,
              });
            }
          }
        }
      }

      emit(UserGetUserDataSuccessState());
    } catch (e) {
      log(e.toString());
      emit(UserGetUserDataErrorState(e.toString()));
    }
  }

  Future<UserModel> getUserInfoById(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch user info: $e');
    }
  }

  Future<void> setActivityStatus({
    String? userId,
    required String statusValue,
    String? shopIdIfSeller,
  }) async {
    final isOnline = statusValue == 'online';

    final mainId = userId?.isNotEmpty == true ? userId : shopIdIfSeller;

    if (mainId == null || mainId.isEmpty) {
      log('❌ No valid userId or shopId to update activity status');
      return;
    }

    final batch = firestore.batch();

    // Update user activity status
    if (userId?.isNotEmpty == true) {
      final userRef = firestore.collection('users').doc(userId);
      batch.update(userRef, {'activityStatus': statusValue});

      currentUserModel.activityStatus = isOnline
          ? UserActivityStatus.online
          : UserActivityStatus.offline;
    }

    // Update shop activity status
    if (isSeller && shopIdIfSeller?.isNotEmpty == true) {
      final shopRef = firestore.collection('shops').doc(shopIdIfSeller);
      batch.update(shopRef, {'activityStatus': statusValue});

      currentShopModel!.activityStatus = isOnline
          ? ShopActivityStatus.online
          : ShopActivityStatus.offline;
    }

    // Update related chats using mainId
    final chatQuery = await firestore
        .collection('chats')
        .where('participants', arrayContains: mainId)
        .get();

    for (final doc in chatQuery.docs) {
      final chatRef = firestore.collection('chats').doc(doc.id);
      batch.update(chatRef, {'${mainId}_online': isOnline});
    }

    await batch.commit();

    log(
      '✅ ActivityStatus updated: $mainId → $statusValue in user/shop and ${chatQuery.docs.length} chats',
    );
  }

  // Future<void> updateUserChatStatus(String userId, String statusValue) async {
  //   try {
  //     final query =
  //         await FirebaseFirestore.instance
  //             .collection('chats')
  //             .where('participants', arrayContains: userId)
  //             .get();
  //
  //     final isOnline = statusValue == 'online';
  //
  //     for (final doc in query.docs) {
  //       final chatId = doc.id;
  //
  //       // Parse chatId to get both IDs
  //       final parts = chatId.split('_');
  //       if (parts.length != 2) continue;
  //
  //       String id1 = parts[0];
  //       String id2 = parts[1];
  //
  //       // Try to get the shop document from shops collection
  //       String shopId = id1.startsWith('shop_') ? id1 : id2;
  //
  //       final shopDoc =
  //           await FirebaseFirestore.instance
  //               .collection('shops')
  //               .doc(shopId)
  //               .get();
  //
  //       if (!shopDoc.exists) continue;
  //
  //       final sellerId = shopDoc.data()?['sellerId'];
  //       if (sellerId == null) continue;
  //
  //       // Define who is the other participant
  //       final otherId =
  //           sellerId == userId
  //               ? id1 == sellerId
  //                   ? id2
  //                   : id1
  //               : sellerId;
  //
  //       // Update only if userId is the receiver in this chat
  //       final receiverIdInThisChat = doc['sentBy'] == userId ? otherId : userId;
  //
  //       if (receiverIdInThisChat == userId) {
  //         await firestore.collection('chats').doc(chatId).update({
  //           'receiverOnline': isOnline,
  //         });
  //         log("✅ Updated chat $chatId with receiverOnline: $isOnline");
  //       }
  //     }
  //   } catch (e) {
  //     log("❌ Error updating chat statuses: $e");
  //   }
  // }
  //
  // Future<void> updateUserChatSenderStatus(
  //   String userId,
  //   String statusValue,
  // ) async {
  //   try {
  //     final query =
  //         await FirebaseFirestore.instance
  //             .collection('chats')
  //             .where('participants', arrayContains: userId)
  //             .get();
  //
  //     final isOnline = statusValue == 'online';
  //
  //     for (final doc in query.docs) {
  //       final chatId = doc.id;
  //
  //       // Parse chatId to get both IDs
  //       final parts = chatId.split('_');
  //       if (parts.length != 2) continue;
  //
  //       String id1 = parts[0];
  //       String id2 = parts[1];
  //
  //       // Try to get the shop document from shops collection
  //       String shopId = id1.startsWith('shop_') ? id1 : id2;
  //
  //       final shopDoc =
  //           await FirebaseFirestore.instance
  //               .collection('shops')
  //               .doc(shopId)
  //               .get();
  //
  //       if (!shopDoc.exists) continue;
  //
  //       final sellerId = shopDoc.data()?['sellerId'];
  //       if (sellerId == null) continue;
  //
  //       // Define who is the other participant
  //       final otherId =
  //           sellerId == userId
  //               ? id1 == sellerId
  //                   ? id2
  //                   : id1
  //               : sellerId;
  //
  //       // Update only if userId is the sender in this chat
  //       final senderIdInThisChat = doc['sentBy'] == userId ? userId : otherId;
  //
  //       if (senderIdInThisChat == userId) {
  //         await firestore.collection('chats').doc(chatId).update({
  //           'senderOnline': isOnline,
  //         });
  //         log("✅ Updated chat $chatId with senderOnline: $isOnline");
  //       }
  //     }
  //   } catch (e) {
  //     log("❌ Error updating sender chat statuses: $e");
  //   }
  // }

  Future<String> uploadImage({
    required XFile image,
    required String docId,
    required String imageName,
  }) async {
    try {
      String downloadURL = '';
      emit(UserUploadImageLoadingState());
      FirebaseStorage storageRef = FirebaseStorage.instance;
      String imagePath =
          'sellers/$docId/$imageName.${image.path.split('.').last}';
      Reference reference = storageRef.ref().child(imagePath);
      UploadTask uploadTask = reference.putFile(File(image.path));
      // Wait for the upload task to complete
      TaskSnapshot taskSnapshot = await uploadTask;
      // Get the download URL for the current image
      downloadURL = await taskSnapshot.ref.getDownloadURL();
      emit(UserUploadImageSuccessState());
      return downloadURL;
    } catch (error) {
      log('Error uploading images: $error');
      emit(UserUploadImageErrorState(error.toString()));
      return '';
    }
  }

  String? uploadedLogoUrl;
  String? uploadedBannerUrl;

  Future<void> uploadShopImages({
    required XFile shopLogo,
    required XFile shopBanner,
    required String shopId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final compressedLogo = await compressImage(shopLogo);
      final compressedBanner = await compressImage(shopBanner);

      final total = 2;
      int uploaded = 0;

      Future<String> uploadAndTrack(XFile image, String name) async {
        final url = await uploadImage(
          image: image,
          docId: shopId,
          imageName: name,
        );
        uploaded++;
        if (onProgress != null) onProgress(uploaded / total);
        return url;
      }

      final results = await Future.wait([
        uploadAndTrack(XFile(compressedLogo.path), 'shopLogo'),
        uploadAndTrack(XFile(compressedBanner.path), 'shopBanner'),
      ]);

      uploadedLogoUrl = results[0];
      uploadedBannerUrl = results[1];
    } catch (e) {
      log('Error uploading shop images: $e');
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

  String? tempShopId; // temporarily holds shop ID from page 2 upload

  Future<void> registerShop({
    required String shopName,
    required String shopCategory,
    required String shopDescription,
    required num deliveryDays,
    required num avgResponseTime,
    required num sellerLicenseNumber,
    required XFile shopLogo,
    required XFile shopBanner,
    required XFile sellerLicenseImage,
    required BuildContext context,
  }) async {
    emit(UserRegisterSellerLoadingState());

    final overlay = Overlay.of(context, rootOverlay: true);
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
                      'Uploading ${(value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Please keep the screen open until upload finishes.',
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

    Future<void> hideUploadOverlay() async {
      try {
        await getUserData();
      } catch (_) {}
      if (loaderEntry.mounted) {
        userRegistered = true;
        print("SUCCESSSSSSSSSSSSSSSSSS");
        emit(UserRegisterSellerSuccessState());
        loaderEntry.remove();
      }
    }

    try {
      final shopDoc = firestore
          .collection('shops')
          .doc(tempShopId ?? firestore.collection('shops').doc().id);
      showUploadOverlay();

      // Upload Images
      progressNotifier.value = 0.1;
      if (uploadedLogoUrl == null || uploadedBannerUrl == null) {
        await uploadShopImages(
          shopLogo: shopLogo,
          shopBanner: shopBanner,
          shopId: shopDoc.id,
        );
      }

      if (uploadedLogoUrl == null || uploadedBannerUrl == null) {
        throw 'Images not uploaded. Please re-upload.';
      }

      progressNotifier.value = 0.4;
      final compressedLicense = await compressImage(sellerLicenseImage);
      final sellerLicenseImageUrl = await uploadImage(
        image: XFile(compressedLicense.path),
        docId: shopDoc.id,
        imageName: 'sellerLicenseImage',
      );

      progressNotifier.value = 0.6;
      final userDoc = await firestore.collection('users').doc(uId).get();
      final List<dynamic> existingShops = userDoc.data()?['shops'] ?? [];

      progressNotifier.value = 0.75;
      final shopModel = ShopModel(
        sellerId: uId,
        shopId: shopDoc.id,
        shopName: shopName,
        shopCategory: shopCategory,
        shopDescription: shopDescription,
        shopLogoUrl: uploadedLogoUrl!,
        shopBannerUrl: uploadedBannerUrl!,
        sellerLicenseNumber: sellerLicenseNumber,
        sellerLicenseImageUrl: sellerLicenseImageUrl,
        emirate: currentUserModel.emirate,
        deliveryDays: deliveryDays,
        avgResponseTime: avgResponseTime,
        numberOfRating: 0,
        sumOfRating: 0,
        activityStatus: ShopActivityStatus.online,
        autoAcceptOrders: autoAcceptOrders,
        subcategories: [],
        usersSetAsFavorite: [],
        // autoAcceptEnabledAt: null,
        sellerCreatedAt: Timestamp.now(),
      )..subcategories = [];

      existingShops.add({
        'id': shopDoc.id,
        'name': shopName,
        'logo': uploadedLogoUrl!,
        'category': shopCategory,
      });

      await shopDoc.set(shopModel.toMap());

      progressNotifier.value = 0.9;
      await firestore.collection('users').doc(uId).update({
        'shops': existingShops,
        'hasShop': true,
        'userType': 'seller',
      });

      await FirebaseFirestore.instance.collection('shops').doc(shopDoc.id).set({
        ...shopModel.toMap(),
        'fcmTokens': [fcmDeviceToken],
      });

      progressNotifier.value = 1.0;

      uploadedLogoUrl = null;
      uploadedBannerUrl = null;
      tempShopId = null;

      await hideUploadOverlay();
    } catch (e) {
      await hideUploadOverlay();
      log('Register Shop Error: $e');
      emit(UserRegisterSellerErrorState(e.toString()));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to register shop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool shouldRefreshSellers = false;

  void markShouldRefreshSellers() {
    shouldRefreshSellers = true;
  }

  void clearRefreshFlag() {
    shouldRefreshSellers = false;
  }

  Future<void> getShop() async {
    try {
      final shopQuery = await firestore
          .collection('shops')
          .where('sellerId', isEqualTo: uId)
          .limit(1)
          .get();

      if (shopQuery.docs.isNotEmpty) {
        currentShopModel = ShopModel.fromJson(shopQuery.docs.first.data());
        await CacheHelper.saveData(
          key: 'currentShopModel',
          value: currentShopModel!,
        );
      }
    } catch (e) {
      log('Error getting shop: $e');
    }
  }

  Future<void> getShopById(String shopId) async {
    emit(GetUserShopByIdLoadingState());
    try {
      final shopDoc = await firestore.collection('shops').doc(shopId).get();

      if (shopDoc.exists) {
        currentShopModel = ShopModel.fromJson(shopDoc.data()!);

        // 👇 Replace all old tokens with the new one
        await FirebaseFirestore.instance.collection('shops').doc(shopId).update(
          {
            'fcmTokens': [fcmDeviceToken],
            'activityStatus': UserActivityStatus.online.name,
          },
        );

        await CacheHelper.saveData(
          key: 'currentShopModel',
          value: jsonEncode(currentShopModel!.toMap()),
        );
      }

      emit(GetUserShopByIdSuccessState());
    } catch (e) {
      log('Error getting shop by ID: $e');
      emit(GetUserShopByIdErrorState(e.toString()));
    }
  }

  ShopModel? shopById;

  Future<ShopModel?> getShopInfoById(String shopId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final shop = ShopModel.fromJson(data!);
        shopById = shop;

        emit(GetShopByIdSuccessState());
        return shop;
      }
    } catch (e) {
      log('Error fetching shop info: $e');
      emit(GetShopByIdErrorState());
    }
    return null;
  }

  Future<void> deleteShop({
    required BuildContext context,
    required String userId,
    required ShopModel shopModel,
    void Function()? onShopDeleted, // Callback to update UI
  }) async {
    final firestore = FirebaseFirestore.instance;
    final storage = FirebaseStorage.instance;
    final productCubit = ProductCubit.get(context);

    // 🔄 Show a non-dismissible dialog while deleting
    Future<void> showDeletingDialog() async {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Dialog(
          backgroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  backgroundColor: Colors.grey,
                  color: Colors.redAccent,
                ),
                SizedBox(height: 16),
                Text(
                  'Deleting shop...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we remove your shop and its products.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      showDeletingDialog();

      // 1️⃣ Delete all products and refresh UI immediately
      await productCubit.deleteAllProductsAndRefreshUI(shopModel: shopModel);

      // 2️⃣ Delete shop images in background
      Future.wait([
        storage.ref('sellers/${shopModel.shopId}/shopLogo.jpg').delete(),
        storage.ref('sellers/${shopModel.shopId}/shopBanner.jpg').delete(),
        storage
            .ref('sellers/${shopModel.shopId}/sellerLicenseImage.jpg')
            .delete(),
      ]).catchError((e) => log("⚠️ Error deleting shop images: $e"));

      // 3️⃣ Delete all product images in background
      _deleteAllProductImagesForShop(shopModel.shopId);

      // 4️⃣ Delete shop chats
      final chatQuery = await firestore
          .collection('chats')
          .where('participants', arrayContains: shopModel.shopId)
          .get();
      for (final doc in chatQuery.docs) {
        await doc.reference.delete();
      }

      // 5️⃣ Delete shop document
      await firestore.collection('shops').doc(shopModel.shopId).delete();

      // 6️⃣ Update user shops
      final userDocRef = firestore.collection('users').doc(userId);
      final userDocSnap = await userDocRef.get();
      final userData = userDocSnap.data();

      if (userData != null && userData['shops'] is List) {
        final List<dynamic> shops = userData['shops'];
        shops.removeWhere((shop) => shop['id'] == shopModel.shopId);

        final updates = {'shops': shops, 'hasShop': shops.isNotEmpty};
        if (shops.isEmpty) {
          updates['userType'] = 'buyer';
          currentUserModel.hasShop = false;
          currentUserModel.userType = UserType.buyer;
          currentUserModel.shops = [];
        } else {
          currentUserModel.shops = List<Map<String, dynamic>>.from(shops);
        }
        await userDocRef.update(updates);
      }

      // 7️⃣ Notify UI
      onShopDeleted?.call();

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // close progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Shop deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // close progress dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Failed to delete shop: $e')));
      }
      log('❌ Failed to delete shop: $e');
    }
  }

  // Helper: Delete all product images of a shop in background
  Future<void> _deleteAllProductImagesForShop(String shopId) async {
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      final snapshot = await firestore
          .collection('products')
          .where('shopId', isEqualTo: shopId)
          .get();

      for (final doc in snapshot.docs) {
        final productId = doc.id;
        final folderRef = storage.ref().child('products/$productId');
        final files = await folderRef.listAll();

        for (final item in files.items) {
          await item.delete();
          log('🗑️ Deleted product image: ${item.fullPath}');
        }
      }
    } catch (e) {
      log('⚠️ Failed to delete product images for shop $shopId: $e');
    }
  }

  Future<void> changeEmail({
    required String email,
    required String password,
  }) async {
    emit(UserChangeEmailLoadingState());

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: currentUserModel.email,
            password: password,
          );

      final user = userCredential.user!;

      // 1. Update Firestore
      await firestore.collection('users').doc(uId).update({'email': email});
      currentUserModel.email = email;

      // 2. Trigger secure verification-based update
      await user.verifyBeforeUpdateEmail(email);

      emit(UserChangeEmailSuccessState());
    } catch (e) {
      log(e.toString());
      emit(UserChangeEmailErrorState(e.toString()));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    emit(UserChangePasswordLoadingState());
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: currentUserModel.email,
            password: currentPassword,
          );
      userCredential.user!.updatePassword(newPassword);
      emit(UserChangePasswordSuccessState());
    } catch (e) {
      log(e.toString());
      emit(UserChangePasswordErrorState(e.toString()));
    }
  }

  Future<void> updateBuyerData({
    required String username,
    XFile? image,
    DateTime? birthdate,
    String? gender, // 👈 هنا الإضافة
  }) async {
    emit(UserUpdateBuyerDataLoadingState());

    Map<String, dynamic> data = {'username': username};

    if (birthdate != null) {
      data['birthdate'] = birthdate;
    }

    if (gender != null) {
      data['gender'] = gender; // 👈 هنا الإضافة
    }

    if (image != null) {
      String imageUrl = await uploadImage(
        image: image,
        docId: uId,
        imageName: 'profileImage',
      );
      data['imageUrl'] = imageUrl;
    }

    try {
      await firestore
          .collection('users')
          .doc(uId)
          .set(data, SetOptions(merge: true));
      await getUserData();
      emit(UserUpdateBuyerDataSuccessState());
    } catch (e) {
      log(e.toString());
      emit(UserUpdateBuyerDataErrorState(e.toString()));
    }
  }
}
