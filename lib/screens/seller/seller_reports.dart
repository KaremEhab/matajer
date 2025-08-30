import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:matajer/constants/colors.dart';
import 'package:matajer/constants/functions.dart';
import 'package:matajer/constants/vars.dart';
import 'package:matajer/cubit/analyticals/analyticals_cubit.dart';
import 'package:matajer/cubit/analyticals/analyticals_state.dart';
import 'package:matajer/generated/l10n.dart';
import 'package:matajer/models/order_model.dart';

class Reports extends StatefulWidget {
  final String shopId;
  const Reports({super.key, required this.shopId});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  String selectedTimeframe = 'daily';
  String? selectedProduct;
  int? touchedIndex;
  late double overlayTop;
  Map<String, int> ordersByGender = {'male': 0, 'female': 0, 'other': 0};
  Map<String, double> totalSalesByGender = {'male': 0, 'female': 0, 'other': 0};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    AnalyticalsCubit.instance.fetchOrders(
      shopId: widget.shopId,
      timeframe: selectedTimeframe,
    );
  }

  void _onTimeframeChanged(String timeframe) {
    setState(() => selectedTimeframe = timeframe);
    _fetchData();
  }

  String _getTranslatedTimeframe(String timeframe) {
    switch (timeframe) {
      case 'daily':
        return S.current.daily;
      case 'weekly':
        return S.current.weekly;
      case 'monthly':
        return S.current.monthly;
      case 'yearly':
        return S.current.yearly;
      default:
        return timeframe;
    }
  }

  String formatDate(DateTime date, String timeframe) {
    switch (timeframe) {
      case 'daily':
        return DateFormat('EEEE, y').format(date); // Saturday
      case 'weekly':
        return DateFormat('d MMM, y').format(date); // 23 Aug, 2025
      case 'monthly':
        return DateFormat('MMMM, y').format(date); // August, 2025
      case 'yearly':
        return DateFormat('y').format(date); // 2025
      default:
        return DateFormat('d MMM, y').format(date); // fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return BlocBuilder<AnalyticalsCubit, AnalyticalsState>(
      bloc: AnalyticalsCubit.instance,
      builder: (context, state) {
        if (state is AnalyticsLoadedState) {
          // 👇 Ensure default selection (first product)
          if (selectedProduct == null && state.productClicksTrend.isNotEmpty) {
            selectedProduct = state.productClicksTrend.keys.first;
          }

          ordersByGender = {'male': 0, 'female': 0, 'other': 0};
          totalSalesByGender = {'male': 0, 'female': 0, 'other': 0};

          for (var buyer in state.topBuyersResolved) {
            final gender = (buyer['gender'] ?? 'other').toLowerCase();
            ordersByGender[gender] =
                (ordersByGender[gender] ?? 0) + (buyer['ordersCount'] as int);
            totalSalesByGender[gender] =
                (totalSalesByGender[gender] ?? 0) +
                (buyer['totalSpent'] as double);
          }
        }

        if (state is AnalyticsLoadingState) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AnalyticsErrorState) {
          return Scaffold(body: Center(child: Text('Error: ${state.error}')));
        }

        if (state is AnalyticsLoadedState) {
          return Scaffold(
            appBar: AppBar(
              forceMaterialTransparency: true,
              automaticallyImplyLeading: false,
              leadingWidth: 50,
              toolbarHeight: 65,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).analytics,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    formatDate(DateTime.now(), selectedTimeframe),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: _onTimeframeChanged,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'daily',
                      child: Text(
                        S.current.daily,
                        style: TextStyle(
                          color: selectedTimeframe == 'daily'
                              ? primaryColor
                              : textColor,
                          fontWeight: selectedTimeframe == 'daily'
                              ? FontWeight.w900
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'weekly',
                      child: Text(
                        S.current.weekly,
                        style: TextStyle(
                          color: selectedTimeframe == 'weekly'
                              ? primaryColor
                              : textColor,
                          fontWeight: selectedTimeframe == 'weekly'
                              ? FontWeight.w900
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'monthly',
                      child: Text(
                        S.current.monthly,
                        style: TextStyle(
                          color: selectedTimeframe == 'monthly'
                              ? primaryColor
                              : textColor,
                          fontWeight: selectedTimeframe == 'monthly'
                              ? FontWeight.w900
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'yearly',
                      child: Text(
                        S.current.yearly,
                        style: TextStyle(
                          color: selectedTimeframe == 'yearly'
                              ? primaryColor
                              : textColor,
                          fontWeight: selectedTimeframe == 'yearly'
                              ? FontWeight.w900
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  icon: Row(
                    spacing: 5,
                    children: [
                      Text(
                        _getTranslatedTimeframe(
                          lang == 'en'
                              ? selectedTimeframe.toUpperCase()
                              : selectedTimeframe,
                        ),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      Icon(Icons.arrow_circle_down),
                    ],
                  ),
                  iconColor: primaryColor,
                ),
              ],
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ------------------- METRICS CARDS -------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _metricCard(
                            title: S.current.total_sales,
                            value: formatNumberWithCommas(
                              state.totalSales.toDouble(),
                            ),
                            color: primaryColor,
                            width: (width - 24) / 2,
                            fontSize: state.totalSales > 1000000 ? 18 : 20,
                          ),
                          _metricCard(
                            title: S.current.total_quantity_sold,
                            value: '${state.totalQuantitySold}',
                            color: primaryColor,
                            width: (width - 24) / 2,
                          ),
                          _metricCard(
                            title: S.current.avg_time,
                            value:
                                '${state.avgDeliveryTime.toInt()} ${S.of(context).days}',
                            color: primaryColor,
                            width: (width - 24) / 2,
                          ),
                          _metricCard(
                            title: S.current.total_orders,
                            value: '${state.totalOrders}',
                            color: primaryColor,
                            width: (width - 24) / 2,
                          ),
                          _metricCard(
                            title: S.current.product_clicks,
                            value: '${state.totalProductClicks}',
                            color: primaryColor,
                            width: (width - 24) / 2,
                          ),
                          _metricCard(
                            title: S.current.total_revenue,
                            value:
                                "AED ${formatNumberWithCommas(state.totalRevenue.toDouble())}",
                            color: primaryColor,
                            width: (width - 24) / 2,
                            fontSize: state.totalRevenue > 1000000 ? 18 : 20,
                            // width: double.infinity,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ------------------- ORDERS TREND -------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        S.current.orders_trend,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: EdgeInsetsGeometry.directional(end: 17),
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: state.ordersTrend.entries
                                    .map(
                                      (e) => FlSpot(
                                        double.parse(e.key),
                                        e.value.toDouble(),
                                      ),
                                    )
                                    .toList(),
                                isCurved: true,
                                barWidth: 3,
                                color: primaryColor,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: selectedTimeframe == 'yearly'
                                      ? 2
                                      : 1,
                                  getTitlesWidget: (value, meta) =>
                                      SideTitleWidget(
                                        meta: meta,
                                        child: Text(
                                          meta.formattedValue,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  interval: selectedTimeframe == 'daily'
                                      ? 3
                                      : selectedTimeframe == 'weekly' ||
                                            selectedTimeframe == 'yearly'
                                      ? 1
                                      : 4,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),

                            // ---------- Add this ----------
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                // getTooltipColor:
                                //     Colors.black87, // background of tooltip
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      '${spot.y.toInt()} ${spot.y > 1 ? S.of(context).orders : S.of(context).order}', // tooltip text
                                      const TextStyle(
                                        color: Colors.white, // text color
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ------------------- SALES TREND -------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        S.current.sales_trend,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: EdgeInsetsGeometry.directional(end: 17),
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: state.salesTrend.entries
                                    .map(
                                      (e) => FlSpot(
                                        double.parse(e.key),
                                        e.value.toDouble(),
                                      ),
                                    )
                                    .toList(),
                                isCurved: true,
                                barWidth: 3,
                                color: primaryColor,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  interval: selectedTimeframe == 'daily'
                                      ? 3
                                      : selectedTimeframe == 'weekly' ||
                                            selectedTimeframe == 'yearly'
                                      ? 1
                                      : 4,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),

                            // ---------- Add tooltip customization ----------
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                // tooltipBgColor: Colors.black87, // background of tooltip
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      'AED ${formatNumberWithCommas(spot.y)}', // tooltip text
                                      const TextStyle(
                                        color: Colors.white, // text color
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ------------------- REVENUE TREND -------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        S.current.revenue_trend,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: EdgeInsetsGeometry.directional(end: 17),
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: state.revenueTrend.entries
                                    .map(
                                      (e) => FlSpot(
                                        double.parse(e.key),
                                        e.value.toDouble(),
                                      ),
                                    )
                                    .toList(),
                                isCurved: true,
                                barWidth: 3,
                                color: primaryColor,
                                dotData: FlDotData(show: false),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) => Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  interval: selectedTimeframe == 'daily'
                                      ? 3
                                      : selectedTimeframe == 'weekly' ||
                                            selectedTimeframe == 'yearly'
                                      ? 1
                                      : 4,
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),

                            // ---------- Add tooltip customization ----------
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                // tooltipBgColor: Colors.black87, // background of tooltip
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      'AED ${formatNumberWithCommas(spot.y)}', // tooltip text
                                      const TextStyle(
                                        color: Colors.white, // text color
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ------------------- TOP PRODUCTS -------------------
                    if (state.totalOrders > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Text(
                          S.current.top_selling_products,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (state.totalOrders > 0)
                      TopProductsBarChart(
                        data: state.topProductsResolved,
                        barColor: primaryColor,
                      ),
                    if (state.totalOrders > 0) const SizedBox(height: 24),

                    // ------------------- PRODUCT CLICKS -------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Text(
                                  S.current.product_clicks,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 160, // or a max width like 200
                            child: DropdownButtonFormField<String>(
                              value: selectedProduct,
                              borderRadius: BorderRadius.circular(15),
                              isExpanded: true, // ✅ crucial
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: formFieldColor.withOpacity(0.4),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: state.productClicksTrend.keys.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: selectedProduct == p
                                          ? FontWeight.w900
                                          : FontWeight.w500,
                                      color: selectedProduct == p
                                          ? primaryColor
                                          : textColor,
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // ✅ truncate long names
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedProduct = value;
                                });
                              },
                              icon: const Icon(
                                Icons.arrow_circle_down_rounded,
                                color: primaryColor,
                              ),
                              dropdownColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ProductClicksTrendChart(
                      trendData: state.productClicksTrend,
                      timeframe: selectedTimeframe,
                      selectedProduct: selectedProduct, // 👈 pass here
                    ),
                    const SizedBox(height: 24),

                    // ------------------- ORDER STATUS -------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Text(
                        S.current.orders_by_status,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: state.orderStatusCount.entries
                            .toList()
                            .asMap()
                            .entries
                            .map((entry) {
                              final index = entry.key;
                              final e = entry.value;
                              final isLastTwo =
                                  index >= state.orderStatusCount.length - 2;
                              return _metricCard(
                                value:
                                    '${getTranslatedOrderStatus(context, OrderStatusParser.fromString(e.key)!)}: ${e.value}',
                                color: getStatusTextColor(
                                  OrderStatusParser.fromString(e.key)!,
                                ),
                                fontSize: 14,
                                width: isLastTwo
                                    ? (width - 24) / 2
                                    : (width - 151) / 2,
                              );
                            })
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ------------------- Ordered Gender -------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.current.gender_charts,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            spacing: 5,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _metricCard(
                                      title: S.of(context).repeated_customers,
                                      value:
                                          "${state.totalRepeatedCustomers} ${state.totalRepeatedCustomers > 1 ? S.of(context).customers : S.of(context).customer}",
                                      color: primaryColor,
                                      width: double.infinity,
                                      fontSize: 17,
                                    ),
                                    const SizedBox(height: 10),
                                    _metricCard(
                                      title: S.current.liked_by,
                                      value:
                                          '${state.totalShopFavourites} ${state.totalShopFavourites > 1 ? S.of(context).users : S.of(context).user}',
                                      color: primaryColor,
                                      width: double.infinity,
                                      fontSize: 17,
                                    ),
                                  ],
                                ),
                              ),
                              if (state.totalOrders > 0)
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    clipBehavior: Clip.none,
                                    children: [
                                      SizedBox(
                                        height: 200,
                                        width: 200,
                                        child: PieChart(
                                          PieChartData(
                                            sections: [
                                              PieChartSectionData(
                                                value:
                                                    state
                                                        .genderDistribution['male']
                                                        ?.toDouble() ??
                                                    0,
                                                title:
                                                    "${S.current.men}\n${state.genderDistribution['male'] ?? 0}",
                                                color: primaryColor,
                                                radius: touchedIndex == 0
                                                    ? 70
                                                    : 60, // 👈 bigger if touched
                                                titleStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              PieChartSectionData(
                                                value:
                                                    state
                                                        .genderDistribution['female']
                                                        ?.toDouble() ??
                                                    0,
                                                title:
                                                    "${S.current.women}\n${state.genderDistribution['female'] ?? 0}",
                                                color: primaryColor.withOpacity(
                                                  0.6,
                                                ),
                                                radius: touchedIndex == 1
                                                    ? 70
                                                    : 60, // 👈 bigger if touched
                                                titleStyle: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                            pieTouchData: PieTouchData(
                                              touchCallback: (event, pieTouchResponse) {
                                                if (pieTouchResponse == null ||
                                                    pieTouchResponse
                                                            .touchedSection ==
                                                        null ||
                                                    !event
                                                        .isInterestedForInteractions) {
                                                  setState(() {
                                                    touchedIndex = null;
                                                  });
                                                  return;
                                                }

                                                final touchPosition =
                                                    pieTouchResponse
                                                        .touchLocation;
                                                setState(() {
                                                  overlayTop =
                                                      touchPosition.dy - 100;
                                                  touchedIndex =
                                                      pieTouchResponse
                                                          .touchedSection!
                                                          .touchedSectionIndex;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Tooltip overlay
                                      if (touchedIndex != null)
                                        Positioned(
                                          top: overlayTop,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black87,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  () {
                                                    String gender =
                                                        touchedIndex == 0
                                                        ? S.current.men
                                                        : S.current.women;
                                                    int orders =
                                                        touchedIndex == 0
                                                        ? ordersByGender['male'] ??
                                                              0
                                                        : ordersByGender['female'] ??
                                                              0;
                                                    return '$gender ${S.current.orders}: $orders';
                                                  }(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  () {
                                                    String gender =
                                                        touchedIndex == 0
                                                        ? S.current.men
                                                        : S.current.women;
                                                    double totalPurchases =
                                                        touchedIndex == 0
                                                        ? totalSalesByGender['male'] ??
                                                              0
                                                        : totalSalesByGender['female'] ??
                                                              0;
                                                    return '$gender ${S.current.paid}: AED ${formatNumberWithCommas(totalPurchases)}';
                                                  }(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (state.totalOrders > 0) const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // ------------------- TOP BUYERS -------------------
                    if (state.totalOrders > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        child: Text(
                          S.current.top_buyers,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (state.totalOrders > 0)
                      _horizontalBarChart(
                        data: state.topBuyersResolved,
                        valueKey: 'totalSpent',
                        color: primaryColor,
                        maxHeight: 200,
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _metricCard({
    String? title,
    required String value,
    required Color color,
    required double width,
    double fontSize = 20,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          if (title != null) const SizedBox(height: 8),
          title != null
              ? Text(
                  value,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )
              : Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _horizontalBarChart({
    required List<Map<String, dynamic>> data,
    required String valueKey,
    required Color color,
    double maxHeight = 200,
  }) {
    final maxValue = data
        .map((e) => (e[valueKey] as num).toDouble())
        .fold<double>(0, (prev, element) => element > prev ? element : prev);

    return SizedBox(
      height: maxHeight + 70, // give space for labels & avatar
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((item) {
            final value = (item[valueKey] as num).toDouble();
            final barHeight = maxValue == 0
                ? 0
                : (value / maxValue) * maxHeight;

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: maxHeight,
                      width: 50,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      height: barHeight.toDouble(),
                      width: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            barHeight != maxHeight ? 0 : 6,
                          ),
                          topRight: Radius.circular(
                            barHeight != maxHeight ? 0 : 6,
                          ),
                          bottomLeft: Radius.circular(6),
                          bottomRight: Radius.circular(6),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              S.of(context).orders,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              item['ordersCount'].toString() ?? '0',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      top: 0,
                      child: Center(
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(item['image']),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 75,
                  height: 60,
                  child: Column(
                    children: [
                      Text(
                        item['title'] ?? item['name'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      Text(
                        "\$${value.toStringAsFixed(0)}", // show value under avatar
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ProductClicksTrendChart extends StatelessWidget {
  final Map<String, Map<String, int>> trendData;
  final String timeframe;
  final String? selectedProduct; // 👈 new

  const ProductClicksTrendChart({
    super.key,
    required this.trendData,
    required this.timeframe,
    this.selectedProduct,
  });

  // --- Get all timeframe buckets based on timeframe ---
  List<String> getAllBuckets() {
    if (selectedProduct != null) {
      // Only take buckets for selected product
      final map = trendData[selectedProduct];
      if (map != null && map.isNotEmpty) {
        return _sortBuckets(map.keys.toList());
      }
      return [];
    } else {
      // Fallback: show all buckets (first product or merged)
      final buckets = trendData.values.expand((m) => m.keys).toSet().toList();
      return _sortBuckets(buckets);
    }
  }

  List<String> _sortBuckets(List<String> buckets) {
    String normalizeDigits(String input) {
      const easternArabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      for (var i = 0; i < easternArabic.length; i++) {
        input = input.replaceAll(easternArabic[i], i.toString());
      }
      return input;
    }

    switch (timeframe) {
      case "daily":
        buckets.sort((a, b) {
          final da = DateFormat("hh:mm a").parse(a);
          final db = DateFormat("hh:mm a").parse(b);
          return da.compareTo(db);
        });
        break;
      case "weekly":
        const weekOrder = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
        buckets.sort(
          (a, b) => weekOrder.indexOf(a).compareTo(weekOrder.indexOf(b)),
        );
        break;
      case "monthly":
        buckets.sort((a, b) {
          final intA = int.parse(normalizeDigits(a));
          final intB = int.parse(normalizeDigits(b));
          return intA.compareTo(intB);
        });
        break;
      case "yearly":
        final monthOrder = List.generate(
          12,
          (i) => DateFormat("MMM").format(DateTime(2000, i + 1)),
        );
        buckets.sort(
          (a, b) => monthOrder.indexOf(a).compareTo(monthOrder.indexOf(b)),
        );
        break;
      default:
        buckets.sort();
    }
    return buckets;
  }

  // --- Bottom Titles ---
  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final buckets = getAllBuckets();
    final index = value.toInt();
    if (index < 0 || index >= buckets.length) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
      meta: meta,
      child: Text(buckets[index], style: style),
    );
  }

  // --- Left: Y Axis values ---
  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 12);

    // Show only whole numbers (since clicks are counts)
    if (value % 1 != 0) {
      return const SizedBox.shrink();
    }

    return SideTitleWidget(
      meta: meta, // 👈 pass the whole meta object here
      child: Text(value.toInt().toString(), style: style),
    );
  }

  // --- Bars ---
  List<BarChartGroupData> getBarGroups(List<String> buckets) {
    final productList = selectedProduct != null
        ? [selectedProduct!] // 👈 only one
        : trendData.keys.toList(); // 👈 all

    return buckets.asMap().entries.map((entry) {
      final bucketIndex = entry.key;
      final bucket = entry.value;

      final rods = productList.asMap().entries.map((pEntry) {
        final pIndex = pEntry.key;
        final product = pEntry.value;
        final clicks = trendData[product]?[bucket] ?? 0;

        return BarChartRodData(
          toY: clicks.toDouble(),
          width: 12,
          color: primaryColor, // 👈 fixed single color for one product
          borderRadius: BorderRadius.circular(4),
        );
      }).toList();

      return BarChartGroupData(x: bucketIndex, barRods: rods, barsSpace: 6);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(S.current.empty_orders)),
      );
    }

    final buckets = getAllBuckets();
    final allClicks = selectedProduct != null
        ? trendData[selectedProduct]?.values.toList() ??
              [] // only selected product
        : trendData.values.expand((m) => m.values).toList(); // all products

    final maxValue = allClicks.isNotEmpty
        ? allClicks.reduce((a, b) => a > b ? a : b).toDouble()
        : 0;

    final adjustedMaxY = (maxValue > 0)
        ? ((maxValue / 2).ceil() * 2).toDouble()
        : 5.0;

    return Padding(
      padding: EdgeInsetsGeometry.directional(end: 17),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: adjustedMaxY,
            barGroups: getBarGroups(buckets),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: bottomTitles,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 1, // 👈 every 1 click step
                  getTitlesWidget: leftTitles,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(show: true, drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final bucket = buckets[group.x.toInt()];
                  final product =
                      selectedProduct ?? trendData.keys.elementAt(rodIndex);
                  return BarTooltipItem(
                    "$product\n$bucket: ${rod.toY.toInt()} ${S.current.clicks}",
                    const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopProductsBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final Color barColor;

  const TopProductsBarChart({
    super.key,
    required this.data,
    this.barColor = Colors.blue,
  });

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);
    final index = value.toInt();
    if (index < 0 || index >= data.length) return const SizedBox.shrink();
    final title = data[index]['title'] ?? data[index]['name'] ?? '';
    return SideTitleWidget(
      meta: meta,
      child: SizedBox(
        width: 40,
        child: Text(
          title,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 13);
    return SideTitleWidget(
      meta: meta,
      child: Text(meta.formattedValue, style: style),
    );
  }

  List<BarChartGroupData> getBarGroups() {
    return data.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final sold = (item['quantitySold'] ?? 0).toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: sold,
            color: barColor,
            width: 20,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(S.current.empty_orders)),
      );
    }

    final maxValue = data
        .map((e) => (e['quantitySold'] ?? 0) as num)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    // Round UP to the nearest multiple of 2
    final adjustedMaxY = ((maxValue / 2).ceil() * 2).toDouble();

    return Padding(
      padding: EdgeInsetsGeometry.directional(end: 17),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: adjustedMaxY,
              barGroups: getBarGroups(),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    getTitlesWidget: bottomTitles,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 2, // Always step by 2
                    getTitlesWidget: leftTitles,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = data[groupIndex];
                    return BarTooltipItem(
                      '${item['title'] ?? item['name']}\nSold: ${item['quantitySold']}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
