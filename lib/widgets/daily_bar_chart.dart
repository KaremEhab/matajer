import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:matajer/constants/colors.dart';

class DailyBarChart extends StatefulWidget {
  final Map<String, double> salesData;

  const DailyBarChart({super.key, required this.salesData});

  final Color barBackgroundColor = transparentColor;
  final Color barColor = const Color(0xffae8aef);
  final Color touchedBarColor = primaryColor;

  @override
  State<StatefulWidget> createState() => _DailyBarChartState();
}

class _DailyBarChartState extends State<DailyBarChart> {
  final Duration animDuration = const Duration(milliseconds: 250);

  int touchedIndex = -1;

  final Map<String, int> indexMapping = {'1': 0, '2': 1, '3': 2, '4': 3};

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
          borderSide: isTouched
              ? BorderSide(color: widget.touchedBarColor)
              : const BorderSide(color: Colors.white, width: 0),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: getMaxY() + 5, // Add padding above the max value
            color: widget.barBackgroundColor,
          ),
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  double getMaxY() {
    if (widget.salesData.isEmpty) {
      return 0.0;
    }
    return widget.salesData.values.reduce((a, b) => max(a, b));
  }

  List<BarChartGroupData> showingGroups() {
    return widget.salesData.entries.map((entry) {
      final key = entry.key;
      final sales = entry.value;
      final index = indexMapping[key] ?? 0;
      return makeGroupData(index, sales, isTouched: index == touchedIndex);
    }).toList();
  }

  BarChartData mainBarData() {
    final maxY = getMaxY() + 5; // Add padding above the max value

    return BarChartData(
      maxY: maxY,
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => Colors.white,
          tooltipHorizontalAlignment: FLHorizontalAlignment.center,
          tooltipMargin: -10,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String key = widget.salesData.keys.elementAt(group.x.toInt());
            return BarTooltipItem(
              '$key\n',
              const TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              children: [
                TextSpan(
                  text: (rod.toY - 1).toString(),
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
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
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
            interval: (maxY / 5)
                .ceilToDouble(), // Adjust interval based on max value
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: showingGroups(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (maxY / 5)
            .ceilToDouble(), // Adjust grid interval based on max value
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
    value++;
    return SideTitleWidget(
      space: 12.h,
      meta: TitleMeta(
        min: 1,
        max: 5,
        parentAxisSize: 0,
        axisPosition: 0,
        appliedInterval: 0,
        sideTitles: SideTitles(),
        formattedValue: "",
        axisSide: meta.axisSide,
        rotationQuarterTurns: 0,
      ),
      child: Text(
        value.toStringAsFixed(0),
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
