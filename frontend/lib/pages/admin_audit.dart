import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api.dart';
import '../widgets/status_banner.dart';

class AdminAuditPage extends StatefulWidget {
  final String token;
  const AdminAuditPage({super.key, required this.token});
  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  List<Map<String, dynamic>> actions = [];
  bool loading = true;
  String feedback = '';
  final adminCtrl = TextEditingController();
  final alvoCtrl = TextEditingController();
  final acaoCtrl = TextEditingController();
  int limit = 50;
  int offset = 0;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  Future<void> load() async {
    await Api.setTokens(widget.token, null);
    final params = {
      'limit': '$limit',
      'offset': '$offset',
      if (adminCtrl.text.trim().isNotEmpty) 'adminId': adminCtrl.text.trim(),
      if (alvoCtrl.text.trim().isNotEmpty) 'alvoId': alvoCtrl.text.trim(),
      if (acaoCtrl.text.trim().isNotEmpty) 'acao': acaoCtrl.text.trim(),
    };
    final query = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    final res = await Api.get('/moderation/actions?$query');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        actions = list.map<Map<String, dynamic>>((e) => {
          'id': e['id'] ?? '',
          'adminId': e['adminId'] ?? '',
          'alvoTipo': e['alvoTipo'] ?? '',
          'alvoId': e['alvoId'] ?? '',
          'acao': e['acao'] ?? '',
          'motivo': e['motivo'] ?? '',
          'createdAt': e['createdAt'] ?? '',
        }).toList();
      }
    } else {
      feedback = 'Erro ao carregar auditoria';
    }
    loading = false;
    setState(() {});
  }
  @override
  void initState() {
    super.initState();
    load();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Auditoria')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/login_bg.png'), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [brandBlack.withValues(alpha: 0.7), brandBlack.withValues(alpha: 0.3)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              child: Row(
                                children: const [
                                  Icon(Icons.receipt_long, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Auditoria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Expanded(child: TextField(controller: adminCtrl, decoration: const InputDecoration(labelText: 'Admin ID'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: TextField(controller: alvoCtrl, decoration: const InputDecoration(labelText: 'Alvo ID'))),
                                  const SizedBox(width: 8),
                                  Expanded(child: TextField(controller: acaoCtrl, decoration: const InputDecoration(labelText: 'Ação'))),
                                  const SizedBox(width: 8),
                                  ElevatedButton(onPressed: () { offset = 0; load(); }, child: const Text('Filtrar')),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: actions.length,
                                itemBuilder: (_, i) {
                                  final a = actions[i];
                                  return ListTile(
                                    title: Text('${a['acao']} • ${a['motivo']}'),
                                    subtitle: Text('Admin: ${a['adminId']} • ${a['alvoTipo']}:${a['alvoId']} • ${a['createdAt']}'),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton(onPressed: () { if (offset >= limit) { offset -= limit; load(); } }, child: const Text('Anterior')),
                                  const SizedBox(width: 8),
                                  OutlinedButton(onPressed: () { offset += limit; load(); }, child: const Text('Próximo')),
                                ],
                              ),
                            ),
                            if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: StatusBanner(text: feedback, type: 'error')),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
