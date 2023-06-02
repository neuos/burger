import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/model/event.dart';
import '../data/model/scan.dart';
import '../data/repository/scan_repository.dart';
import '../scanner.dart';
import 'scan_result.dart';
import 'statistic.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key, required this.title, required this.event});

  final String title;
  final Event event;

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
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
    setState(() {
      _error = "Preparing scanner";
    });
    final message = await startScanner(onDiscovered);
    setState(() {
      _error = message;
    });
  }

  Future<void> _stopScanner() async {
    await stopScanner();
    setState(() {
      _error = "Scanner stopped";
    });
  }

  Future<void> onDiscovered(String? id) async {
    _error = null;
    _history = [];

    // ignore double scans
    if (id == previousId) {
      return;
    }
    previousId = id;

    if (id == null) {
      setState(() {
        _error = "No ID found";
      });
      return;
    }

    logger.i('read ID: $id');

    await repo.insert(Scan(eventId: widget.event.id, tagId: id));
    final history = await repo.find(widget.event.id, id);
    setState(() {
      _history = history.map((e) => e.timestamp).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(icon: const Icon(Icons.nfc), onPressed: _restartScanner),
          IconButton(onPressed: _export, icon: const Icon(Icons.share)),
        ],
      ),
      body: Center(
        child: Column(children: <Widget>[
          ScanResult(history: _history, error: _error),
          Expanded(child: Container()),
          FutureBuilder(
            future: repo.findAll(widget.event.id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Card(
                    child: Statistic(data: snapshot.data as List<Scan>));
              }
              return const CircularProgressIndicator();
            },
          )
        ]),
      ),
    );
  }

  // create file with all scans and share it
  void _export() async {
    final fullHistory = await repo.findAll(widget.event.id);
    final directory = await getApplicationDocumentsDirectory();
    final filename = "${widget.event.name} - ${fullHistory.last.timestamp}.csv";
    final file = File('${directory.path}/$filename');
    final csv = fullHistory.map((e) => e.toCsv()).join('\n');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: filename);
  }

  void _restartScanner() async {
    await _stopScanner();
    await _startScanner();
  }
}
