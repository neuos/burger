import 'package:burger/data/serialization/scan_serializer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

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
  final serializer = GetIt.I.get<IScanSerializer>();
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
    if (mounted) {
      setState(() {
        _error = "Scanner stopped";
      });
    }
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
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.share),
                      Text('Export'),
                    ],
                  )),
              const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.file_open),
                      Text('Import'),
                    ],
                  ))
            ],
            onSelected: (value) {
              switch (value) {
                case 'export':
                  _export();
                  break;
                case 'import':
                  _import();
                  break;
              }
            },
          )
        ],
      ),
      body: Center(
        child: Column(children: <Widget>[
          Expanded(child: ScanResult(history: _history, error: _error)),
          FutureBuilder(
      future: repo.findAll(widget.event.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if(snapshot.data!.isEmpty){
            return const SizedBox();
          }
          return Card(child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Statistic(data: snapshot.data as List<Scan>),
          ));
        }
        return const CircularProgressIndicator();
      },
    ),
        ]),
      ),
    );
  }

  void _restartScanner() async {
    await _stopScanner();
    await _startScanner();
  }

  void _export() async {
    await serializer.export(widget.event);
  }

  void _import() async {
    await serializer.import(widget.event);
    setState(() {});
  }
}
