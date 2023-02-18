typedef EventId = int;

class Event {
  final EventId id;
  final String name;
  final int? count;

  Event({required this.name, this.id = -1, this.count});

  static const String tableName = 'events';
  static const String createTable = '''
    CREATE TABLE $tableName (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      name TEXT
    )
  ''';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  static Event fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      count: map['count'],
    );
  }


  @override
  String toString() {
    return 'Event{id: $id, name: $name, count: $count}';
  }
}
