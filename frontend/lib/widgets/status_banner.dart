import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  final String text;
  final String type;
  final String? actionText;
  final VoidCallback? onAction;
  const StatusBanner({super.key, required this.text, this.type = 'info', this.actionText, this.onAction});
  Color _bg(BuildContext context) {
    switch (type) {
      case 'error':
        return Colors.red.shade100;
      case 'success':
        return Colors.green.shade100;
      case 'warning':
        return Colors.orange.shade100;
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }
  Color _fg(BuildContext context) {
    switch (type) {
      case 'error':
        return Colors.red.shade900;
      case 'success':
        return Colors.green.shade900;
      case 'warning':
        return Colors.orange.shade900;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: _bg(context), borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(color: _fg(context)))),
          if (actionText != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionText!, style: TextStyle(color: _fg(context)))),
        ],
      ),
    );
  }
}
