import 'dart:typed_data';

import 'package:sqflite/utils/utils.dart';

class Scan {
  final Uint8List tagId;
  final DateTime timestamp;

  static const String tableName = 'scans';

  static const String createTable = '''
    CREATE TABLE $tableName (
      tagId TEXT,
      timestamp INTEGER,
      PRIMARY KEY (tagId, timestamp)
    )
  ''';

  Scan({required this.tagId, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tagId': hex(tagId),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  static Scan fromMap(Map<String, dynamic> map) {
    return Scan(
      tagId: Uint8List.map['tagId'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  String toString() {
    return 'Scan{tagId: $tagId, timestamp: $timestamp}';
  }
}
