import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import '../model/Scan.dart';

abstract class IScanRepository {
  Future<void> insert(Scan scan);
  Future<List<Scan>> find(String tagId);
}


class ScanRepository implements IScanRepository {
  final _db = GetIt.I.getAsync<Database>();

  @override
  Future<void> insert(Scan scan) async {
    final db = await _db;
    await db.insert(
      Scan.tableName,
      scan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Scan>> find(String tagId) async {
    final db = await _db;
    var res = await db.query(
      Scan.tableName,
      where: 'tagId = ?',
      whereArgs: [tagId],
    );
    return res.map(Scan.fromMap).toList();
  }
}
