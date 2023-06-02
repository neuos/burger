import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'status.dart';

class ScanResult extends StatelessWidget {
  const ScanResult({super.key, required this.history, this.error});

  final List<DateTime> history;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final Status status;
    final String text;
    if (error != null) {
      status = Status.error;
      text = error!;
    } else if (history.length == 1) {
      status = Status.success;
      text = "Enjoy";
    } else {
      status = Status.warn;
      text = "Scanned ${history.length} times";
    }

    return Column(
      children: [
        StatusCard(
          status: status,
          text: text,
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: false,
            itemCount: history.length,
            itemBuilder: (context, index) {
              final date = history[index];
              return Card(
                child: ListTile(
                  title: Text(DateFormat("dd.MM.yy HH:mm:ss").format(date)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
