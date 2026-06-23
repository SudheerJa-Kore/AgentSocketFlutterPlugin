import 'package:flutter/material.dart';

import '../connection_status.dart';

class ChatStatusBar extends StatelessWidget {
  final ConnectionStatus status;

  const ChatStatusBar({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color foregroundColor;
    final Color textColor;
    final Widget leading;
    final String label;

    switch (status) {
      case ConnectionStatus.connected:
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade700;
        textColor = Colors.green.shade900;
        leading = Icon(Icons.check_circle, size: 16, color: foregroundColor);
        label = 'Connected';
        break;
      case ConnectionStatus.connecting:
        backgroundColor = Colors.blue.shade100;
        foregroundColor = Colors.blue.shade700;
        textColor = Colors.blue.shade900;
        leading = SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
          ),
        );
        label = 'Connecting…';
        break;
      case ConnectionStatus.notConnected:
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade700;
        textColor = Colors.orange.shade900;
        leading = Icon(Icons.warning, size: 16, color: foregroundColor);
        label = 'Not Connected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}
