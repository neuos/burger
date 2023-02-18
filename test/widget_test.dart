// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:burger/data/database.dart';
import 'package:burger/data/repository/event_repository.dart';
import 'package:burger/data/repository/scan_repository.dart';
import 'package:burger/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final getIt = GetIt.instance;

  setUpAll(() {
    getIt.registerLazySingletonAsync<Database>(() => DatabaseProvider.initDB());
    getIt.registerLazySingleton<IScanRepository>(() => ScanRepository());
    getIt.registerLazySingleton<IEventRepository>(() => EventRepository());
  });

  testWidgets('App runs and has Widgets', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    expect(tester.allWidgets.isNotEmpty, true);
  });
}
