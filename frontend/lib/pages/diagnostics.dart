import 'package:flutter/material.dart';
import '../services/api.dart';
import '../widgets/status_banner.dart';
import '../l10n/app_localizations.dart';

class DiagnosticsPage extends StatefulWidget {
  const DiagnosticsPage({super.key});
  @override
  State<DiagnosticsPage> createState() => _DiagnosticsPageState();
}

class _DiagnosticsPageState extends State<DiagnosticsPage> {
  Map<String, int> stats = Api.diagnostics();
  void refresh() {
    setState(() => stats = Api.diagnostics());
  }
  void reset() {
    Api.requestCount = 0;
    Api.timeoutCount = 0;
    Api.networkErrorCount = 0;
    refresh();
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.diagnostics)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBanner(text: '${t.requests}: ${stats['requests']}', type: 'info'),
            const SizedBox(height: 8),
            StatusBanner(text: '${t.timeouts}: ${stats['timeouts']}', type: 'warning'),
            const SizedBox(height: 8),
            StatusBanner(text: '${t.networkErrors}: ${stats['networkErrors']}', type: 'error'),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(onPressed: refresh, child: Text(t.update)),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: reset, child: Text(t.reset)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
