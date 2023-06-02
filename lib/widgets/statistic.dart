import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../data/model/scan.dart';

class Statistic extends StatelessWidget {
  const Statistic({super.key, required List<Scan> data}) : _data = data;
  final List<Scan> _data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<int> counts = getBinned(_data);
    final List<DateTime> binTimes = getBinTimes(_data, segments: counts.length);

    Logger().i('counts: $counts');

    return Column(
      children: [
        Text('History (${_data.length})'),
        AspectRatio(
            aspectRatio: 1.5,
            child: LineChart(LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: counts
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                      .toList(),
                  color: colorScheme.primary,
                ),
              ],
              gridData: FlGridData(show: true),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: colorScheme.secondary,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((e) {
                      final index = e.spotIndex.toInt();
                      if (index < counts.length) {
                        return LineTooltipItem(counts[index].toString(),
                            TextStyle(color: colorScheme.onSecondary));
                      }
                      return LineTooltipItem('', const TextStyle());
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index % 2 != 0) {
                        return const Text('');
                      }
                      if (index < binTimes.length) {
                        return Text(
                            DateFormat("HH:mm").format(binTimes[index]));
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              backgroundColor: colorScheme.primaryContainer,
            ))),
      ],
    );
  }

  List<int> getBinned(List<Scan> data, {int segments = 9}) {
    if (data.isEmpty) {
      Logger().w('no data');
      return List.filled(segments, 0);
    }
    final first = data.first.timestamp;
    final last = data.last.timestamp.add(const Duration(seconds: 1));
    final diff = last.difference(first).inSeconds;
    final secondsPerBin = diff / segments;
    final counts = List.filled(segments, 0);
    for (final scan in data) {
      final index = scan.timestamp.difference(first).inSeconds ~/ secondsPerBin;
      counts[index]++;
    }
    assert(data.length == counts.reduce((a, b) => a + b));
    return counts;
  }

  List<DateTime> getBinTimes(List<Scan> data, {required int segments}) {
    if (data.isEmpty) {
      Logger().w('no data');
      return List.filled(segments, DateTime.now());
    }
    final first = data.first.timestamp;
    final last = data.last.timestamp.add(const Duration(seconds: 1));
    final diff = last.difference(first).inSeconds;
    final secondsPerBin = diff / segments;
    final times = <DateTime>[];
    for (var i = 0; i < segments; i++) {
      times.add(first.add(Duration(seconds: (i * secondsPerBin).toInt())));
    }
    return times;
  }
}
