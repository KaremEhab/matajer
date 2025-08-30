import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/cubit/notifications/notification_cubit.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/product_model.dart';
import 'package:matajer/screens/home/categories/shop_list_card.dart';
import 'package:matajer/screens/home/categories/shop_products_card.dart';
import 'package:matajer/screens/home/product_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/widgets/pick_image_source.dart';
import '../../constants/vars.dart';
import 'order_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

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

class OrderCubit extends Cubit<OrderState> {
  OrderCubit() : super(OrderInitial());

  static OrderCubit get(context) => BlocProvider.of(context);

  Future<void> ordersScreenInit() async {
    emit(OrderOrderScreenInitLoadingState());
    await Future.wait([
      getSellerActiveOrders(),
      getFulfilledOrdersCount(),
      getActiveOrdersCount(),
      getPendingOrdersCount(),
    ]);
    emit(OrderOrderScreenInitSuccessState());
  }

  List<OrderModel> activeOrders = [];
  List<OrderModel> historyOrders = [];
  Future<void> getSellerActiveOrders() async {
    activeOrders = [];
    emit(OrderGetSellerOrdersLoadingState());
    try {
      final userText = isSeller ? 'shopId' : 'sellerId';
      final userId = isSeller ? currentShopModel!.shopId : uId;
      var result = await FirebaseFirestore.instance
          .collection('orders')
          .where(userText, isEqualTo: userId)
          .where(
            'orderStatus',
            whereIn: [
              OrderStatus.pending.index,
              OrderStatus.accepted.index,
              OrderStatus.shipped.index,
            ],
          )
          .orderBy('createdAt', descending: true)
          .get();
      for (var element in result.docs) {
        activeOrders.add(OrderModel.fromJson(element.data(), element.id));
      }
      emit(OrderGetSellerOrdersSuccessState());
    } catch (e) {
      emit(OrderGetSellerOrdersErrorState(e.toString()));
    }
  }

  Future<void> getSellerHistoryOrders() async {
    historyOrders = [];
    emit(OrderGetSellerOrdersLoadingState());
    try {
      final userText = isSeller ? 'shopId' : 'sellerId';
      final userId = isSeller ? currentShopModel!.shopId : uId;
      var result = await FirebaseFirestore.instance
          .collection('orders')
          .where(userText, isEqualTo: userId)
          .where(
            'orderStatus',
            whereIn: [OrderStatus.delivered.index, OrderStatus.rejected.index],
          )
          .orderBy('createdAt', descending: true)
          .get();
      for (var element in result.docs) {
        historyOrders.add(OrderModel.fromJson(element.data(), element.id));
      }
      emit(OrderGetSellerOrdersSuccessState());
    } catch (e) {
      emit(OrderGetSellerOrdersErrorState(e.toString()));
    }
  }

  int fulfilledOrdersCount = 0;
  Future<void> getFulfilledOrdersCount() async {
    fulfilledOrdersCount = 0;
    try {
      final userText = isSeller ? 'shopId' : 'sellerId';
      final userId = isSeller ? currentShopModel!.shopId : uId;
      var result = await FirebaseFirestore.instance
          .collection('orders')
          .where(userText, isEqualTo: userId)
          .where('orderStatus', isEqualTo: OrderStatus.delivered.index)
          .get();
      fulfilledOrdersCount = result.docs.length;
    } catch (e) {
      log(e.toString());
    }
  }

  int activeOrdersCount = 0;
  Future<void> getActiveOrdersCount() async {
    activeOrdersCount = 0;
    try {
      final userText = isSeller ? 'shopId' : 'sellerId';
      final userId = isSeller ? currentShopModel!.shopId : uId;
      var result = await FirebaseFirestore.instance
          .collection('orders')
          .where(userText, isEqualTo: userId)
          .where('orderStatus', isNotEqualTo: OrderStatus.delivered.index)
          .get();
      activeOrdersCount = result.docs.length;
    } catch (e) {
      log(e.toString());
    }
  }

  int pendingOrdersCount = 0;
  Future<void> getPendingOrdersCount() async {
    pendingOrdersCount = 0;
    try {
      final userText = isSeller ? 'shopId' : 'sellerId';
      final userId = isSeller ? currentShopModel!.shopId : uId;
      var result = await FirebaseFirestore.instance
          .collection('orders')
          .where(userText, isEqualTo: userId)
          .where('orderStatus', isEqualTo: OrderStatus.pending.index)
          .get();
      pendingOrdersCount = result.docs.length;
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> changeOrderStatus({
    required OrderModel order,
    required String shopId,
    required OrderStatus status,
    required BuildContext context,
  }) async {
    emit(OrderChangeOrderStatusLoadingState());
    try {
      log("status: ${status.name}");

      if (status == OrderStatus.rejected) {
        await refundOrder(
          captureId: order
              .paypal['purchase_units'][0]['payments']['captures'][0]['id'],
        );
      } else if (status == OrderStatus.delivered) {
        // 1. Add money to wallet
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uId)
            .collection('wallet')
            .add({
              'amount': order.price,
              'createdAt': Timestamp.now(),
              'title': order.id,
              'shopId': shopId,
            });
      } else if (status.name == OrderStatus.shipped.name) {
        // 2. Decrease quantity for each ordered product
        for (final cartItem in order.products) {
          final productId = cartItem.product.id;
          final orderedQuantity = cartItem.quantity;

          final productRef = FirebaseFirestore.instance
              .collection('products')
              .doc(productId);

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(productRef);

            if (snapshot.exists) {
              final currentQty = snapshot.data()?['quantity'] ?? 0;
              final newQty = currentQty - orderedQuantity;

              transaction.update(productRef, {
                'quantity': newQty < 0 ? 0 : newQty,
              });

              log(
                "Decreased product $productId: ordered $orderedQuantity, from $currentQty → $newQty",
              );
            } else {
              log("⚠️ Product $productId not found in shop $shopId");
            }
          });
        }
      }

      // 3. Update order status
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order.id)
          .update({'orderStatus': status.index});

      // 4. Refresh orders screen
      await ordersScreenInit();

      // 6. Navigate and finish
      if (context.mounted) {
        Navigator.pop(context); // go back to orders screen
        // then optionally refresh orders
        OrderCubit.get(context).ordersScreenInit();
      }

      // 5. Send notification to buyer
      await NotificationCubit.instance.sendNotification(
        title: currentUserModel.username,
        body:
            "${order.products.first.product.title.trim()} order status is ${status.name}",
        userId: order.buyerId,
        notificationType: NotificationTypes.orderStatus,
        payload: jsonEncode({
          'type': NotificationTypes.orderStatus.name,
          'orderModel': order.toMap(),
          'orderStatus': status.index,
        }),
      );

      await NotificationCubit.instance.createNotification(
        receiverId: order.buyerId,
        receiverType: 'user',
        title: currentUserModel.username,
        body:
            "${order.products.first.product.title.trim()} order status is ${status.name}",
        type: NotificationTypes.orderStatus,
        payload: {'orderModel': order.toMap(), 'orderStatus': status.index},
      );
      emit(OrderChangeOrderStatusSuccessState());
    } catch (e) {
      emit(OrderChangeOrderStatusErrorState(e.toString()));
    }
  }

  Future<void> refundOrder({required String captureId}) async {
    emit(OrderRefundOrderLoadingState());
    String url = 'https://paypal-zfje.onrender.com/refund?captureId=$captureId';
    try {
      var response = await Dio().post(url);
      log(response.data.toString());
      emit(OrderRefundOrderSuccessState());
    } catch (e) {
      emit(OrderRefundOrderErrorState(e.toString()));
    }
  }

  Map<String, Map<String, dynamic>> ratingCache = {};
  List<OrderModel> buyerOrders = [];
  Future<void> getBuyerOrders() async {
    buyerOrders = [];
    emit(OrderGetBuyerOrdersLoadingState());
    try {
      var result = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: uId)
          .orderBy('createdAt', descending: true)
          .get();
      for (var element in result.docs) {
        buyerOrders.add(OrderModel.fromJson(element.data(), element.id));
      }
      emit(OrderGetBuyerOrdersSuccessState());
    } catch (e) {
      emit(OrderGetBuyerOrdersErrorState(e.toString()));
    }
  }

  Future<void> getOrderById(String orderId) async {
    emit(OrderGetByIdLoadingState());
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (doc.exists) {
        final order = await compute(parseOrder, {...doc.data()!, "id": doc.id});
        emit(OrderGetByIdSuccessState(order));
      } else {
        emit(OrderGetByIdErrorState("Order not found"));
      }
    } catch (e) {
      emit(OrderGetByIdErrorState(e.toString()));
    }
  }

  Future<void> submitRating({
    required num rating,
    required ProductModel productModel,
    required int index,
    String? comment,
    XFile? imageFile,
    bool updateRated = true,
  }) async {
    try {
      // 1. Update total rating counters on product
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productModel.id)
          .update({
            'numberOfRating': FieldValue.increment(1),
            'sumOfRating': FieldValue.increment(rating),
          });

      // 2. Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('ratings')
            .child(
              '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}',
            );
        await ref.putFile(File(imageFile.path));
        imageUrl = await ref.getDownloadURL();
      }

      // 3. Save rating details in /ratings subcollection
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productModel.id)
          .collection('ratings')
          .add({
            'rating': rating,
            'comment': comment ?? '',
            'image': imageUrl ?? '',
            'userId': uId,
            'createdAt': Timestamp.now(),
          });

      // 4. Mark order as rated (only once)
      if (updateRated) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(buyerOrders[index].id)
            .set({'isRated': true}, SetOptions(merge: true));

        buyerOrders[index].isRated = true;

        // 5. Send notification to buyer
        await NotificationCubit.instance.sendNotification(
          title: "${currentUserModel.username} rated this order with",
          body:
              "$rating ⭐${(comment ?? "").isNotEmpty ? " and commented $comment" : ""}",
          userId: productModel.sellerId,
          notificationType: NotificationTypes.review,
          payload: jsonEncode({
            'type': NotificationTypes.review.name,
            'productModel': productModel,
          }),
        );

        await NotificationCubit.instance.createNotification(
          receiverId: productModel.sellerId,
          receiverType: 'shop',
          title: "${currentUserModel.username} rated this order with",
          body:
              "$rating ⭐${(comment ?? "").isNotEmpty ? " and commented $comment" : ""}",
          type: NotificationTypes.review,
          payload: {'productModel': productModel},
        );

        emit(OrderSubmitRatingSuccessState());
      }
    } catch (e) {
      log(e.toString());
      emit(OrderSubmitRatingErrorState(e.toString()));
    }
  }

  void handleViewOrderProducts(BuildContext context, OrderModel order) {
    if (order.products.length == 1) {
      // Navigate directly to the only product
      navigateTo(
        context: context,
        screen: ProductDetailsScreen(
          productModel: order.products.first.product,
        ),
      );
    } else {
      // Show modal bottom sheet with product list
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: scaffoldColor,
        builder: (context) {
          return SafeArea(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: order.products.length,
              itemBuilder: (context, index) {
                final productItem = order.products[index];
                return ShopProductsCard(
                  productModel: productItem.product,
                  onTap: () {
                    navigateTo(
                      context: context,
                      screen: ProductDetailsScreen(
                        productModel: productItem.product,
                      ),
                    );
                  },
                  deleteButton: null,
                  isSelected: false,
                );
              },
            ),
          );
        },
      );
    }
  }

  void showRatingModal({required BuildContext context, required int index}) {
    final order = OrderCubit.get(context).buyerOrders[index];
    final orderId = order.id;
    final ratingCache = OrderCubit.get(context).ratingCache;

    // Load or initialize cached values
    final cached = ratingCache[orderId];
    final ratings =
        cached?['ratings']?.cast<double>() ??
        List<double>.filled(order.products.length, 0.0);
    final comments =
        cached?['comments']?.cast<String>() ??
        List<String>.filled(order.products.length, '');
    final images =
        cached?['images']?.cast<List<XFile>>() ??
        List<List<XFile>>.generate(order.products.length, (_) => []);

    final ImagePicker picker = ImagePicker();
    final pageController = PageController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: scaffoldColor,
      enableDrag: false,
      isDismissible: false,
      builder: (BuildContext context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setState) {
              // Helper to update cached values
              void updateCache() {
                ratingCache[orderId] = {
                  'ratings': ratings,
                  'comments': comments,
                  'images': images,
                };
              }

              bool allRated = ratings.every((r) => r as double > 0);

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        S.of(context).rate_your_products,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 0.5.sh,
                        child: PageView.builder(
                          controller: pageController,
                          itemCount: order.products.length,
                          itemBuilder: (context, productIndex) {
                            final product = order.products[productIndex];
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Product Info
                                Material(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl:
                                                product.product.images.first,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            progressIndicatorBuilder:
                                                (_, __, progress) =>
                                                    shimmerPlaceholder(
                                                      width: 100,
                                                      height: 100,
                                                      radius: 15,
                                                    ),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.error),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.product.title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                product.product.description,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: textColor,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "${S.of(context).last_order} ${DateFormat("MMMM d, yyy").format(order.createdAt.toDate())}",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Rating Bar
                                RatingBar(
                                  glowColor: primaryColor,
                                  initialRating: ratings[productIndex],
                                  minRating: 1,
                                  allowHalfRating: true,
                                  direction: Axis.horizontal,
                                  itemCount: 5,
                                  ratingWidget: RatingWidget(
                                    full: const Icon(
                                      CupertinoIcons.star_fill,
                                      color: primaryColor,
                                    ),
                                    half: const Icon(
                                      CupertinoIcons.star_lefthalf_fill,
                                      color: primaryColor,
                                    ),
                                    empty: const Icon(
                                      CupertinoIcons.star,
                                      color: primaryColor,
                                    ),
                                  ),
                                  itemPadding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  onRatingUpdate: (rating) {
                                    setState(() {
                                      ratings[productIndex] = rating;
                                      updateCache();
                                    });
                                  },
                                ),

                                const SizedBox(height: 10),

                                // Comment
                                TextFormField(
                                  initialValue: comments[productIndex],
                                  decoration: InputDecoration(
                                    labelText: S.of(context).write_your_review,
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  onChanged: (val) {
                                    setState(() {
                                      comments[productIndex] = val;
                                      updateCache();
                                    });
                                  },
                                ),

                                const SizedBox(height: 10),

                                // Images
                                images[productIndex].isEmpty
                                    ? GestureDetector(
                                        onTap: () async {
                                          final picked =
                                              await showModalBottomSheet<
                                                XFile?
                                              >(
                                                context: context,
                                                builder: (_) => PickImageSource(
                                                  galleryButton: () async {
                                                    final file = await picker
                                                        .pickImage(
                                                          source: ImageSource
                                                              .gallery,
                                                        );
                                                    Navigator.pop(
                                                      context,
                                                      file,
                                                    );
                                                  },
                                                  cameraButton: () async {
                                                    final file = await picker
                                                        .pickImage(
                                                          source: ImageSource
                                                              .camera,
                                                        );
                                                    Navigator.pop(
                                                      context,
                                                      file,
                                                    );
                                                  },
                                                ),
                                              );
                                          if (picked != null) {
                                            setState(() {
                                              images[productIndex].add(picked);
                                              updateCache();
                                            });
                                          }
                                        },
                                        child: Container(
                                          height: 100,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: primaryColor,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              S
                                                  .of(context)
                                                  .upload_optional_image,
                                              style: TextStyle(
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : SizedBox(
                                        height: 100,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                final picked = await showModalBottomSheet<XFile?>(
                                                  context: context,
                                                  builder: (_) => Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      ListTile(
                                                        leading: const Icon(
                                                          Icons.photo,
                                                        ),
                                                        title: Text(
                                                          S
                                                              .of(context)
                                                              .pick_image,
                                                        ),
                                                        onTap: () async {
                                                          final file = await picker
                                                              .pickImage(
                                                                source:
                                                                    ImageSource
                                                                        .gallery,
                                                              );
                                                          Navigator.pop(
                                                            context,
                                                            file,
                                                          );
                                                        },
                                                      ),
                                                      ListTile(
                                                        leading: const Icon(
                                                          Icons.camera_alt,
                                                        ),
                                                        title: Text(
                                                          S
                                                              .of(context)
                                                              .take_photo,
                                                        ),
                                                        onTap: () async {
                                                          final file = await picker
                                                              .pickImage(
                                                                source:
                                                                    ImageSource
                                                                        .camera,
                                                              );
                                                          Navigator.pop(
                                                            context,
                                                            file,
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (picked != null) {
                                                  setState(() {
                                                    images[productIndex].add(
                                                      picked,
                                                    );
                                                    updateCache();
                                                  });
                                                }
                                              },
                                              child: Container(
                                                width: 100,
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: primaryColor,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.add_a_photo,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ...images[productIndex].asMap().entries.map((
                                              entry,
                                            ) {
                                              final img = entry.value;
                                              final imgIndex = entry.key;
                                              return Stack(
                                                children: [
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.only(
                                                          right: 8,
                                                        ),
                                                    width: 100,
                                                    height: 100,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      image: DecorationImage(
                                                        image: FileImage(
                                                          File(img.path),
                                                        ),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          images[productIndex]
                                                              .removeAt(
                                                                imgIndex,
                                                              );
                                                          updateCache();
                                                        });
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        decoration:
                                                            const BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color: Colors
                                                                  .black54,
                                                            ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                              ],
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              allRated ? primaryColor : Colors.grey.shade400,
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              Colors.white,
                            ),
                          ),
                          onPressed: allRated
                              ? () async {
                                  for (
                                    int i = 0;
                                    i < order.products.length;
                                    i++
                                  ) {
                                    final product = order.products[i];
                                    final rating = ratings[i];
                                    final comment = comments[i];
                                    final imageList = images[i];

                                    if (imageList.isEmpty) {
                                      await OrderCubit.get(
                                        context,
                                      ).submitRating(
                                        productModel: product.product,
                                        rating: rating,
                                        index: index,
                                        comment: comment,
                                        imageFile: null,
                                        updateRated:
                                            i == order.products.length - 1,
                                      );
                                    } else {
                                      for (
                                        int j = 0;
                                        j < imageList.length;
                                        j++
                                      ) {
                                        await OrderCubit.get(
                                          context,
                                        ).submitRating(
                                          productModel: product.product,
                                          rating: rating,
                                          index: index,
                                          comment: comment,
                                          imageFile: imageList[j],
                                          updateRated:
                                              i == order.products.length - 1 &&
                                              j == imageList.length - 1,
                                        );
                                      }
                                    }
                                  }

                                  // Clear cache
                                  ratingCache.remove(orderId);
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                }
                              : null,
                          child: Text(
                            S.of(context).submit_all,
                            style: const TextStyle(fontSize: 20.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
