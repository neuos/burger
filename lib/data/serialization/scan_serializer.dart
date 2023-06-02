import 'dart:io';

import 'package:burger/data/model/event.dart';
import 'package:burger/data/model/scan.dart';
import 'package:burger/data/repository/event_repository.dart';
import 'package:burger/data/repository/scan_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

abstract class IScanSerializer {
  Future<void> export(Event event);

  Future<void> import(Event event);

  Future<void> importNew();
}

class ScanSerializer implements IScanSerializer {
  final _scanRepo = GetIt.I.get<IScanRepository>();
  final _eventRepo = GetIt.I.get<IEventRepository>();
  final _logger = Logger();

  @override
  Future<void> export(Event event) async {
    final fullHistory = await _scanRepo.findAll(event.id);
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat("dd.MM.yy-HH:mm:ss").format(fullHistory.last.timestamp);
    final filename = "${event.name} - $timestamp.csv";
    final file = File('${directory.path}/$filename');
    final csv = fullHistory.map((e) => e.toCsv()).join('\n');
    await file.writeAsString(csv);
    _logger.i("sharing $filename with ${fullHistory.length} scans");
    await Share.shareXFiles([XFile(file.path)], text: filename);
  }

  @override
  Future<void> import(Event event) async {
    final file = await _pickFile();
    if (file == null) {
      _logger.i('no file selected');
      return;
    }
    await _insertScans(file, event.id);
  }

  @override
  Future<void> importNew() async {
    final file = await _pickFile();
    if (file == null) {
      _logger.i('no file selected');
      return;
    }
    final name = file.path.split('/').last.split(" - ").first;
    final eventId = await _eventRepo.create(Event(name: name));
    await _insertScans(file, eventId);
  }

  Future<File?> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    final path = picked?.files.single.path;
    if (path == null) {
      return null;
    }
    return File(path);
  }

  Future<void> _insertScans(File file, int eventId) async {
    final lines = await file.readAsLines();
    if (lines.isEmpty) {
      _logger.w('no scans found');
      return;
    }
    final scans = lines.map((e) => Scan.fromCsv(e, eventId)).toList();
    for (final scan in scans) {
      _logger.i(scan);
      await _scanRepo.insert(scan);
    }
  }
}
