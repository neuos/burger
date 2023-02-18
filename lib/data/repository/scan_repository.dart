import 'package:burger/data/model/event.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../model/scan.dart';

abstract class IScanRepository {
  Future<void> insert(Scan scan);

  Future<List<Scan>> find(EventId eventId, String tagId);

  Future<List<Scan>> findAll(EventId eventId);
}

class ScanRepository implements IScanRepository {
  final _db = GetIt.I.getAsync<Database>();
  final logger = Logger();

  @override
  Future<void> insert(Scan scan) async {
    final db = await _db;
    final res = await db.insert(
      Scan.tableName,
      scan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    logger.d("inserted $res");
  }

  @override
  Future<List<Scan>> find(EventId eventId, String tagId) async {
    final db = await _db;
    var res = await db.query(
      Scan.tableName,
      where: 'tagId = ? AND eventId = ?',
      whereArgs: [tagId, eventId],
      orderBy: 'timestamp ASC',
    );
    logger.d("found ${res.length} results");
    return res.map(Scan.fromMap).toList();
  }

  @override
  Future<List<Scan>> findAll(EventId eventId) async {
    final db = await _db;
    var res = await db.query(Scan.tableName,
        where: 'eventId = ?',
        whereArgs: [eventId],
        orderBy: 'timestamp ASC');
    logger.d("found ${res.length} results");
    return res.map(Scan.fromMap).toList();
  }
}
