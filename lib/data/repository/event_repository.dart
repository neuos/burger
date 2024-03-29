import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../model/event.dart';
import '../model/scan.dart';

abstract class IEventRepository {
  Future<List<Event>> getEvents();

  Future<int> create(Event event);

  Future<void> delete(Event event);
}

class EventRepository implements IEventRepository {
  final _db = GetIt.I.getAsync<Database>();
  final logger = Logger();

  @override
  Future<int> create(Event event) async {
    final db = await _db;

    var map = event.toMap();
    map.remove('id');
    final id = await db.insert(
      Event.tableName,
      map,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    logger.d("inserted event with id $id");
    return id;
  }

  @override
  Future<void> delete(Event event) async {
    final db = await _db;
    final res = await db.delete(
      Event.tableName,
      where: 'id = ?',
      whereArgs: [event.id],
    );
    logger.d("deleted $res");
  }

  @override
  Future<List<Event>> getEvents() async {
    final db = await _db;

    var res = await db.rawQuery('''
      SELECT id, name, COUNT(tagId) as count
      FROM ${Event.tableName} left join ${Scan.tableName} on ${Event.tableName}.id = ${Scan.tableName}.eventId
      GROUP BY id
      ORDER BY id DESC''');

    logger.d("found ${res.length} results");
    return res.map(Event.fromMap).toList();
  }
}
