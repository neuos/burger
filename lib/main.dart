import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

import 'data/database.dart';
import 'data/repository/scan_repository.dart';
import 'widgets/home_page.dart';

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
