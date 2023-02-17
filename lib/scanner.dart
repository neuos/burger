import 'package:logger/logger.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/platform_tags.dart';
import 'package:sqflite/utils/utils.dart';

Future<String> startScanner(Future<void> Function(String?) idCallback) async {
  final logger = Logger();

  bool isAvailable = await NfcManager.instance.isAvailable();
  if (!isAvailable) {
    var message = "NFC reader not available";
    logger.w(message);
    return message;
  }

  // Start Session
  await NfcManager.instance.startSession(
    onDiscovered: (NfcTag tag) => idCallback(getId(tag)),
    pollingOptions: {NfcPollingOption.iso14443},
  );

  return "Ready to scan";
}

stopScanner() async {
  await NfcManager.instance.stopSession();
}

String? getId(NfcTag tag) {
  final id = NfcA.from(tag)?.identifier ??
      NfcB.from(tag)?.identifier ??
      NfcF.from(tag)?.identifier ??
      NfcV.from(tag)?.identifier ??
      MiFare.from(tag)?.identifier ??
      MifareClassic.from(tag)?.identifier ??
      MifareUltralight.from(tag)?.identifier ??
      NdefFormatable.from(tag)?.identifier ??
      Iso7816.from(tag)?.identifier ??
      Iso15693.from(tag)?.identifier;

  if (id == null) {
    Logger().w("No ID found", tag.data);
    return null;
  }
  return hex(id);
}
