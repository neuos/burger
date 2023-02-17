import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

enum Status { success, warn, error }

class StatusCard extends StatelessWidget {
  const StatusCard({super.key, required this.status, required this.text});

  final Status status;
  final String text;

  @override
  Widget build(BuildContext context) {
    final themeData = GetIt.I.get<ThemeData>();
    final Color containerColor;
    final IconData icon;
    final Color color;

    switch (status) {
      case Status.success:
        containerColor = themeData.colorScheme.primaryContainer;
        icon = Icons.check_box;
        color = themeData.colorScheme.primary;
        break;
      case Status.warn:
        containerColor = themeData.colorScheme.errorContainer;
        icon = Icons.warning;
        color = themeData.colorScheme.error;
        break;
      case Status.error:
        containerColor = themeData.colorScheme.errorContainer;
        icon = Icons.error;
        color = themeData.colorScheme.error;
        break;
    }

    return Card(
      color: containerColor,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 128,
            ),
            Flexible(
              child: Text(
                text,
                style: TextStyle(color: color, fontSize: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
