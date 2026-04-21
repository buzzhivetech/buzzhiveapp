import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/sensor_reading.dart';
import 'metric_selector.dart';

/// Renders a time-series line chart for a single [SensorMetric] across a list
/// of [SensorReading]s.  X-axis = time, Y-axis = metric value.
class SensorLineChart extends StatelessWidget {
  const SensorLineChart({
    required this.readings,
    required this.metric,
    super.key,
  });

  final List<SensorReading> readings;
  final SensorMetric metric;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Center(
        child: Text(
          'No data for this time range',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final theme = Theme.of(context);
    final spots = _buildSpots();
    final yValues = spots.map((s) => s.y).toList();
    final yMin = yValues.reduce(math.min);
    final yMax = yValues.reduce(math.max);
    final yPad = (yMax - yMin) * 0.1;
    final effectiveMin = yMin - yPad;
    final effectiveMax = yMax + yPad;

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 8),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: theme.colorScheme.primary,
              barWidth: 2,
              dotData: FlDotData(
                show: readings.length <= 50,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 2.5,
                  color: theme.colorScheme.primary,
                  strokeWidth: 0,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ],
          minY: effectiveMin.isFinite ? effectiveMin : 0,
          maxY: effectiveMax.isFinite ? effectiveMax : 1,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                '${metric.label} (${metric.unit})',
                style: theme.textTheme.labelSmall,
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toStringAsFixed(1),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _formatTime(dt),
                      style: theme.textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              left: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final dt =
                    DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(2)} ${metric.unit}\n',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat('MMM d, h:mm a').format(dt),
                      style: TextStyle(
                        color: theme.colorScheme.onInverseSurface
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    return readings.map((r) {
      final x = r.timestamp.millisecondsSinceEpoch.toDouble();
      final y = metric.valueFrom(r);
      return FlSpot(x, y);
    }).toList();
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('M/d h:mm').format(dt);
  }
}
