import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/sensor_reading.dart';
import 'metric_selector.dart';

/// Max points to render on the chart. Beyond this, LTTB downsampling kicks in.
const _maxDisplayPoints = 200;

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
    final allSpots = _buildSpots();
    final spots = _downsampleLTTB(allSpots, _maxDisplayPoints);

    final yValues = spots.map((s) => s.y).toList();
    final yMin = yValues.reduce(math.min);
    final yMax = yValues.reduce(math.max);
    final yPad = yMax == yMin ? 1.0 : (yMax - yMin) * 0.1;
    final effectiveMin = yMin - yPad;
    final effectiveMax = yMax + yPad;

    final xMin = spots.first.x;
    final xMax = spots.last.x;
    final spanMs = xMax - xMin;
    final labelInterval = _chooseLabelInterval(spanMs);

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
                show: spots.length <= 50,
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
                reservedSize: 40,
                interval: labelInterval,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  final dt =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _formatLabel(dt, spanMs),
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
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

  // ---------------------------------------------------------------------------
  // Adaptive X-axis labels
  // ---------------------------------------------------------------------------

  static const _hour = 3600 * 1000.0;
  static const _day = 24 * _hour;

  /// Pick a round label interval so ~4-6 labels appear regardless of span.
  double _chooseLabelInterval(double spanMs) {
    if (spanMs <= 0) return _hour;
    final candidates = [
      _hour,
      2 * _hour,
      4 * _hour,
      6 * _hour,
      12 * _hour,
      _day,
      2 * _day,
      3 * _day,
      7 * _day,
      14 * _day,
      30 * _day,
    ];
    for (final c in candidates) {
      if (spanMs / c <= 7) return c;
    }
    return 30 * _day;
  }

  /// Format a tick label based on the total time span being displayed.
  String _formatLabel(DateTime dt, double spanMs) {
    if (spanMs <= _day) {
      return DateFormat('h:mm a').format(dt);
    }
    if (spanMs <= 7 * _day) {
      return '${DateFormat('M/d').format(dt)}\n${DateFormat('h a').format(dt)}';
    }
    return DateFormat('MMM d').format(dt);
  }

  // ---------------------------------------------------------------------------
  // LTTB (Largest Triangle Three Buckets) downsampling
  // ---------------------------------------------------------------------------

  /// Reduces [data] to at most [threshold] points while preserving visual
  /// shape (peaks, valleys, trends).  Always keeps the first and last point.
  static List<FlSpot> _downsampleLTTB(List<FlSpot> data, int threshold) {
    if (data.length <= threshold) return data;

    final out = <FlSpot>[data.first];
    final bucketSize = (data.length - 2) / (threshold - 2);
    var prevIdx = 0;

    for (var bucket = 1; bucket < threshold - 1; bucket++) {
      final curStart = ((bucket - 1) * bucketSize + 1).floor();
      final curEnd =
          (bucket * bucketSize + 1).floor().clamp(0, data.length - 1);

      // Average of the *next* bucket (used as the third triangle vertex).
      final nextStart = curEnd;
      final nextEnd =
          ((bucket + 1) * bucketSize + 1).floor().clamp(0, data.length);
      var avgX = 0.0, avgY = 0.0;
      var cnt = 0;
      for (var j = nextStart; j < nextEnd; j++) {
        avgX += data[j].x;
        avgY += data[j].y;
        cnt++;
      }
      if (cnt > 0) {
        avgX /= cnt;
        avgY /= cnt;
      }

      // Pick the point in the current bucket that maximises triangle area.
      final prev = data[prevIdx];
      var bestArea = -1.0;
      var bestIdx = curStart;
      for (var j = curStart; j < curEnd; j++) {
        final area = ((prev.x - avgX) * (data[j].y - prev.y) -
                (prev.x - data[j].x) * (avgY - prev.y))
            .abs();
        if (area > bestArea) {
          bestArea = area;
          bestIdx = j;
        }
      }

      out.add(data[bestIdx]);
      prevIdx = bestIdx;
    }

    out.add(data.last);
    return out;
  }
}
