import 'event.dart';

class Scan {
  final EventId eventId;
  final String tagId;
  final DateTime timestamp;

  static const String tableName = 'scans';

  static const String createTable = '''
    CREATE TABLE $tableName (
      tagId TEXT,
      timestamp INTEGER,
      eventId INTEGER,
      FOREIGN KEY(eventId) REFERENCES ${Event.tableName}(id)
      PRIMARY KEY (eventId, tagId, timestamp)
    )
  ''';

  Scan({required this.eventId, required this.tagId, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tagId': tagId,
      'eventId': eventId,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static Scan fromMap(Map<String, dynamic> map) {
    return Scan(
      tagId: map['tagId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      eventId: map['eventId'],
    );
  }

  @override
  String toString() {
    return 'Scan{eventId: $eventId, tagId: $tagId, timestamp: $timestamp}';
  }

  toCsv() {
    return '$tagId,${timestamp.millisecondsSinceEpoch}';
  }

  static Scan fromCsv(String csv, int eventId) {
    final parts = csv.split(',');
    return Scan(
      eventId: eventId,
      tagId: parts[0],
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1])),
    );
  }
}
