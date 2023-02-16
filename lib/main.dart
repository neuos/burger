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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(title: 'Burger Scanner'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
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
