

import 'event.dart';

class Scan {
  final String tagId;
  final EventId eventId;
  final DateTime timestamp;

  static const String tableName = 'scans';

  static const String createTable = '''
    CREATE TABLE $tableName (
      tagId TEXT,
      timestamp INTEGER,
      eventId INTEGER,
      FOREIGN KEY(eventId) REFERENCES ${Event.tableName}(id)
      PRIMARY KEY (tagId, timestamp)
    )
  ''';

  Scan({required this.tagId, required this.eventId, DateTime? timestamp})
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
    return 'Scan{tagId: $tagId, timestamp: $timestamp}';
  }
}
