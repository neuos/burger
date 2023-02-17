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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final getIt = GetIt.instance;
  getIt.registerLazySingletonAsync<Database>(() => DatabaseProvider.initDB());
  getIt.registerLazySingleton<IScanRepository>(() => ScanRepository());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
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
  Uint8List? previousId;

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
      logger.w('nfc reader not available');
      setState(() {
        _error = "nfc reader not available";
      });
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
    final id = getId(tag);

    _error = null;
    _history = [];

    // ignore double scans
    if (listEquals(id, previousId)) {
      return;
    }
    previousId = id;

    if (id == null) {
      logger.w("No id found", tag.data);
      setState(() {
        _error = "no id found";
      });
      return;
    }

    final stringId = hex(id);
    logger.i('read id: $stringId');

    final history = await repo.find(stringId);
    repo.insert(Scan(tagId: stringId));

    if (history.isNotEmpty) {
      logger.i('already scanned: $history');
      setState(() {
        _error = "already scanned";
        _history = history.map((s) => s.timestamp).toList();
      });
    } else {
      setState(() {
        _error = null;
        _history = [];
      });
    }
  }

  Uint8List? getId(NfcTag tag) {
    return NdefFormatable.from(tag)?.identifier ?? MiFare.from(tag)?.identifier;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_history.isEmpty && _error == null)
              const Text(
                'Not scanned yet',
                style: TextStyle(color: Colors.green),
              ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            if (_history.isNotEmpty)
              Column(
                children: [
                  Text(
                    'Scanned ${_history.length} times',
                    style: const TextStyle(color: Colors.red),
                  ),
                  for (final date in _history)
                    Text(
                      date.toString(),
                      style: const TextStyle(color: Colors.red),
                    )
                ],
              ),
          ],
        ),
      ),
    );
  }
}
