import 'package:flutter/material.dart';

class AppModal extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;
  final EdgeInsets insetPadding;
  const AppModal({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.maxWidth = 720,
    this.insetPadding = const EdgeInsets.all(24),
  });
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: insetPadding,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                ],
              ),
              const SizedBox(height: 12),
              content,
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
