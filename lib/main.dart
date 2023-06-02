import 'package:burger/data/repository/event_repository.dart';
import 'package:burger/data/serialization/scan_serializer.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import 'data/database.dart';
import 'data/repository/scan_repository.dart';
import 'widgets/event_list.dart';

const brandColor = Color(0xFFF29400);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final getIt = GetIt.I;
  getIt.registerLazySingletonAsync<Database>(() => DatabaseProvider.initDB());
  getIt.registerLazySingleton<IScanRepository>(() => ScanRepository());
  getIt.registerLazySingleton<IEventRepository>(() => EventRepository());
  getIt.registerLazySingleton<IScanSerializer>(() => ScanSerializer());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
        builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
      final ColorScheme lightColorScheme;
      final ColorScheme darkColorScheme;
      if (lightDynamic != null && darkDynamic != null) {
        lightColorScheme = lightDynamic.harmonized();
        darkColorScheme = darkDynamic.harmonized();
      } else {
        Logger().w('Dynamic color scheme is null');
        lightColorScheme = ColorScheme.fromSeed(
          seedColor: brandColor,
        );
        darkColorScheme = ColorScheme.fromSeed(
          seedColor: brandColor,
          brightness: Brightness.dark,
        );
      }

      return MaterialApp(
        theme: ThemeData.from(
          colorScheme: lightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData.from(
          colorScheme: darkColorScheme,
          useMaterial3: true,
        ),
        home: const EventList(),
      );
    });
  }
}
