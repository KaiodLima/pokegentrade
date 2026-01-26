import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_modal.dart';

class AdminMarketplaceConfigPage extends StatefulWidget {
  final String token;
  const AdminMarketplaceConfigPage({super.key, required this.token});
  @override
  State<AdminMarketplaceConfigPage> createState() => _AdminMarketplaceConfigPageState();
}

class _AdminMarketplaceConfigPageState extends State<AdminMarketplaceConfigPage> {
  List<Map<String, String>> categories = [];
  List<Map<String, String>> servers = [];
  final catCtrl = TextEditingController();
  final srvCtrl = TextEditingController();
  String feedback = '';
  @override
  void initState() {
    super.initState();
    _load();
  }
  Future<void> _load() async {
    await Api.init();
    await Api.setTokens(widget.token, null);
    try {
      final rc = await Api.get('/marketplace/categories');
      if (rc.statusCode == 200) {
        final list = jsonDecode(rc.body);
        if (list is List) categories = list.map<Map<String, String>>((e) => {'id': (e['id'] ?? '').toString(), 'name': (e['name'] ?? '').toString()}).toList();
      }
      final rs = await Api.get('/marketplace/servers');
      if (rs.statusCode == 200) {
        final list = jsonDecode(rs.body);
        if (list is List) servers = list.map<Map<String, String>>((e) => {'id': (e['id'] ?? '').toString(), 'name': (e['name'] ?? '').toString()}).toList();
      }
    } catch (_) {}
    setState(() {});
  }
  Future<void> _createCategory() async {
    final name = catCtrl.text.trim();
    if (name.isEmpty) return;
    await Api.setTokens(widget.token, null);
    final res = await Api.post('/marketplace/categories', {'name': name});
    feedback = res.statusCode == 201 || res.statusCode == 200 ? 'Categoria criada' : 'Falha ao criar';
    catCtrl.clear();
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> _createServer() async {
    final name = srvCtrl.text.trim();
    if (name.isEmpty) return;
    await Api.setTokens(widget.token, null);
    final res = await Api.post('/marketplace/servers', {'name': name});
    feedback = res.statusCode == 201 || res.statusCode == 200 ? 'Servidor criado' : 'Falha ao criar';
    srvCtrl.clear();
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> _deleteCategory(String id) async {
    await Api.setTokens(widget.token, null);
    final res = await Api.delete('/marketplace/categories/$id');
    feedback = (res.statusCode == 200 || res.statusCode == 204) ? 'Categoria removida' : 'Falha ao remover';
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> _deleteServer(String id) async {
    await Api.setTokens(widget.token, null);
    final res = await Api.delete('/marketplace/servers/$id');
    feedback = (res.statusCode == 200 || res.statusCode == 204) ? 'Servidor removido' : 'Falha ao remover';
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final header = Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        gradient: LinearGradient(colors: [Color(0xFFD32F2F), Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.settings, color: Colors.white),
          const SizedBox(width: 8),
          const Text('Configurar Marketplace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
    return Scaffold(
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
                  colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.3)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      ClipRRect(borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)), child: header),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Categorias', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(child: TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Nova categoria'))),
                                      const SizedBox(width: 8),
                                      ElevatedButton(onPressed: _createCategory, child: const Text('Adicionar')),
                                    ]),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: categories.map((c) => Chip(label: Text(c['name'] ?? ''), onDeleted: () => _deleteCategory(c['id'] ?? ''))).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Servidores', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Row(children: [
                                      Expanded(child: TextField(controller: srvCtrl, decoration: const InputDecoration(labelText: 'Novo servidor'))),
                                      const SizedBox(width: 8),
                                      ElevatedButton(onPressed: _createServer, child: const Text('Adicionar')),
                                    ]),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: servers.map((s) => Chip(label: Text(s['name'] ?? ''), onDeleted: () => _deleteServer(s['id'] ?? ''))).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
