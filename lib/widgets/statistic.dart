import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

import '../data/model/scan.dart';

class Statistic extends StatelessWidget {
  const Statistic({super.key, required List<Scan> data}) : _data = data;
  final List<Scan> _data;

  @override
  Widget build(BuildContext context) {
    final themeData = GetIt.I.get<ThemeData>();
    final List<int> counts = getBinned(_data);

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
                  color: themeData.primaryColor,
                ),
              ],
              backgroundColor: themeData.colorScheme.primaryContainer,
            ))),
      ],
    );
  }

  List<int> getBinned(List<Scan> data, {int segments = 16}) {
    if (data.isEmpty) {
      Logger().w('no data');
      return List.filled(segments, 0);
    }
    final first = data.first.timestamp;
    final last = data.last.timestamp.add(const Duration(seconds: 1));
    final diff = last.difference(first).inSeconds;
    final segment = diff / segments;
    final counts = List.filled(segments, 0);
    for (final scan in data) {
      final index = scan.timestamp.difference(first).inSeconds ~/ segment;
      counts[index]++;
    }
    assert(data.length == counts.reduce((a, b) => a + b));
    return counts;
  }
}
