import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';

class WeeklyBarChart extends StatefulWidget {
  final Map<String, double> weeklySales;

  const WeeklyBarChart({super.key, required this.weeklySales});

  List<Color> get availableColors => const <Color>[
    Colors.purple,
    Colors.yellow,
    Colors.blue,
    Colors.orange,
    Colors.pink,
    Colors.red,
  ];

  final Color barBackgroundColor = transparentColor;
  final Color barColor = const Color(0xffae8aef);
  final Color touchedBarColor = primaryColor;

  @override
  State<WeeklyBarChart> createState() => _WeeklyChartBarState();
}

class _WeeklyChartBarState extends State<WeeklyBarChart> {
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  final Map<String, int> dayIndex = {
    'Monday': 0,
    'Tuesday': 1,
    'Wednesday': 2,
    'Thursday': 3,
    'Friday': 4,
    'Saturday': 5,
    'Sunday': 6,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 0.3.sh,
      width: 1.sw,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: BarChart(
                mainBarData(),
                swapAnimationDuration: animDuration,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    bool isTouched = false,
    Color? barColor,
    double width = 18,
    List<int> showTooltips = const [],
  }) {
    barColor ??= widget.barColor;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: isTouched ? y + 1 : y,
          color: isTouched ? widget.touchedBarColor : barColor,
          width: width,
          borderSide:
              isTouched
                  ? BorderSide(color: widget.touchedBarColor)
                  : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: getMaxY() + 5,
            color: widget.barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  double getMaxY() {
    if (widget.weeklySales.isEmpty) return 0.0;
    return widget.weeklySales.values.reduce(max);
  }

  List<BarChartGroupData> showingGroups() {
    return dayIndex.entries.map((entry) {
      final day = entry.key;
      final index = entry.value;
      final sales = widget.weeklySales[day] ?? 0;
      return makeGroupData(index, sales, isTouched: index == touchedIndex);
    }).toList();
  }

  BarChartData mainBarData() {
    final maxY = getMaxY() + 5;

    return BarChartData(
      maxY: maxY,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.white,
          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
          tooltipMargin: -10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final index = group.x;
            final day =
                dayIndex.entries
                    .firstWhere(
                      (e) => e.value == index,
                      orElse: () => const MapEntry("N/A", 0),
                    )
                    .key;
            return BarTooltipItem(
              '$day\n',
              const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              children: [
                TextSpan(
                  text: (rod.toY - 1).toStringAsFixed(2),
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse?.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse!.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            reservedSize: 38,
            getTitlesWidget: getTitles,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50.w,
            interval: (maxY / 5).ceilToDouble(),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: showingGroups(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY / 5).ceilToDouble(),
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: greyColor.withOpacity(0.6),
            strokeWidth: 1,
            dashArray: [5, 5],
          );
        },
      ),
    );
  }

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: textColor,
      fontWeight: FontWeight.w600,
      fontSize: 13.2.sp,
    );

    final day =
        dayIndex.entries
            .firstWhere(
              (entry) => entry.value == value.toInt(),
              orElse: () => const MapEntry("N/A", 0),
            )
            .key;

    return SideTitleWidget(
      space: 12.h,
      meta: meta,
      child: Text(
        day.substring(0, 3), // Mon, Tue, etc.
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
