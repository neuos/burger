import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'model/event.dart';
import 'model/scan.dart';

class DatabaseProvider {
  static Future<Database> initDB() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'app.sqlite'),
      onCreate: (db, version) async {
        await db.execute(Event.createTable);
        await db.execute(Scan.createTable);
      },
      version: 2,
    );
  }
}
