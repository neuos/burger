import 'dart:math';

import 'package:burger/data/model/scan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite/utils/utils.dart';

import 'data/database.dart';
import 'data/repository/scan_repository.dart';
import 'package:fl_chart/fl_chart.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final getIt = GetIt.I;
  getIt.registerLazySingletonAsync<Database>(() => DatabaseProvider.initDB());
  getIt.registerLazySingleton<IScanRepository>(() => ScanRepository());
  getIt.registerLazySingleton(() => ThemeData(
        colorSchemeSeed: const Color(0xFFF29400),
        useMaterial3: true,
      ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var themeData = GetIt.I.get<ThemeData>();

    return MaterialApp(
      theme: themeData,
      home: const MyHomePage(title: 'Burger Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final repo = GetIt.I.get<IScanRepository>();
  final logger = Logger();

  String? _error;
  List<DateTime> _history = [];
  String? previousId;

  @override
  initState() {
    super.initState();
    _startScanner();
  }

  @override
  dispose() {
    super.dispose();
    _stopScanner();
  }

  Future<void> _startScanner() async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      setState(() {
        _error = "nfc reader not available";
      });
      logger.w(_error);
      return;
    }

    // Start Session
    await NfcManager.instance.startSession(
      onDiscovered: onDiscovered,
      pollingOptions: {NfcPollingOption.iso14443},
    );
  }

  Future<void> _stopScanner() async {
    await NfcManager.instance.stopSession();
  }

  Future<void> onDiscovered(NfcTag tag) async {
    _error = null;
    _history = [];

    final id = getId(tag);

    // ignore double scans
    if (id == previousId) {
      return;
    }
    previousId = id;

    if (id == null) {
      setState(() {
        _error = "No ID found";
      });
      logger.w(_error, tag.data);
      return;
    }

    logger.i('read ID: $id');

    await repo.insert(Scan(tagId: id));
    final history = await repo.find(id);
    setState(() {
      _history = history.map((e) => e.timestamp).toList();
    });
  }

  String? getId(NfcTag tag) {
    final id = NfcA.from(tag)?.identifier ??
        NfcB.from(tag)?.identifier ??
        NfcF.from(tag)?.identifier ??
        NfcV.from(tag)?.identifier ??
        MiFare.from(tag)?.identifier ??
        MifareClassic.from(tag)?.identifier ??
        MifareUltralight.from(tag)?.identifier ??
        NdefFormatable.from(tag)?.identifier ??
        Iso7816.from(tag)?.identifier ??
        Iso15693.from(tag)?.identifier;

    return id != null ? hex(id) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(children: <Widget>[
          ScanResult(history: _history, error: _error),
          Expanded(child: Container()),
          const Statistic(),
        ]),
      ),
    );
  }
}

class Statistic extends StatelessWidget {
  const Statistic({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Scan>>(
      future: GetIt.I.get<IScanRepository>().findAll(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<int> counts = getBinned(snapshot.data!);

          Logger().i('counts: $counts');

          final chart = LineChart(LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: counts
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                    .toList(),
              ),
            ],
          ));

          return Column(
            children: [
              Text('History (${snapshot.data!.length})'),
              AspectRatio(aspectRatio: 1.5, child: chart),
            ],
          );
        } else {
          return const Text('Loading...');
        }
      },
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
    return counts;
  }
}

class ScanResult extends StatelessWidget {
  const ScanResult({super.key, required this.history, this.error});

  final List<DateTime> history;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final Status status;
    final String text;
    if (error != null) {
      status = Status.error;
      text = error!;
    } else if (history.length == 1) {
      status = Status.success;
      text = "Enjoy your Burger";
    } else {
      status = Status.warn;
      text = "Scanned ${history.length} times";
    }

    return Column(
      children: [
        Column(
          children: [
            StatusCard(
              status: status,
              text: text,
            ),
            SizedBox(
              height: 300,
              child: ListView.builder(
                shrinkWrap: false,
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final date = history[index];
                  return Card(
                    child: ListTile(
                      title: Text(date.toString()),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum Status { success, warn, error }

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.status, required this.text});

  final Status status;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Color containerColor;
    final IconData icon;
    final Color color;

    var themeData = GetIt.I.get<ThemeData>();
    switch (status) {
      case Status.success:
        containerColor = themeData.colorScheme.primaryContainer;
        icon = Icons.check_box;
        color = themeData.colorScheme.primary;
        break;
      case Status.warn:
        containerColor = themeData.colorScheme.errorContainer;
        icon = Icons.warning;
        color = themeData.colorScheme.error;
        break;
      case Status.error:
        containerColor = themeData.colorScheme.errorContainer;
        icon = Icons.error;
        color = themeData.colorScheme.error;
        break;
    }

    return Card(
      color: containerColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 128,
            ),
            Flexible(
              child: Text(
                text,
                style: TextStyle(color: color, fontSize: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
