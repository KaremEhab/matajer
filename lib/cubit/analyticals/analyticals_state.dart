import 'package:matajer/models/order_model.dart';

abstract class AnalyticalsState {}

class AnalyticsInitialState extends AnalyticalsState {}

class AnalyticsLoadingState extends AnalyticalsState {}

class AnalyticsLoadedState extends AnalyticalsState {
  final num totalRevenue;
  final num totalSales;
  final int totalOrders;
  final num totalQuantitySold;
  final Map<String, int> orderStatusCount;
  final num avgDeliveryTime;
  final List<OrderModel> orders;
  final Map<String, num> ordersTrend;
  final Map<String, num> revenueTrend;
  final Map<String, num> salesTrend;
  final List<Map<String, dynamic>> topProductsResolved;
  final List<Map<String, dynamic>> topBuyersResolved;
  final int totalProductClicks;
  final Map<String, Map<String, int>> productClicksTrend;
  final Map<String, int> genderDistribution;

  // ✅ NEW FIELDS
  final int totalRepeatedCustomers;
  final int totalShopFavourites;

  AnalyticsLoadedState({
    required this.totalRevenue,
    required this.totalSales,
    required this.totalOrders,
    required this.totalQuantitySold,
    required this.orderStatusCount,
    required this.avgDeliveryTime,
    required this.orders,
    required this.ordersTrend,
    required this.revenueTrend,
    required this.salesTrend,
    required this.topProductsResolved,
    required this.topBuyersResolved,
    required this.totalProductClicks,
    required this.productClicksTrend,
    required this.genderDistribution,
    required this.totalRepeatedCustomers,
    required this.totalShopFavourites,
  });
}

class AnalyticsErrorState extends AnalyticalsState {
  final String error;

  AnalyticsErrorState({required this.error});
}
