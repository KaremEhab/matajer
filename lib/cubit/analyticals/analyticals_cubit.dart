import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:matajer/cubit/analyticals/analyticals_state.dart';
import 'package:matajer/models/order_model.dart';

class AnalyticalsCubit extends Cubit<AnalyticalsState> {
  AnalyticalsCubit._privateConstructor() : super(AnalyticsInitialState());

  static final AnalyticalsCubit _instance =
      AnalyticalsCubit._privateConstructor();

  factory AnalyticalsCubit() => _instance;

  static AnalyticalsCubit get instance => _instance;

  // ---------------------- SALES, ORDERS & PRODUCT ANALYTICS ----------------------
  Future<void> fetchOrders({
    required String shopId,
    required String timeframe, // "daily", "weekly", "monthly", "yearly"
  }) async {
    emit(AnalyticsLoadingState());

    try {
      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate;

      switch (timeframe) {
        case 'daily':
          startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'weekly':
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = startDate.add(
            const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
          );
          break;
        case 'monthly':
          startDate = DateTime(now.year, now.month, 1);
          int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          endDate = DateTime(now.year, now.month, daysInMonth, 23, 59, 59);
          break;
        case 'yearly':
          startDate = DateTime(now.year, 1, 1);
          endDate = DateTime(now.year, 12, 31, 23, 59, 59);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }

      // ---------------------- Fetch Orders ----------------------
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('shopId', isEqualTo: shopId)
          .where(
            'orderStatus',
            whereIn: [
              OrderStatus.pending.index,
              OrderStatus.accepted.index,
              OrderStatus.rejected.index,
              OrderStatus.shipped.index,
              OrderStatus.delivered.index,
            ],
          )
          .get();

      List<OrderModel> allOrders = snapshot.docs
          .map(
            (doc) =>
                OrderModel.fromJson(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

      List<OrderModel> orders = allOrders.where((order) {
        final date = order.createdAt.toDate();
        return date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endDate.add(const Duration(seconds: 1)));
      }).toList();

      // ---------------------- CALCULATE METRICS ----------------------
      num totalRevenue = 0;
      num totalSales = 0;
      int totalOrders = orders.length;
      num totalQuantitySold = 0;

      Map<String, int> orderStatusCount = {
        'pending': 0,
        'accepted': 0,
        'rejected': 0,
        'shipped': 0,
        'delivered': 0,
      };

      num totalDeliveryTime = 0;
      int deliveredOrdersCount = 0;

      Map<String, num> ordersTrend = {};
      Map<String, num> revenueTrend = {};
      Map<String, num> salesTrend = {};
      Map<String, Map<String, int>> productClicksTrend = {};

      Map<String, int> topProductsMap = {};
      Map<String, num> topBuyersMap = {};
      Map<String, int> buyerOrdersCount = {};
      Map<String, Map<String, dynamic>> buyerMap = {};

      // ✅ Pre-initialize trend maps
      if (timeframe == 'daily') {
        for (int h = 0; h < 24; h++) {
          ordersTrend[h.toString()] = 0;
          revenueTrend[h.toString()] = 0;
          salesTrend[h.toString()] = 0;
        }
      } else if (timeframe == 'weekly') {
        for (int d = 1; d <= 7; d++) {
          ordersTrend[d.toString()] = 0;
          revenueTrend[d.toString()] = 0;
          salesTrend[d.toString()] = 0;
        }
      } else if (timeframe == 'monthly') {
        int days = DateTime(now.year, now.month + 1, 0).day;
        for (int d = 1; d <= days; d++) {
          ordersTrend[d.toString()] = 0;
          revenueTrend[d.toString()] = 0;
          salesTrend[d.toString()] = 0;
        }
      } else if (timeframe == 'yearly') {
        for (int m = 1; m <= 12; m++) {
          ordersTrend[m.toString()] = 0;
          revenueTrend[m.toString()] = 0;
          salesTrend[m.toString()] = 0;
        }
      }

      // ---------------------- Process Orders ----------------------
      for (var order in orders) {
        for (var product in order.products) {
          totalRevenue += product.totalPrice;
        }
        totalSales += order.price;

        String statusKey = order.orderStatus.index == OrderStatus.pending.index
            ? 'pending'
            : order.orderStatus.index == OrderStatus.accepted.index
            ? 'accepted'
            : order.orderStatus.index == OrderStatus.rejected.index
            ? 'rejected'
            : order.orderStatus.index == OrderStatus.shipped.index
            ? 'shipped'
            : 'delivered';

        orderStatusCount[statusKey] = (orderStatusCount[statusKey] ?? 0) + 1;

        if (order.orderStatus.index == OrderStatus.delivered.index) {
          totalDeliveryTime += order.deliveryTime;
          deliveredOrdersCount++;
        }

        DateTime orderDate = order.createdAt.toDate();
        String key = timeframe == 'daily'
            ? orderDate.hour.toString()
            : timeframe == 'weekly'
            ? orderDate.weekday.toString()
            : timeframe == 'monthly'
            ? orderDate.day.toString()
            : orderDate.month.toString();

        ordersTrend[key] = (ordersTrend[key] ?? 0) + 1;
        salesTrend[key] = (salesTrend[key] ?? 0) + order.price;
        for (var product in order.products) {
          revenueTrend[key] = (revenueTrend[key] ?? 0) + product.totalPrice;
        }

        for (var product in order.products) {
          totalQuantitySold += product.quantity;
          topProductsMap[product.product.id] =
              (topProductsMap[product.product.id] ?? 0) + product.quantity;
        }

        // 🟢 Track buyers
        topBuyersMap[order.buyerId] =
            (topBuyersMap[order.buyerId] ?? 0) + order.price;

        buyerOrdersCount[order.buyerId] =
            (buyerOrdersCount[order.buyerId] ?? 0) + 1;

        buyerMap[order.buyerId] = {
          'spent': (buyerMap[order.buyerId]?['spent'] ?? 0) + order.price,
          'ordersCount': (buyerMap[order.buyerId]?['ordersCount'] ?? 0) + 1,
        };
      }

      num avgDeliveryTime = deliveredOrdersCount > 0
          ? totalDeliveryTime / deliveredOrdersCount
          : 0;

      // ---------------------- CALCULATE REPEATED CUSTOMERS ----------------------
      int totalRepeatedCustomers = buyerOrdersCount.values
          .where((count) => count > 1)
          .length;

      // ---------------------- CALCULATE TOTAL SHOP FAVOURITES ----------------------
      final shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .get();

      int totalShopFavourites = 0;
      if (shopDoc.exists) {
        final data = shopDoc.data()!;
        totalShopFavourites =
            (data['usersSetAsFavorite'] as List?)?.length ?? 0;
      }

      // ---------------------- FETCH PRODUCT CLICKS ----------------------
      int totalProductClicks = 0;

      QuerySnapshot clicksSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('shopId', isEqualTo: shopId)
          .get();

      for (var doc in clicksSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final productTitle = data['title'] ?? 'Unknown';

        if (data['clickEvents'] != null) {
          List events = data['clickEvents'] as List;
          for (var event in events) {
            final ts = (event['timestamp'] as Timestamp).toDate();
            if (ts.isAfter(startDate) && ts.isBefore(endDate)) {
              totalProductClicks++;

              String key;
              if (timeframe == 'daily') {
                key = DateFormat('hh:mm a').format(ts);
              } else if (timeframe == 'weekly') {
                key = DateFormat('EEE').format(ts);
              } else if (timeframe == 'monthly') {
                key = DateFormat('d').format(ts);
              } else {
                key = DateFormat('MMM').format(ts);
              }

              if (!productClicksTrend.containsKey(productTitle)) {
                productClicksTrend[productTitle] = {};
              }
              productClicksTrend[productTitle]![key] =
                  (productClicksTrend[productTitle]![key] ?? 0) + 1;
            }
          }
        }
      }

      // ---------------------- BATCH FETCH USERS ----------------------
      final buyerIds = buyerMap.keys.toList();
      List<Map<String, dynamic>> buyersList = [];
      if (buyerIds.isNotEmpty) {
        QuerySnapshot buyersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: buyerIds)
            .get();

        Map<String, Map<String, dynamic>> usersMap = {
          for (var doc in buyersSnapshot.docs)
            doc.id: doc.data() as Map<String, dynamic>,
        };

        buyersList = buyerMap.entries
            .map((entry) {
              final data = usersMap[entry.key];
              if (data != null) {
                return {
                  'id': entry.key,
                  'name': data['username'] ?? 'Unknown',
                  'image': data['profilePicture'] ?? '',
                  'phone': data['phoneNumber'] ?? '',
                  'gender': data['gender'] ?? 'other',
                  'totalSpent': entry.value['spent'],
                  'ordersCount': entry.value['ordersCount'],
                };
              }
              return null;
            })
            .whereType<Map<String, dynamic>>()
            .toList();

        buyersList.sort(
          (a, b) => (b['totalSpent'] as num).compareTo(a['totalSpent'] as num),
        );
      }

      // ---------------------- RESOLVE TOP PRODUCTS ----------------------
      List<Map<String, dynamic>> topProductsList = [];
      if (topProductsMap.isNotEmpty) {
        final productIds = topProductsMap.keys.toList();

        QuerySnapshot productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: productIds)
            .get();

        Map<String, Map<String, dynamic>> productsMap = {
          for (var doc in productsSnapshot.docs)
            doc.id: doc.data() as Map<String, dynamic>,
        };

        topProductsList = topProductsMap.entries
            .map((entry) {
              final data = productsMap[entry.key];
              if (data != null) {
                return {
                  'id': entry.key,
                  'title': data['title'] ?? 'Unknown',
                  'image': (data['images'] as List?)?.first ?? '',
                  'quantitySold': entry.value,
                };
              }
              return null;
            })
            .whereType<Map<String, dynamic>>()
            .toList();

        topProductsList.sort(
          (a, b) =>
              (b['quantitySold'] as int).compareTo(a['quantitySold'] as int),
        );
      }

      // ---------------------- GENDER DISTRIBUTION ----------------------
      Map<String, int> genderDistribution = {
        'male': 0,
        'female': 0,
        'other': 0,
      };

      for (var buyer in buyersList) {
        final gender = (buyer['gender'] ?? 'other').toLowerCase();
        if (genderDistribution.containsKey(gender)) {
          genderDistribution[gender] = genderDistribution[gender]! + 1;
        } else {
          genderDistribution['other'] = genderDistribution['other']! + 1;
        }
      }

      // ---------------------- EMIT STATE ----------------------
      emit(
        AnalyticsLoadedState(
          totalRevenue: totalRevenue,
          totalSales: totalSales,
          totalOrders: totalOrders,
          totalQuantitySold: totalQuantitySold,
          orderStatusCount: orderStatusCount,
          avgDeliveryTime: avgDeliveryTime,
          orders: orders,
          ordersTrend: ordersTrend,
          revenueTrend: revenueTrend,
          salesTrend: salesTrend,
          topProductsResolved: topProductsList,
          topBuyersResolved: buyersList,
          totalProductClicks: totalProductClicks,
          productClicksTrend: productClicksTrend,
          genderDistribution: genderDistribution,
          totalRepeatedCustomers: totalRepeatedCustomers,
          totalShopFavourites: totalShopFavourites,
        ),
      );
    } catch (e) {
      emit(AnalyticsErrorState(error: e.toString()));
    }
  }
}
