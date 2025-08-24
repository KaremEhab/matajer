import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/analytics/analytics_state.dart';
import 'package:matajer/models/order_model.dart';
import 'package:matajer/models/product_analysis_model.dart';
import 'package:matajer/models/product_model.dart';

class AnalyticsCubit extends Cubit<AnalyticsState> {
  AnalyticsCubit() : super(AnalyticsInitialState());

  static AnalyticsCubit get(context) => BlocProvider.of(context);

  num totalSales = 0;
  num totalOrders = 0;

  List<String> buyersIds = [];
  num totalBuyers = 0;
  num repeatBuyers = 0;

  List<ProductAnalysisModel> products = [];

  Map<String, double> dailySales = {'1': 0, '2': 0, '3': 0, '4': 0};

  Future<num> getProductClicks(String productId) async {
    try {
      var result =
          await FirebaseFirestore.instance
              .collection('products')
              .doc(productId)
              .get();
      return result['clicks'];
    } catch (e) {
      log(e.toString());
      return 0;
    }
  }

  Future<void> getDailySales() async {
    emit(AnalyticsGetAnnuallySalesLoadingState());

    try {
      // Reset
      totalOrders = 0;
      totalSales = 0;
      productTotalClicks = 0;
      products = [];
      totalBuyers = 0;
      repeatBuyers = 0;
      dailySales = {};

      DateTime now = DateTime.now();
      DateTime startOfYear = DateTime(now.year);

      /// Step 1: Get all products for this shop
      var productsSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('shopId', isEqualTo: currentShopModel!.shopId)
              .get();

      List<ProductModel> shopProducts =
          productsSnapshot.docs
              .map((doc) => ProductModel.fromJson(doc.data()))
              .toList();

      /// Step 2: Get all orders for current year
      var ordersSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
              )
              .where('sellerId', isEqualTo: currentShopModel!.sellerId)
              .where('orderStatus', isEqualTo: OrderStatus.delivered.index)
              .get();

      Set<String> buyers = {};
      Map<String, int> buyerFrequency = {};

      for (var product in shopProducts) {
        int ordersCount = 0;
        num productSales = 0;

        for (var orderDoc in ordersSnapshot.docs) {
          final data = orderDoc.data();
          final buyerId = data['buyerId'];
          final orderDate = (data['createdAt'] as Timestamp).toDate();
          final dayString = DateFormat('yyyy-MM-dd').format(orderDate);

          final orderProducts = List<Map<String, dynamic>>.from(
            data['products'],
          );

          for (var item in orderProducts) {
            final productData = item['product'];
            final quantity = item['quantity'] ?? 1;

            if (productData['id'] == product.id) {
              final price = item['totalPrice'] ?? 0;

              // Count sale
              ordersCount += 1;
              productSales += price * quantity;

              // Daily breakdown
              dailySales[dayString] =
                  (dailySales[dayString] ?? 0) + (price * quantity);

              // Track buyer
              buyers.add(buyerId);
              buyerFrequency[buyerId] = (buyerFrequency[buyerId] ?? 0) + 1;
            }
          }
        }

        totalOrders += ordersCount;
        totalSales += productSales;
        productTotalClicks += product.clicks;

        if (ordersCount > 0 || product.clicks > 0) {
          products.add(
            ProductAnalysisModel(
              name: product.title,
              image: product.images.isNotEmpty ? product.images.first : '',
              sellerName: product.shopName,
              id: product.id,
              orders: ordersCount,
              sales: productSales,
              clicks: product.clicks,
            ),
          );
        }
      }

      totalBuyers = buyers.length;
      repeatBuyers = buyerFrequency.values.where((count) => count > 1).length;

      emit(AnalyticsGetAnnuallySalesSuccessState());
    } catch (e, st) {
      emit(AnalyticsGetAnnuallySalesErrorState(e.toString()));
      debugPrintStack(stackTrace: st);
    }
  }

  Map<String, double> weeklySales = {
    'Monday': 0,
    'Tuesday': 0,
    'Wednesday': 0,
    'Thursday': 0,
    'Friday': 0,
    'Saturday': 0,
    'Sunday': 0,
  };

  Future<void> getWeeklySales() async {
    emit(AnalyticsGetWeeklySalesLoadingState());
    debugPrint('🟡 Start getWeeklySales');

    try {
      // Reset
      totalOrders = 0;
      totalSales = 0;
      productTotalClicks = 0;
      products = [];
      totalBuyers = 0;
      repeatBuyers = 0;
      buyersIds = [];
      weeklySales.updateAll((key, value) => 0);

      DateTime weekStart = DateTime.now().subtract(const Duration(days: 7));

      /// Step 1: Get all products for this shop
      var productsSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('shopId', isEqualTo: currentShopModel!.shopId)
              .get();

      List<ProductModel> shopProducts =
          productsSnapshot.docs
              .map((doc) => ProductModel.fromJson(doc.data()))
              .toList();

      debugPrint('✅ Loaded ${shopProducts.length} products');

      debugPrint('📆 Week Start: $weekStart');
      debugPrint('🔍 sellerId to match: ${currentShopModel!.sellerId}');
      debugPrint(
        '📦 OrderStatus index (delivered): ${OrderStatus.delivered.index}',
      );

      /// Step 2: Get all delivered orders for the last 7 days
      var ordersSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart),
              )
              .where('sellerId', isEqualTo: currentShopModel!.sellerId)
              .where('orderStatus', isEqualTo: OrderStatus.delivered.index)
              .get();

      debugPrint('✅ Loaded ${ordersSnapshot.docs.length} orders');

      var allOrders =
          await FirebaseFirestore.instance.collection('orders').limit(5).get();

      debugPrint('🧾 Sample Order Data:');
      for (var order in allOrders.docs) {
        log(order.data().toString());
      }

      Set<String> buyers = {};
      Map<String, int> buyerFrequency = {};

      for (var product in shopProducts) {
        int ordersCount = 0;
        num productSales = 0;

        debugPrint('🟠 Analyzing product: ${product.title} (${product.id})');

        for (var orderDoc in ordersSnapshot.docs) {
          final data = orderDoc.data();
          final buyerId = data['buyerId'];
          final orderDate = (data['createdAt'] as Timestamp).toDate();
          final weekday = DateFormat('EEEE').format(orderDate);

          final orderProducts = List<Map<String, dynamic>>.from(
            data['products'],
          );

          for (var item in orderProducts) {
            final productData = item['product'];
            final productId = productData['id'];
            final quantity = item['quantity'] ?? 1;
            final price = item['totalPrice'] ?? 0;

            debugPrint(
              '🔍 Order Product ID: $productId | Target: ${product.id}',
            );

            if (productId == product.id) {
              final total = price * quantity;
              ordersCount++;
              productSales += total;

              weeklySales[weekday] = (weeklySales[weekday] ?? 0) + total;

              buyers.add(buyerId);
              buyerFrequency[buyerId] = (buyerFrequency[buyerId] ?? 0) + 1;

              debugPrint(
                '✅ Match! Added $quantity orders - total: $total to $weekday',
              );
            }
          }
        }

        debugPrint(
          '📦 Product [${product.title}] => Orders: $ordersCount | Sales: $productSales',
        );

        totalOrders += ordersCount;
        totalSales += productSales;
        productTotalClicks += product.clicks;

        if (ordersCount > 0 || product.clicks > 0) {
          products.add(
            ProductAnalysisModel(
              name: product.title,
              image: product.images.isNotEmpty ? product.images.first : '',
              sellerName: product.shopName,
              id: product.id,
              orders: ordersCount,
              sales: productSales,
              clicks: product.clicks,
            ),
          );
        }
      }

      totalBuyers = buyers.length;
      repeatBuyers = buyerFrequency.values.where((count) => count > 1).length;

      debugPrint('✅ Finished analyzing.');
      debugPrint('📊 Total Orders: $totalOrders');
      debugPrint('💰 Total Sales: $totalSales');
      debugPrint('👥 Total Buyers: $totalBuyers');
      debugPrint('🔁 Repeat Buyers: $repeatBuyers');
      debugPrint('📈 Weekly Sales: $weeklySales');

      emit(AnalyticsGetWeeklySalesSuccessState());
    } catch (e, st) {
      emit(AnalyticsGetWeeklySalesErrorState(e.toString()));
      debugPrint('❌ Error in getWeeklySales: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Map<String, double> monthlySales = {
    'January': 0,
    'February': 0,
    'March': 0,
    'April': 0,
    'May': 0,
    'June': 0,
    'July': 0,
    'August': 0,
    'September': 0,
    'October': 0,
    'November': 0,
    'December': 0,
  };

  Future<void> getMonthlySales() async {
    emit(AnalyticsGetMonthlySalesLoadingState());

    try {
      // Reset
      totalOrders = 0;
      totalSales = 0;
      productTotalClicks = 0;
      products = [];
      totalBuyers = 0;
      repeatBuyers = 0;
      buyersIds = [];
      monthlySales.updateAll((key, value) => 0); // reset all months to 0

      DateTime now = DateTime.now();
      DateTime startOfYear = DateTime(now.year);

      /// Step 1: Get all products for this shop
      // var productsSnapshot =
      //     await FirebaseFirestore.instance
      //         .collection('products')
      //         .where('shopId', isEqualTo: currentShopModel!.shopId)
      //         .get();

      // List<ProductModel> shopProducts =
      //     productsSnapshot.docs
      //         .map((doc) => ProductModel.fromJson(doc.data()))
      //         .toList();

      /// Step 2: Get all delivered orders for this year
      var ordersSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
              )
              .where('sellerId', isEqualTo: currentShopModel!.sellerId)
              .where('orderStatus', isEqualTo: OrderStatus.delivered.index)
              .get();

      Set<String> buyers = {};
      Map<String, int> buyerFrequency = {};

      for (var orderDoc in ordersSnapshot.docs) {
        final data = orderDoc.data();
        final buyerId = data['buyerId'];
        final orderDate = (data['createdAt'] as Timestamp).toDate();
        final month = DateFormat('MMMM').format(orderDate); // e.g. March

        final orderProducts = List<Map<String, dynamic>>.from(data['products']);

        double orderTotal = 0;

        for (var item in orderProducts) {
          final productData = item['product'];
          final quantity = item['quantity'] ?? 1;
          final price = item['totalPrice'] ?? 0;
          final productId = productData['id'];

          orderTotal += price * quantity;

          // Add to products
          int index = products.indexWhere((p) => p.id == productId);
          if (index == -1) {
            num clicks = await getProductClicks(productId);
            products.add(
              ProductAnalysisModel(
                name: productData['title'] ?? 'Unnamed',
                image: (productData['images'] as List?)?.first ?? '',
                sellerName: currentShopModel!.shopName,
                id: productId,
                orders: quantity,
                sales: price * quantity,
                clicks: clicks,
              ),
            );
          } else {
            products[index].orders += quantity;
            products[index].sales += price * quantity;
          }
        }

        totalOrders++;
        totalSales += orderTotal;

        if (monthlySales.containsKey(month)) {
          monthlySales[month] = (monthlySales[month] ?? 0) + orderTotal;
        }

        if (!buyersIds.contains(buyerId)) {
          buyersIds.add(buyerId);
          totalBuyers++;
        } else {
          repeatBuyers++;
        }

        buyers.add(buyerId);
        buyerFrequency[buyerId] = (buyerFrequency[buyerId] ?? 0) + 1;
      }

      productTotalClicks = products.fold(
        0,
        (sum, product) => sum + (product.clicks),
      );

      emit(AnalyticsGetMonthlySalesSuccessState());
    } catch (e, st) {
      emit(AnalyticsGetMonthlySalesErrorState(e.toString()));
      debugPrintStack(stackTrace: st);
    }
  }

  // Future<void> getAnnuallySalese() async {
  //   totalOrders = 0;
  //   totalSales = 0;
  //   buyersIds = [];
  //   products = [];
  //   totalBuyers = 0;
  //   repeatBuyers = 0;
  //   annuallySales = {};
  //
  //   emit(AnalyticsGetAnnuallySalesLoadingState());
  //
  //   try {
  //     var result =
  //         await FirebaseFirestore.instance
  //             .collection('orders')
  //             .where('sellerId', isEqualTo: currentShopModel!.shopId)
  //             .where('orderStatus', isEqualTo: OrderStatus.delivered.index)
  //             .where(
  //               'createdAt',
  //               isGreaterThanOrEqualTo: DateTime.now().subtract(
  //                 const Duration(days: 365),
  //               ),
  //             )
  //             .get();
  //
  //     for (var element in result.docs) {
  //       totalOrders++;
  //       totalSales += element['price'];
  //
  //       if (!buyersIds.contains(element['buyerId'])) {
  //         buyersIds.add(element['buyerId']);
  //         totalBuyers++;
  //       } else {
  //         repeatBuyers++;
  //       }
  //
  //       for (var product in element['products']) {
  //         final String? productId = product['productId'];
  //
  //         if (productId == null) {
  //           log('❌ Skipping product: missing productId. Data: $product');
  //           continue;
  //         }
  //
  //         var index = products.indexWhere((e) => e.id == productId);
  //
  //         if (index == -1) {
  //           num clicks = await getProductClicks(productId);
  //           products.add(
  //             ProductAnalysisModel(
  //               id: productId,
  //               name: product['productName'] ?? 'Unnamed Product',
  //               sellerName: product['sellerName'] ?? '',
  //               image: product['imageUrl'] ?? '',
  //               orders: product['quantity'] ?? 0,
  //               sales: product['price'] ?? 0,
  //               clicks: clicks,
  //             ),
  //           );
  //         } else {
  //           products[index].orders += product['quantity'] ?? 0;
  //           products[index].sales += product['price'] ?? 0;
  //         }
  //       }
  //
  //       var year = element['createdAt'].toDate().year;
  //       double price = element['price'].toDouble();
  //
  //       annuallySales.update(
  //         year.toString(),
  //         (value) => value + price,
  //         ifAbsent: () => price,
  //       );
  //     }
  //
  //     emit(AnalyticsGetAnnuallySalesSuccessState());
  //   } catch (e) {
  //     log('❌ getAnnuallySales error: $e');
  //     emit(AnalyticsGetAnnuallySalesErrorState(e.toString()));
  //   }
  // }

  num productTotalClicks = 0;
  Map<String, double> annuallySales = {};
  Future<void> getAnnuallySales() async {
    emit(AnalyticsGetAnnuallySalesLoadingState());

    try {
      // Reset
      totalOrders = 0;
      totalSales = 0;
      productTotalClicks = 0;
      products = [];
      totalBuyers = 0;
      repeatBuyers = 0;
      annuallySales = {};

      DateTime now = DateTime.now();
      DateTime startOfYear = DateTime(now.year);

      /// Step 1: Get all products for this shop
      var productsSnapshot =
          await FirebaseFirestore.instance
              .collection('products')
              .where('shopId', isEqualTo: currentShopModel!.shopId)
              .get();

      List<ProductModel> shopProducts =
          productsSnapshot.docs
              .map((doc) => ProductModel.fromJson(doc.data()))
              .toList();

      /// Step 2: Get all orders for current year (that belong to the shop)
      var ordersSnapshot =
          await FirebaseFirestore.instance
              .collection('orders')
              .where(
                'createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
              )
              .where('sellerId', isEqualTo: currentShopModel!.sellerId)
              .where('orderStatus', isEqualTo: OrderStatus.delivered.index)
              .get();

      Set<String> buyers = {};
      Map<String, int> buyerFrequency = {};

      for (var product in shopProducts) {
        int ordersCount = 0;
        num productSales = 0;

        for (var orderDoc in ordersSnapshot.docs) {
          final data = orderDoc.data();
          // final orderId = orderDoc.id;
          final buyerId = data['buyerId'];
          final orderDate = (data['createdAt'] as Timestamp).toDate();

          final orderProducts = List<Map<String, dynamic>>.from(
            data['products'],
          );

          for (var item in orderProducts) {
            final productData = item['product'];
            final quantity = item['quantity'] ?? 1;

            if (productData['id'] == product.id) {
              final price = item['totalPrice'] ?? 0;

              // Count sale
              ordersCount += 1;
              productSales += price * quantity;

              // Monthly breakdown
              String month = _getMonthName(orderDate.month);
              annuallySales[month] =
                  (annuallySales[month] ?? 0) + (price * quantity);

              // Track buyer
              buyers.add(buyerId);
              buyerFrequency[buyerId] = (buyerFrequency[buyerId] ?? 0) + 1;
            }
          }
        }

        totalOrders += ordersCount;
        totalSales += productSales;
        productTotalClicks += product.clicks;

        if (ordersCount > 0 || product.clicks > 0) {
          products.add(
            ProductAnalysisModel(
              name: product.title,
              image: product.images.isNotEmpty ? product.images.first : '',
              sellerName: product.shopName,
              id: product.id,
              orders: ordersCount,
              sales: productSales,
              clicks: product.clicks,
            ),
          );
        }
      }

      totalBuyers = buyers.length;
      repeatBuyers = buyerFrequency.values.where((count) => count > 1).length;

      emit(AnalyticsGetAnnuallySalesSuccessState());
    } catch (e, st) {
      emit(AnalyticsGetAnnuallySalesErrorState(e.toString()));
      debugPrintStack(stackTrace: st);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  // List<ProductModel> products = [];
  // Future<void> getProducts() async {
  //   emit(AnalyticsGetProductsLoadingState());
  //   try {
  //     var result = await FirebaseFirestore.instance
  //         .collection('products')
  //         .where('sellerId', isEqualTo: uId)
  //         .get();
  //     products =
  //         result.docs.map((e) => ProductModel.fromJson(e.data())).toList();
  //     emit(AnalyticsGetProductsSuccessState());
  //   } catch (e) {
  //     emit(AnalyticsGetProductsErrorState(e.toString()));
  //   }
  // }
  //
  // List<OrderModel> orders = [];
  // Future<void> getOrders() async {
  //   emit(AnalyticsGetOrdersLoadingState());
  //   try {
  //     var result = await FirebaseFirestore.instance
  //         .collection('orders')
  //         .where('sellerId', isEqualTo: uId)
  //         .get();
  //     orders =
  //         result.docs.map((e) => OrderModel.fromJson(e.data(), e.id)).toList();
  //     emit(AnalyticsGetOrdersSuccessState());
  //   } catch (e) {
  //     emit(AnalyticsGetOrdersErrorState(e.toString()));
  //   }
  // }
}
