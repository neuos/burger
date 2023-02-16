import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'model/scan.dart';

class DatabaseProvider {
  static Future<Database> initDB() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'app.sqlite'),
      onCreate: (db, version) {
        return db.execute(
          Scan.createTable,
        );
      },
      version: 1,
    );
  }
}
