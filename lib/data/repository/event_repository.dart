import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../model/event.dart';

abstract class IEventRepository{
  Future<List<Event>> getEvents();
  Future<void> addEvent(Event event);
  Future<void> deleteEvent(Event event);
}

class EventRepository implements IEventRepository{
  final _db = GetIt.I.getAsync<Database>();
  final logger = Logger();


  @override
  Future<Event> addEvent(Event event) async {
    final db = await _db;
    final res = await db.insert(
      Event.tableName,
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    logger.d("inserted $res");

    return event;
  }

  @override
  Future<void> deleteEvent(Event event) async {
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
    var res = await db.query(
      Event.tableName,
      orderBy: 'timestamp ASC',
    );
    logger.d("found ${res.length} results");
    return res.map(Event.fromMap).toList();
  }

}
