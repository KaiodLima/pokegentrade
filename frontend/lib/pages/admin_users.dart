import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api.dart';
import '../widgets/status_banner.dart';

class AdminUsersPage extends StatefulWidget {
  final String token;
  const AdminUsersPage({super.key, required this.token});
  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> users = [];
  String feedback = '';
  bool loading = true;
  final searchCtrl = TextEditingController();
  String roleFilter = '';
  String statusFilter = '';
  int limit = 50;
  int offset = 0;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  Future<void> load() async {
    await Api.setTokens(widget.token, null);
    final params = {
      'limit': '$limit',
      'offset': '$offset',
      if (searchCtrl.text.trim().isNotEmpty) 'q': searchCtrl.text.trim(),
      if (roleFilter.isNotEmpty) 'role': roleFilter,
      if (statusFilter.isNotEmpty) 'status': statusFilter,
    };
    final query = params.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&');
    final res = await Api.get('/users?$query');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        users = list.map<Map<String, dynamic>>((e) => {
          'id': e['id'] ?? '',
          'email': e['email'] ?? '',
          'displayName': e['displayName'] ?? '',
          'role': e['role'] ?? 'User',
          'status': e['status'] ?? 'ativa',
          'createdAt': e['createdAt'] ?? '',
        }).toList();
      }
    } else {
      feedback = 'Erro ao carregar usuários';
    }
    loading = false;
    setState(() {});
  }
  Future<void> setRole(String id, String role) async {
    await Api.setTokens(widget.token, null);
    final res = await Api.patch('/users/$id/role', {'role': role});
    feedback = res.statusCode == 200 ? 'Atualizado' : 'Falha ao atualizar';
    setState(() {});
    await load();
  }
  Future<void> setStatus(String id, String status) async {
    await Api.setTokens(widget.token, null);
    final res = await Api.patch('/users/$id/status', {'status': status});
    feedback = res.statusCode == 200 ? 'Atualizado' : 'Falha ao atualizar';
    setState(() {});
    await load();
  }
  @override
  void initState() {
    super.initState();
    load();
  }
  @override
  Widget build(BuildContext context) {
    final list = users.where((u) {
      final q = searchCtrl.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return (u['email'] as String).toLowerCase().contains(q) || (u['displayName'] as String).toLowerCase().contains(q) || (u['id'] as String).toLowerCase().contains(q);
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin - Usuários')),
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
                                  Icon(Icons.group, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Usuários', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: searchCtrl,
                                      decoration: const InputDecoration(labelText: 'Buscar por nome, email ou ID'),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButton<String>(
                                    value: roleFilter.isEmpty ? null : roleFilter,
                                    hint: const Text('Papel'),
                                    items: const [
                                      DropdownMenuItem(value: 'User', child: Text('User')),
                                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                      DropdownMenuItem(value: 'SuperAdmin', child: Text('SuperAdmin')),
                                    ],
                                    onChanged: (v) { setState(() => roleFilter = v ?? ''); },
                                  ),
                                  const SizedBox(width: 8),
                                  DropdownButton<String>(
                                    value: statusFilter.isEmpty ? null : statusFilter,
                                    hint: const Text('Status'),
                                    items: const [
                                      DropdownMenuItem(value: 'ativa', child: Text('ativa')),
                                      DropdownMenuItem(value: 'suspensa', child: Text('suspensa')),
                                    ],
                                    onChanged: (v) { setState(() => statusFilter = v ?? ''); },
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () { offset = 0; load(); },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('Filtrar', style: TextStyle(color: Colors.white),),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final u = list[i];
                                  final role = (u['role'] ?? 'User').toString();
                                  final isSuper = role == 'SuperAdmin';
                                  return ListTile(
                                    title: Text('${u['displayName']} • ${u['email']}'),
                                    subtitle: Text('ID: ${u['id']} • ${u['status']} • ${u['createdAt']}'),
                                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isSuper ? Colors.black : (role == 'Admin' ? Colors.red : Colors.grey.shade300), borderRadius: BorderRadius.circular(10)), child: Text(role, style: TextStyle(color: isSuper ? Colors.white : (role == 'Admin' ? Colors.white : Colors.black)))),
                                      const SizedBox(width: 8),
                                      DropdownButton<String>(
                                        value: isSuper ? 'SuperAdmin' : role,
                                        items: const [
                                          DropdownMenuItem(value: 'User', child: Text('User')),
                                          DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                          DropdownMenuItem(value: 'SuperAdmin', child: Text('SuperAdmin')),
                                        ],
                                        onChanged: isSuper ? null : (v) {
                                          if (v == null || v == 'SuperAdmin') return;
                                          setRole(u['id'].toString(), v);
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: isSuper ? null : () => setStatus(u['id'].toString(), 'suspensa'),
                                        child: const Text('Suspender'),
                                      ),
                                      const SizedBox(width: 4),
                                      OutlinedButton(
                                        onPressed: isSuper ? null : () => setStatus(u['id'].toString(), 'ativa'),
                                        child: const Text('Reativar'),
                                      ),
                                    ]),
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
                            if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: StatusBanner(text: feedback, type: feedback == 'Atualizado' ? 'success' : 'error')),
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
