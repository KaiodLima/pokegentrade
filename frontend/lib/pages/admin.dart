import 'package:flutter/material.dart';
import 'dart:convert';
import 'marketplace_detail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../l10n/app_localizations.dart';
import '../services/sanitize.dart';
import '../services/api.dart';
import '../app/locator.dart';
import '../features/news/domain/usecases/create_news.dart';
import '../widgets/app_modal.dart';

class AdminPage extends StatefulWidget {
  final String token;
  final bool embedded;
  const AdminPage({super.key, required this.token, this.embedded = false});
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandLightRed = const Color.fromARGB(255, 157, 4, 4);
  List<Map<String, dynamic>> ads = [];
  List<Map<String, dynamic>> rooms = [];
  bool loading = true;
  String feedback = '';
  String statusFilter = 'todos';
  String typeFilter = 'todos';
  final minPriceCtrl = TextEditingController();
  final maxPriceCtrl = TextEditingController();
  final roomNameCtrl = TextEditingController();
  final roomDescCtrl = TextEditingController();
  final intervalCtrl = TextEditingController(text: '3');
  final perUserCtrl = TextEditingController(text: '0');
  bool roomSilenced = false;
  bool showRooms = false;
  String selectedSection = 'marketplace';
  final usersSearchCtrl = TextEditingController();
  String usersRoleFilter = '';
  String usersStatusFilter = '';
  int usersLimit = 50;
  int usersOffset = 0;
  final auditAdminCtrl = TextEditingController();
  final auditAlvoCtrl = TextEditingController();
  final auditAcaoCtrl = TextEditingController();
  int auditLimit = 50;
  int auditOffset = 0;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> actions = [];
  List<Map<String, dynamic>> newsItems = [];
  Future<void> loadNewsAdmin() async {
    await Api.init();
    final res = await Api.get('/news');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        newsItems = list.map<Map<String, dynamic>>((e) => {
          'id': (e['id'] ?? '').toString(),
          'title': (e['title'] ?? '').toString(),
          'content': (e['content'] ?? '').toString(),
          'createdAt': (e['createdAt'] ?? '').toString(),
          'attachments': (e['attachments'] is List) ? (e['attachments'] as List).map((x) => x.toString()).toList() : <String>[],
        }).toList();
      }
    }
    setState(() {});
  }
  Future<void> editNews(Map<String, dynamic> n) async {
    final titleCtrl = TextEditingController(text: (n['title'] ?? '').toString());
    final contentCtrl = TextEditingController(text: (n['content'] ?? '').toString());
    final ok = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Editar notícia'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
          TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Conteúdo')),
        ]),
        actions: [
          // TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Salvar', style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      );
    }) ?? false;
    if (!ok) return;
    await Api.setTokens(widget.token, null);
    final res = await Api.patch('/news/${n['id']}', {'title': titleCtrl.text.trim(), 'content': contentCtrl.text.trim()});
    feedback = res.statusCode == 200 ? 'Notícia atualizada' : 'Falha ao atualizar';
    setState(() {});
    await loadNewsAdmin();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> deleteNews(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Excluir notícia?'),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Confirmar', style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      );
    }) ?? false;
    if (!ok) return;
    await Api.setTokens(widget.token, null);
    final res = await Api.delete('/news/$id');
    feedback = (res.statusCode == 200 || res.statusCode == 204) ? 'Notícia excluída' : 'Falha ao excluir';
    setState(() {});
    await loadNewsAdmin();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> load() async {
    await Api.init();
    final tok = Api.currentAccessToken() ?? widget.token;
    await Api.setTokens(tok, null);
    final res = await Api.get('/marketplace/ads/admin');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        ads = list.map<Map<String, dynamic>>((e) => {
          'id': e['id'] ?? '',
          'title': e['title'] ?? '',
          'type': e['type'] ?? '',
          'price': e['price']?.toString() ?? '',
          'status': e['status'] ?? '',
          'createdAt': e['createdAt'] ?? '',
          'authorId': e['authorId'] ?? '',
          'attachments': e['attachments'] ?? [],
        }).toList();
      }
    }
    loading = false;
    setState(() {});
    await loadRoomsAdmin();
  }
  Future<void> loadRoomsAdmin() async {
    final res = await Api.get('/rooms');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        rooms = list.map<Map<String, dynamic>>((e) => {
          'id': (e['id'] ?? '').toString(),
          'name': (e['name'] ?? '').toString(),
          'description': (e['description'] ?? '').toString(),
          'imageUrl': (e['imageUrl'] ?? '').toString(),
          'intervalGlobalSeconds': ((e['rulesJson'] ?? {})['intervalGlobalSeconds'] ?? 3),
          'perUserSeconds': ((e['rulesJson'] ?? {})['perUserSeconds'] ?? 0),
          'silenced': (e['silenced'] ?? false) == true,
        }).toList();
        setState(() {});
      }
    }
  }
  Future<void> loadUsersAdmin() async {
    loading = true;
    setState(() {});
    await Api.init();
    final tok = Api.currentAccessToken() ?? widget.token;
    await Api.setTokens(tok, null);
    final params = {
      'limit': '$usersLimit',
      'offset': '$usersOffset',
      if (usersSearchCtrl.text.trim().isNotEmpty) 'q': usersSearchCtrl.text.trim(),
      if (usersRoleFilter.isNotEmpty) 'role': usersRoleFilter,
      if (usersStatusFilter.isNotEmpty) 'status': usersStatusFilter,
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
  Future<void> setUserRole(String id, String role) async {
    await Api.setTokens(widget.token, null);
    final res = await Api.patch('/users/$id/role', {'role': role});
    feedback = res.statusCode == 200 ? 'Atualizado' : 'Falha ao atualizar';
    setState(() {});
    await loadUsersAdmin();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> setUserStatus(String id, String status) async {
    await Api.setTokens(widget.token, null);
    final res = await Api.patch('/users/$id/status', {'status': status});
    feedback = res.statusCode == 200 ? 'Atualizado' : 'Falha ao atualizar';
    setState(() {});
    await loadUsersAdmin();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> loadAuditAdmin() async {
    loading = true;
    setState(() {});
    await Api.init();
    final tok = Api.currentAccessToken() ?? widget.token;
    await Api.setTokens(tok, null);
    final params = {
      'limit': '$auditLimit',
      'offset': '$auditOffset',
      if (auditAdminCtrl.text.trim().isNotEmpty) 'adminId': auditAdminCtrl.text.trim(),
      if (auditAlvoCtrl.text.trim().isNotEmpty) 'alvoId': auditAlvoCtrl.text.trim(),
      if (auditAcaoCtrl.text.trim().isNotEmpty) 'acao': auditAcaoCtrl.text.trim(),
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
  Future<void> editRoom(Map<String, dynamic> r) async {
    final nameCtrl = TextEditingController(text: r['name'] ?? '');
    final descCtrl = TextEditingController(text: r['description'] ?? '');
    final intervalCtrlE = TextEditingController(text: '${r['intervalGlobalSeconds'] ?? 3}');
    final perUserCtrlE = TextEditingController(text: '${r['perUserSeconds'] ?? 0}');
    bool silencedE = (r['silenced'] ?? false) == true;
    PlatformFile? roomImageFile;
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
      return StatefulBuilder(builder: (ctx, setDialog) {
        return AppModal(
          title: t.editRoom,
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.cancel)),
            const SizedBox(width: 6),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.save)),
          ],
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: t.title)),
            TextField(controller: descCtrl, decoration: InputDecoration(labelText: t.description)),
            TextField(controller: intervalCtrlE, decoration: const InputDecoration(labelText: 'Intervalo global (s)'), keyboardType: TextInputType.number),
            TextField(controller: perUserCtrlE, decoration: const InputDecoration(labelText: 'Intervalo por usuário (s)'), keyboardType: TextInputType.number),
            Row(children: [const Text('Silenciado'), StatefulBuilder(builder: (c, set) => Switch(value: silencedE, onChanged: (v) => set(() => silencedE = v)))]),
            const SizedBox(height: 8),
            StatefulBuilder(builder: (ctx2, set2) {
              return Row(children: [
                GestureDetector(
                  onTap: () async {
                    final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: false, type: FileType.custom, allowedExtensions: ['png','jpg','jpeg','gif','webp']);
                    if (res != null && res.files.isNotEmpty) {
                      set2(() => roomImageFile = res.files.first);
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(8)),
                    child: Text(t.selectPhoto),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(roomImageFile?.name ?? 'Nenhum arquivo', overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  if (roomImageFile?.bytes != null && {'png','jpg','jpeg','gif','webp'}.contains((roomImageFile!.extension ?? '').toLowerCase()))
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(roomImageFile!.bytes!, width: 60, height: 60, fit: BoxFit.cover)),
                ])),
              ]);
            }),
          ]),
        );
      });
    }) ?? false;
    if (!ok) return;
    String imageUrl = (r['imageUrl']?.toString() ?? '');
    if (roomImageFile?.bytes != null) {
      String ctype;
      final ext = (roomImageFile!.extension ?? '').toLowerCase();
      switch (ext) {
        case 'png': ctype = 'image/png'; break;
        case 'jpg':
        case 'jpeg': ctype = 'image/jpeg'; break;
        case 'gif': ctype = 'image/gif'; break;
        case 'webp': ctype = 'image/webp'; break;
        default: ctype = 'application/octet-stream';
      }
      final pres = await Api.post('/uploads', {'filename': roomImageFile!.name, 'contentType': ctype});
      if (pres.statusCode == 200 || pres.statusCode == 201) {
        final p = jsonDecode(pres.body);
        if ((p['method'] ?? '') == 'POST') {
          final uri = Uri.parse(p['postUrl']);
          final req = http.MultipartRequest('POST', uri);
          final fields = (p['fields'] as Map?) ?? {};
          fields.forEach((k, v) => req.fields[k] = v.toString());
          req.files.add(http.MultipartFile.fromBytes('file', roomImageFile!.bytes!, filename: roomImageFile!.name));
          final resp = await req.send();
          if (resp.statusCode == 204 || resp.statusCode == 201) {
            imageUrl = (p['objectUrl'] ?? '').toString();
          }
        } else {
          await http.put(Uri.parse(p['uploadUrl']), headers: {'Content-Type': ctype}, body: roomImageFile!.bytes);
          imageUrl = p['uploadUrl'].toString().split('?').first;
        }
      }
    }
    final body = {
      'name': nameCtrl.text.trim(),
      'description': descCtrl.text.trim(),
      'intervalGlobalSeconds': int.tryParse(intervalCtrlE.text) ?? 3,
      'perUserSeconds': int.tryParse(perUserCtrlE.text) ?? 0,
      'silenced': silencedE,
      'imageUrl': imageUrl,
    };
    final res = await Api.patch('/rooms/${r['id']}', body);
    feedback = (res.statusCode == 200) ? 'Sala atualizada' : 'Falha ao atualizar';
    setState(() {});
    await loadRoomsAdmin();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> deleteRoom(String id) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
      return AppModal(
        title: t.confirmDelete,
        actions: [
          TextButton(onPressed: () => Navigator.of(_).pop(false), child: Text(t.cancel)),
          const SizedBox(width: 6),
          ElevatedButton(onPressed: () => Navigator.of(_).pop(true), child: Text(t.confirm)),
        ],
        content: const SizedBox.shrink(),
      );
    }) ?? false;
    if (!ok) return;
    final res = await Api.delete('/rooms/$id');
    feedback = (res.statusCode == 200 || res.statusCode == 204) ? 'Sala excluída' : 'Falha ao excluir';
    setState(() {});
    await loadRoomsAdmin();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> approve(String id) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: Text(t.confirmApprove),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t.cancel, style: TextStyle(color: Colors.white),),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t.confirm, style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      );
    }) ?? false;
    if (!ok) return;
    await Api.setTokens(widget.token, null);
    final res = await Api.patch('/marketplace/ads/$id/approve', {});
    feedback = res.statusCode == 200 ? 'Aprovado' : 'Falha ao aprovar';
    setState(() {});
    await load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> complete(String id) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: Text(t.confirmComplete),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t.cancel, style: TextStyle(color: Colors.white),),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t.confirm, style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      );
    }) ?? false;
    if (!ok) return;
    await Api.setTokens(widget.token, null);
    final res = await Api.patch('/marketplace/ads/$id/complete', {});
    feedback = res.statusCode == 200 ? 'Concluído' : 'Falha ao concluir';
    setState(() {});
    await load();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  Future<void> suspendAuthor(String userId) async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: Text(t.confirmSuspend),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t.cancel, style: TextStyle(color: Colors.white),),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(t.confirm, style: TextStyle(color: Colors.white),),
            ),
          ),
        ],
      );
    }) ?? false;
    if (!ok) return;
    await Api.setTokens(widget.token, null);
    final res = await Api.post('/moderation/users/suspend', {'userId': userId, 'motivo': 'violação'});
    feedback = res.statusCode == 200 ? 'Autor suspenso' : 'Falha ao suspender';
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
  }
  @override
  void initState() {
    super.initState();
    load();
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1300),
        child: Row(
          children: [
            Expanded(
              flex: 5,
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
                                      gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.admin_panel_settings, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          selectedSection == 'marketplace'
                                              ? 'Admin • Marketplace'
                                              : selectedSection == 'rooms'
                                                  ? 'Admin • Salas'
                                              : selectedSection == 'users'
                                                      ? 'Admin • Usuários'
                                                      : selectedSection == 'audit'
                                                          ? 'Admin • Auditoria'
                                                          : 'Admin • Notícias',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selectedSection == 'rooms')
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          const SizedBox(height: 8),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: rooms.length,
                                            itemBuilder: (_, i) {
                                              final r = rooms[i];
                                              return cardRoomAdminWidget(room: r,);
                                            },
                                          ),
                                        ]),
                                      ),
                                    ),
                                  if (selectedSection == 'rooms')
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: FractionallySizedBox(
                                        widthFactor: 0.7,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final nameCtrlM = TextEditingController();
                                            final descCtrlM = TextEditingController();
                                            final intervalCtrlM = TextEditingController(text: '3');
                                            final perUserCtrlM = TextEditingController(text: '0');
                                            bool silencedM = false;
                                            PlatformFile? roomImageFile;
                                            final t = AppLocalizations.of(context);
                                            final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
                                              return StatefulBuilder(builder: (ctx, setDialog) {
                                                return AppModal(
                                                  title: t.createRoom,
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(t.cancel)),
                                                    const SizedBox(width: 6),
                                                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(t.confirm)),
                                                  ],
                                                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                                                    TextField(controller: nameCtrlM, decoration: const InputDecoration(labelText: 'Nome')),
                                                    TextField(controller: descCtrlM, decoration: const InputDecoration(labelText: 'Descrição')),
                                                    TextField(controller: intervalCtrlM, decoration: const InputDecoration(labelText: 'Intervalo global (s)'), keyboardType: TextInputType.number),
                                                    TextField(controller: perUserCtrlM, decoration: const InputDecoration(labelText: 'Intervalo por usuário (s)'), keyboardType: TextInputType.number),
                                                    Row(children: [const Text('Silenciado'), Switch(value: silencedM, onChanged: (v) => setDialog(() => silencedM = v))]),
                                                    const SizedBox(height: 8),
                                                    Row(children: [
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: false, type: FileType.custom, allowedExtensions: ['png','jpg','jpeg','gif','webp']);
                                                          if (res != null && res.files.isNotEmpty) setDialog(() => roomImageFile = res.files.first);
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(t.selectPhoto, style: const TextStyle(color: Colors.white),),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(child: Text(roomImageFile?.name ?? 'Nenhum arquivo', overflow: TextOverflow.ellipsis)),
                                                    ]),
                                                  ]),
                                                );
                                              });
                                            }) ?? false;
                                            if (!ok) return;
                                            final name = nameCtrlM.text.trim();
                                            if (name.isEmpty) {
                                              setState(() => feedback = 'Informe o nome do canal');
                                              return;
                                            }
                                            await Api.setTokens(widget.token, null);
                                            String imageUrl = '';
                                            if (roomImageFile?.bytes != null) {
                                              String ctype;
                                              final ext = (roomImageFile!.extension ?? '').toLowerCase();
                                              switch (ext) {
                                                case 'png': ctype = 'image/png'; break;
                                                case 'jpg':
                                                case 'jpeg': ctype = 'image/jpeg'; break;
                                                case 'gif': ctype = 'image/gif'; break;
                                                case 'webp': ctype = 'image/webp'; break;
                                                default: ctype = 'application/octet-stream';
                                              }
                                              final pres = await Api.post('/uploads', {'filename': roomImageFile!.name, 'contentType': ctype});
                                              if (pres.statusCode == 200 || pres.statusCode == 201) {
                                                final p = jsonDecode(pres.body);
                                                if ((p['method'] ?? '') == 'POST') {
                                                  final uri = Uri.parse(p['postUrl']);
                                                  final req = http.MultipartRequest('POST', uri);
                                                  final fields = (p['fields'] as Map?) ?? {};
                                                  fields.forEach((k, v) => req.fields[k] = v.toString());
                                                  req.files.add(http.MultipartFile.fromBytes('file', roomImageFile!.bytes!, filename: roomImageFile!.name));
                                                  final resp = await req.send();
                                                  if (resp.statusCode == 204 || resp.statusCode == 201) {
                                                    imageUrl = (p['objectUrl'] ?? '').toString();
                                                  }
                                                } else {
                                                  await http.put(Uri.parse(p['uploadUrl']), headers: {'Content-Type': ctype}, body: roomImageFile!.bytes);
                                                  imageUrl = p['uploadUrl'].toString().split('?').first;
                                                }
                                              }
                                            }
                                            final body = {
                                              'name': name,
                                              'description': descCtrlM.text.trim(),
                                              'intervalGlobalSeconds': int.tryParse(intervalCtrlM.text) ?? 3,
                                              'perUserSeconds': int.tryParse(perUserCtrlM.text) ?? 0,
                                              'silenced': silencedM,
                                              'imageUrl': imageUrl,
                                            };
                                            final res = await Api.post('/rooms', body);
                                            feedback = (res.statusCode == 200 || res.statusCode == 201) ? 'Canal criado' : 'Falha ao criar canal';
                                            setState(() {});
                                            await loadRoomsAdmin();
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: brandRed,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(child: const Text('Criar sala', style: TextStyle(color: Colors.white),)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (selectedSection == 'marketplace')
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Text('${t.status}:'),
                                          const SizedBox(width: 8),
                                          DropdownButton<String>(
                                            value: statusFilter,
                                            items: [
                                              DropdownMenuItem(value: 'todos', child: Text(t.all)),
                                              DropdownMenuItem(value: 'pendente', child: Text(t.pending)),
                                              DropdownMenuItem(value: 'aprovado', child: Text(t.approved)),
                                              DropdownMenuItem(value: 'concluido', child: Text(t.completed)),
                                            ],
                                            onChanged: (v) => setState(() => statusFilter = v ?? 'todos'),
                                          ),
                                          const SizedBox(width: 16),
                                          Text('${t.type}:'),
                                          const SizedBox(width: 8),
                                          DropdownButton<String>(
                                            value: typeFilter,
                                            items: [
                                              DropdownMenuItem(value: 'todos', child: Text(t.all)),
                                              DropdownMenuItem(value: 'venda', child: Text(t.sale)),
                                              DropdownMenuItem(value: 'compra', child: Text(t.buy)),
                                              DropdownMenuItem(value: 'troca', child: Text(t.trade)),
                                            ],
                                            onChanged: (v) => setState(() => typeFilter = v ?? 'todos'),
                                          ),
                                          const SizedBox(width: 16),
                                          SizedBox(width: 100, child: TextField(controller: minPriceCtrl, decoration: InputDecoration(labelText: t.minPrice), keyboardType: TextInputType.number)),
                                          const SizedBox(width: 8),
                                          SizedBox(width: 100, child: TextField(controller: maxPriceCtrl, decoration: InputDecoration(labelText: t.maxPrice), keyboardType: TextInputType.number)),
                                        ],
                                      ),
                                    ),
                                  if (selectedSection == 'marketplace')
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: ads.where((a) {
                                          final statusOk = statusFilter == 'todos' ? true : a['status'] == statusFilter;
                                          final typeOk = typeFilter == 'todos' ? true : a['type'] == typeFilter;
                                          final price = double.tryParse((a['price'] ?? '').toString()) ?? 0.0;
                                          final min = double.tryParse(minPriceCtrl.text) ?? double.negativeInfinity;
                                          final max = double.tryParse(maxPriceCtrl.text) ?? double.infinity;
                                          final priceOk = price >= min && price <= max;
                                          return statusOk && typeOk && priceOk;
                                        }).length,
                                        itemBuilder: (_, i) {
                                          final filtered = ads.where((a) {
                                            final statusOk = statusFilter == 'todos' ? true : a['status'] == statusFilter;
                                            final typeOk = typeFilter == 'todos' ? true : a['type'] == typeFilter;
                                            final price = double.tryParse((a['price'] ?? '').toString()) ?? 0.0;
                                            final min = double.tryParse(minPriceCtrl.text) ?? double.negativeInfinity;
                                            final max = double.tryParse(maxPriceCtrl.text) ?? double.infinity;
                                            final priceOk = price >= min && price <= max;
                                            return statusOk && typeOk && priceOk;
                                          }).toList();
                                          final a = filtered[i];
                                          final atts = (a['attachments'] as List? ?? []);
                                          final firstImg = atts.cast<Map>().firstWhere((x) => (x['type']?.toString() ?? '').startsWith('image/'), orElse: () => {});
                                          final imgUrl = Sanitize.sanitizeImageUrl((firstImg['url']?.toString() ?? ''));

                                          return cardAdAdminWidget(ad: a, t: t, imgUrl: imgUrl);
                                          
                                        },
                                      ),
                                    ),
                                  if (selectedSection == 'marketplace')
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: FractionallySizedBox(
                                        widthFactor: 0.7,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final result = await showDialog<Map<String, dynamic>>(context: context, builder: (_) {
                                              String current = 'venda';
                                              final titleCtrl = TextEditingController();
                                              final descCtrl = TextEditingController();
                                              final priceCtrl = TextEditingController();
                                              PlatformFile? imageFile;
                                              return StatefulBuilder(builder: (ctx, setStateDialog) {
                                                return AlertDialog(
                                                  title: const Text('Novo anúncio'),
                                                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                                                    DropdownButtonFormField<String>(
                                                      initialValue: current,
                                                      items: const [
                                                        DropdownMenuItem(value: 'venda', child: Text('Venda')),
                                                        DropdownMenuItem(value: 'compra', child: Text('Compra')),
                                                        DropdownMenuItem(value: 'troca', child: Text('Troca')),
                                                      ],
                                                      onChanged: (v) => setStateDialog(() => current = v ?? 'venda'),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
                                                    const SizedBox(height: 8),
                                                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
                                                    const SizedBox(height: 8),
                                                    TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Preço'), keyboardType: TextInputType.number),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () async {
                                                            final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: false, type: FileType.custom, allowedExtensions: ['png','jpg','jpeg','gif','webp']);
                                                            if (res != null && res.files.isNotEmpty) {
                                                              setStateDialog(() => imageFile = res.files.first);
                                                            }
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: const Text('Selecionar imagem', style: TextStyle(color: Colors.white),),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(child: Text(imageFile?.name ?? 'Nenhuma imagem selecionada', overflow: TextOverflow.ellipsis)),
                                                      ],
                                                    ),
                                                  ]),
                                                  actions: [
                                                    GestureDetector(
                                                      onTap: () => Navigator.of(context).pop(null),
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.of(context).pop({
                                                          'type': current,
                                                          'title': titleCtrl.text.trim(),
                                                          'description': descCtrl.text.trim(),
                                                          'price': double.tryParse(priceCtrl.text),
                                                          'file': imageFile,
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Text('Criar', style: TextStyle(color: Colors.white),),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              });
                                            });
                                            if (result != null) {
                                              await Api.setTokens(widget.token, null);
                                              final res = await Api.post('/marketplace/ads', {
                                                'type': result['type'],
                                                'title': result['title'],
                                                'description': result['description'],
                                                'price': result['price'],
                                              });
                                              if (res.statusCode == 200 || res.statusCode == 201) {
                                                final ad = jsonDecode(res.body);
                                                final PlatformFile? f = result['file'] as PlatformFile?;
                                                if (f != null && f.bytes != null) {
                                                  String ctype;
                                                  final ext = (f.extension ?? '').toLowerCase();
                                                  switch (ext) {
                                                    case 'png': ctype = 'image/png'; break;
                                                    case 'jpg':
                                                    case 'jpeg': ctype = 'image/jpeg'; break;
                                                    case 'gif': ctype = 'image/gif'; break;
                                                    case 'webp': ctype = 'image/webp'; break;
                                                    default: ctype = 'application/octet-stream';
                                                  }
                                                  final pres = await Api.post('/uploads', {'filename': f.name, 'contentType': ctype});
                                                  if (pres.statusCode == 200 || pres.statusCode == 201) {
                                                    final p = jsonDecode(pres.body);
                                                    String objectUrl = '';
                                                    if ((p['method'] ?? '') == 'POST') {
                                                      final uri = Uri.parse(p['postUrl']);
                                                      final req = http.MultipartRequest('POST', uri);
                                                      final fields = (p['fields'] as Map?) ?? {};
                                                      fields.forEach((k, v) => req.fields[k] = v.toString());
                                                      req.files.add(http.MultipartFile.fromBytes('file', f.bytes!, filename: f.name));
                                                      final resp = await req.send();
                                                      if (resp.statusCode == 204 || resp.statusCode == 201) {
                                                        objectUrl = (p['objectUrl'] ?? '').toString();
                                                      }
                                                    } else {
                                                      await http.put(Uri.parse(p['uploadUrl']), headers: {'Content-Type': ctype}, body: f.bytes);
                                                      objectUrl = p['uploadUrl'].toString().split('?').first;
                                                    }
                                                    if (objectUrl.isNotEmpty) {
                                                      await Api.post('/marketplace/ads/${ad['id']}/attachments', {'url': objectUrl, 'type': ctype, 'meta': {'size': f.size}});
                                                    }
                                                  }
                                                }
                                                feedback = 'Anúncio criado';
                                                setState(() {});
                                                await load();
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                                              } else {
                                                feedback = 'Falha ao criar anúncio';
                                                setState(() {});
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: brandRed,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(child: const Text('Novo anúncio', style: TextStyle(color: Colors.white),)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (selectedSection == 'marketplace')
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(feedback),
                                    ),
                                  if (selectedSection == 'users')
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: usersSearchCtrl,
                                              decoration: const InputDecoration(labelText: 'Buscar por nome, email ou ID'),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          DropdownButton<String>(
                                            value: usersRoleFilter.isEmpty ? null : usersRoleFilter,
                                            hint: const Text('Papel'),
                                            items: const [
                                              DropdownMenuItem(value: 'User', child: Text('User')),
                                              DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                              DropdownMenuItem(value: 'SuperAdmin', child: Text('SuperAdmin')),
                                            ],
                                            onChanged: (v) { setState(() => usersRoleFilter = v ?? ''); },
                                          ),
                                          const SizedBox(width: 8),
                                          DropdownButton<String>(
                                            value: usersStatusFilter.isEmpty ? null : usersStatusFilter,
                                            hint: const Text('Status'),
                                            items: const [
                                              DropdownMenuItem(value: 'ativa', child: Text('ativa')),
                                              DropdownMenuItem(value: 'suspensa', child: Text('suspensa')),
                                            ],
                                            onChanged: (v) { setState(() => usersStatusFilter = v ?? ''); },
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () { usersOffset = 0; loadUsersAdmin(); },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('Filtrar', style: TextStyle(color: Colors.white),),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (selectedSection == 'users')
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: users.where((u) {
                                          final q = usersSearchCtrl.text.trim().toLowerCase();
                                          if (q.isEmpty) return true;
                                          return (u['email'] as String).toLowerCase().contains(q) || (u['displayName'] as String).toLowerCase().contains(q) || (u['id'] as String).toLowerCase().contains(q);
                                        }).length,
                                        itemBuilder: (_, i) {
                                          final filtered = users.where((u) {
                                            final q = usersSearchCtrl.text.trim().toLowerCase();
                                            if (q.isEmpty) return true;
                                            return (u['email'] as String).toLowerCase().contains(q) || (u['displayName'] as String).toLowerCase().contains(q) || (u['id'] as String).toLowerCase().contains(q);
                                          }).toList();
                                          final u = filtered[i];
                                          final role = (u['role'] ?? 'User').toString();
                                          final isSuper = role == 'SuperAdmin';
                                          return ListTile(
                                            leading: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: ((u['avatarUrl'] ?? '') as String).isNotEmpty
                                                  ? Image.network((u['avatarUrl'] ?? ''), width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.person)))
                                                  : Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.person)),
                                            ),
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
                                                  setUserRole(u['id'].toString(), v);
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(onPressed: isSuper ? null : () => setUserStatus(u['id'].toString(), 'suspensa'), child: const Text('Suspender')),
                                              const SizedBox(width: 4),
                                              OutlinedButton(onPressed: isSuper ? null : () => setUserStatus(u['id'].toString(), 'ativa'), child: const Text('Reativar')),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () async {
                                                  final emailCtrl = TextEditingController(text: (u['email'] ?? '').toString());
                                                  final nameCtrl = TextEditingController(text: (u['displayName'] ?? '').toString());
                                                  String roleM = role;
                                                  String statusM = (u['status'] ?? 'ativa').toString();
                                                  final pwdCtrl = TextEditingController();
                                                  PlatformFile? avatarFile;
                                                  final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
                                                    return StatefulBuilder(builder: (ctx, setDialog) {
                                                      return AppModal(
                                                        title: 'Editar usuário',
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                                          const SizedBox(width: 6),
                                                          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Salvar')),
                                                        ],
                                                        content: Column(mainAxisSize: MainAxisSize.min, children: [
                                                          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                                                          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
                                                          TextField(controller: pwdCtrl, decoration: const InputDecoration(labelText: 'Senha (opcional)')),
                                                          DropdownButton<String>(value: roleM, items: const [
                                                            DropdownMenuItem(value: 'User', child: Text('User')),
                                                            DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                                          ], onChanged: (v) => setDialog(() => roleM = v ?? 'User')),
                                                          DropdownButton<String>(value: statusM, items: const [
                                                            DropdownMenuItem(value: 'ativa', child: Text('ativa')),
                                                            DropdownMenuItem(value: 'suspensa', child: Text('suspensa')),
                                                          ], onChanged: (v) => setDialog(() => statusM = v ?? 'ativa')),
                                                          Row(children: [
                                                            GestureDetector(
                                                              onTap: () async {
                                                                final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: false, type: FileType.custom, allowedExtensions: ['png','jpg','jpeg','gif','webp']);
                                                                if (res != null && res.files.isNotEmpty) setDialog(() => avatarFile = res.files.first);
                                                              },
                                                              child: Container(
                                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: Colors.grey,
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                          child: Text(t.selectAvatar, style: const TextStyle(color: Colors.white),),
                                                              ),
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Expanded(child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(avatarFile?.name ?? 'Nenhum arquivo', overflow: TextOverflow.ellipsis),
                                                                const SizedBox(height: 6),
                                                                if (avatarFile?.bytes != null && {'png','jpg','jpeg','gif','webp'}.contains((avatarFile!.extension ?? '').toLowerCase()))
                                                                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(avatarFile!.bytes!, width: 60, height: 60, fit: BoxFit.cover)),
                                                              ],
                                                            )),
                                                          ]),
                                                        ]),
                                                      );
                                                    });
                                                  }) ?? false;
                                                  if (!ok) return;
                                                  await Api.setTokens(widget.token, null);
                                                  String avatarUrl = '';
                                                  if (avatarFile?.bytes != null) {
                                                    String ctype;
                                                    final ext = (avatarFile!.extension ?? '').toLowerCase();
                                                    switch (ext) {
                                                      case 'png': ctype = 'image/png'; break;
                                                      case 'jpg':
                                                      case 'jpeg': ctype = 'image/jpeg'; break;
                                                      case 'gif': ctype = 'image/gif'; break;
                                                      case 'webp': ctype = 'image/webp'; break;
                                                      default: ctype = 'application/octet-stream';
                                                    }
                                                    final pres = await Api.post('/uploads', {'filename': avatarFile!.name, 'contentType': ctype});
                                                    if (pres.statusCode == 200 || pres.statusCode == 201) {
                                                      final p = jsonDecode(pres.body);
                                                      if ((p['method'] ?? '') == 'POST') {
                                                        final uri = Uri.parse(p['postUrl']);
                                                        final req = http.MultipartRequest('POST', uri);
                                                        final fields = (p['fields'] as Map?) ?? {};
                                                        fields.forEach((k, v) => req.fields[k] = v.toString());
                                                        req.files.add(http.MultipartFile.fromBytes('file', avatarFile!.bytes!, filename: avatarFile!.name));
                                                        final resp = await req.send();
                                                        if (resp.statusCode == 204 || resp.statusCode == 201) {
                                                          avatarUrl = (p['objectUrl'] ?? '').toString();
                                                        }
                                                      } else {
                                                        await http.put(Uri.parse(p['uploadUrl']), headers: {'Content-Type': ctype}, body: avatarFile!.bytes);
                                                        avatarUrl = p['uploadUrl'].toString().split('?').first;
                                                      }
                                                    }
                                                  }
                                                  final res = await Api.patch('/users/${u['id']}', {'email': emailCtrl.text.trim(), 'displayName': nameCtrl.text.trim(), 'role': roleM, 'status': statusM, 'password': pwdCtrl.text.trim(), 'avatarUrl': avatarUrl});
                                                  feedback = res.statusCode == 200 ? 'Usuário atualizado' : 'Falha ao atualizar';
                                                  if (mounted) setState(() {});
                                                  await loadUsersAdmin();
                                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text('Editar', style: TextStyle(color: Colors.white),),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () async {
                                                  final ok = await showDialog<bool>(context: context, builder: (_) {
                                                    return AlertDialog(
                                                      title: const Text('Excluir usuário?'),
                                                      actions: [
                                                        GestureDetector(
                                                          onTap: () => Navigator.of(context).pop(false),
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: () => Navigator.of(context).pop(true),
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: const Text('Confirmar', style: TextStyle(color: Colors.white),),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }) ?? false;
                                                  if (!ok) return;
                                                  await Api.setTokens(widget.token, null);
                                                  final res = await Api.delete('/users/${u['id']}');
                                                  feedback = (res.statusCode == 200 || res.statusCode == 204) ? 'Usuário excluído' : 'Falha ao excluir';
                                                  setState(() {});
                                                  await loadUsersAdmin();
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text('Excluir', style: TextStyle(color: Colors.white),),
                                                ),
                                              ),
                                            ]),
                                          );
                                        },
                                      ),
                                    ),
                                  if (selectedSection == 'users')
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: FractionallySizedBox(
                                        widthFactor: 0.7,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final emailCtrl = TextEditingController();
                                            final nameCtrl = TextEditingController();
                                            String roleM = 'User';
                                            String statusM = 'ativa';
                                            final pwdCtrl = TextEditingController();
                                            PlatformFile? avatarFile;
                                            final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
                                              return StatefulBuilder(builder: (ctx, setDialog) {
                                                return AppModal(
                                                  title: t.newUser,
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                                    const SizedBox(width: 6),
                                                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Criar')),
                                                  ],
                                                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                                                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                                                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
                                                    TextField(controller: pwdCtrl, decoration: const InputDecoration(labelText: 'Senha')),
                                                    DropdownButton<String>(value: roleM, items: const [
                                                      DropdownMenuItem(value: 'User', child: Text('User')),
                                                      DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                                                    ], onChanged: (v) => setDialog(() => roleM = v ?? 'User')),
                                                    DropdownButton<String>(value: statusM, items: const [
                                                      DropdownMenuItem(value: 'ativa', child: Text('ativa')),
                                                      DropdownMenuItem(value: 'suspensa', child: Text('suspensa')),
                                                    ], onChanged: (v) => setDialog(() => statusM = v ?? 'ativa')),
                                                      Row(children: [
                                                        GestureDetector(
                                                          onTap: () async {
                                                            final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: false, type: FileType.custom, allowedExtensions: ['png','jpg','jpeg','gif','webp']);
                                                            if (res != null && res.files.isNotEmpty) setDialog(() => avatarFile = res.files.first);
                                                          },
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: Colors.grey,
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                          child: Text(t.selectAvatar, style: const TextStyle(color: Colors.white),),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(avatarFile?.name ?? 'Nenhum arquivo', overflow: TextOverflow.ellipsis),
                                                            const SizedBox(height: 6),
                                                            if (avatarFile?.bytes != null && {'png','jpg','jpeg','gif','webp'}.contains((avatarFile!.extension ?? '').toLowerCase()))
                                                              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(avatarFile!.bytes!, width: 60, height: 60, fit: BoxFit.cover)),
                                                          ],
                                                        )),
                                                      ]),
                                                  ]),
                                                );
                                              });
                                            }) ?? false;
                                            if (!ok) return;
                                            await Api.setTokens(widget.token, null);
                                            String avatarUrl = '';
                                            if (avatarFile?.bytes != null) {
                                              String ctype;
                                              final ext = (avatarFile!.extension ?? '').toLowerCase();
                                              switch (ext) {
                                                case 'png': ctype = 'image/png'; break;
                                                case 'jpg':
                                                case 'jpeg': ctype = 'image/jpeg'; break;
                                                case 'gif': ctype = 'image/gif'; break;
                                                case 'webp': ctype = 'image/webp'; break;
                                                default: ctype = 'application/octet-stream';
                                              }
                                              final pres = await Api.post('/uploads', {'filename': avatarFile!.name, 'contentType': ctype});
                                              if (pres.statusCode == 200 || pres.statusCode == 201) {
                                                final p = jsonDecode(pres.body);
                                                if ((p['method'] ?? '') == 'POST') {
                                                  final uri = Uri.parse(p['postUrl']);
                                                  final req = http.MultipartRequest('POST', uri);
                                                  final fields = (p['fields'] as Map?) ?? {};
                                                  fields.forEach((k, v) => req.fields[k] = v.toString());
                                                  req.files.add(http.MultipartFile.fromBytes('file', avatarFile!.bytes!, filename: avatarFile!.name));
                                                  final resp = await req.send();
                                                  if (resp.statusCode == 204 || resp.statusCode == 201) {
                                                    avatarUrl = (p['objectUrl'] ?? '').toString();
                                                  }
                                                } else {
                                                  await http.put(Uri.parse(p['uploadUrl']), headers: {'Content-Type': ctype}, body: avatarFile!.bytes);
                                                  avatarUrl = p['uploadUrl'].toString().split('?').first;
                                                }
                                              }
                                            }
                                            final res = await Api.post('/users', {'email': emailCtrl.text.trim(), 'displayName': nameCtrl.text.trim(), 'role': roleM, 'status': statusM, 'password': pwdCtrl.text.trim(), 'avatarUrl': avatarUrl});
                                            feedback = (res.statusCode == 200 || res.statusCode == 201) ? 'Usuário criado' : 'Falha ao criar usuário';
                                            if (mounted) setState(() {});
                                            await loadUsersAdmin();
                                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: brandRed,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(child: Text(t.newUser, style: const TextStyle(color: Colors.white),)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (selectedSection == 'audit')
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(child: TextField(controller: auditAdminCtrl, decoration: const InputDecoration(labelText: 'Admin ID'))),
                                          const SizedBox(width: 8),
                                          Expanded(child: TextField(controller: auditAlvoCtrl, decoration: const InputDecoration(labelText: 'Alvo ID'))),
                                          const SizedBox(width: 8),
                                          Expanded(child: TextField(controller: auditAcaoCtrl, decoration: const InputDecoration(labelText: 'Ação'))),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () { auditOffset = 0; loadAuditAdmin(); },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Text('Filtrar', style: TextStyle(color: Colors.white),),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (selectedSection == 'audit')
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
                                  if (selectedSection == 'news')
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          const SizedBox(height: 8),
                                          ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: newsItems.length,
                                            itemBuilder: (_, i) {
                                              final n = newsItems[i];
                                              return cardNewsAdminWidget(newRegitered: n,);
                                            },
                                          ),
                                        ]),
                                      ),
                                    ),
                                  if (selectedSection == 'news')
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: FractionallySizedBox(
                                        widthFactor: 0.7,
                                        child: GestureDetector(
                                          onTap: () async {
                                            final titleCtrl = TextEditingController();
                                            final contentCtrl = TextEditingController();
                                            List<String> attachments = [];
                                            final ok = await showDialog<bool>(context: context, builder: (_) {
                                              return StatefulBuilder(builder: (ctx, set) {
                                                return AlertDialog(
                                                  title: const Text('Nova notícia'),
                                                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                                                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
                                                    TextField(controller: contentCtrl, decoration: const InputDecoration(labelText: 'Conteúdo')),
                                                    const SizedBox(height: 8),
                                                    Row(children: [
                                                      GestureDetector(
                                                        onTap: () async {
                                                          final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: true);
                                                          if (res == null || res.files.isEmpty) return;
                                                          for (final f in res.files) {
                                                            final allowedExt = {'png','jpg','jpeg','gif','webp'};
                                                            final ext = (f.extension ?? '').toLowerCase();
                                                            if (!allowedExt.contains(ext) || (f.bytes == null)) continue;
                                                            final ct = ext == 'png' ? 'image/png' : (ext == 'gif' ? 'image/gif' : (ext == 'webp' ? 'image/webp' : 'image/jpeg'));
                                                            final pres = await Api.post('/uploads', {'filename': f.name, 'contentType': ct});
                                                            if (!(pres.statusCode == 200 || pres.statusCode == 201)) continue;
                                                            final p = jsonDecode(pres.body);
                                                            String objectUrl = '';
                                                            if ((p['method'] ?? '') == 'POST') {
                                                              final uri = Uri.parse(p['postUrl']);
                                                              final req = http.MultipartRequest('POST', uri);
                                                              final fields = (p['fields'] as Map?) ?? {};
                                                              fields.forEach((k, v) => req.fields[k] = v.toString());
                                                              req.files.add(http.MultipartFile.fromBytes('file', f.bytes!, filename: f.name));
                                                              final resp = await req.send();
                                                              if (resp.statusCode == 204 || resp.statusCode == 201) {
                                                                objectUrl = (p['objectUrl'] ?? '').toString();
                                                              }
                                                            } else {
                                                              await http.put(Uri.parse(p['uploadUrl']), headers: {'Content-Type': ct}, body: f.bytes);
                                                              objectUrl = p['uploadUrl'].toString().split('?').first;
                                                            }
                                                            if (objectUrl.isNotEmpty) {
                                                              attachments.add(objectUrl);
                                                            }
                                                          }
                                                          set(() {});
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: const Text('Selecionar imagens', style: TextStyle(color: Colors.white),),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(attachments.isEmpty ? 'Nenhuma imagem' : '${attachments.length} imagem(ns) adicionada(s)'),
                                                    ]),
                                                  ]),
                                                  actions: [
                                                    GestureDetector(
                                                      onTap: () => Navigator.of(context).pop(false),
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => Navigator.of(context).pop(true),
                                                      child: Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Text('Salvar', style: TextStyle(color: Colors.white),),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              });
                                            }) ?? false;
                                            if (!ok) return;
                                            if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Título e conteúdo são obrigatórios')));
                                              return;
                                            }
                                            await Api.setTokens(widget.token, null);
                                            final usecase = CreateNewsUseCase(Locator.news);
                                            final r = await usecase(title: titleCtrl.text.trim(), content: contentCtrl.text.trim(), attachments: attachments);
                                            feedback = r.isOk ? 'Notícia criada' : 'Falha ao criar notícia';
                                            setState(() {});
                                            await loadNewsAdmin();
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: brandRed,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(child: const Text('Nova notícia', style: TextStyle(color: Colors.white),)),
                                          ),
                                        ),
                                      ),
                                    ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 260,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              child: Row(
                                children: const [
                                  Icon(Icons.menu, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                selectedSection = 'marketplace';
                                loading = true;
                                setState(() {});
                                load();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedSection == 'marketplace'? brandLightRed: brandRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Marketplace', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                selectedSection = 'users';
                                loading = true;
                                setState(() {});
                                loadUsersAdmin();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedSection == 'users'? brandLightRed: brandRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Usuários', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                selectedSection = 'audit';
                                loading = true;
                                setState(() {});
                                loadAuditAdmin();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedSection == 'audit'? brandLightRed: brandRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Auditoria', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                selectedSection = 'rooms';
                                loading = true;
                                setState(() {});
                                await loadRoomsAdmin();
                                loading = false;
                                setState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedSection == 'rooms'? brandLightRed: brandRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Salas', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () async {
                                selectedSection = 'news';
                                loading = true;
                                setState(() {});
                                await loadNewsAdmin();
                                loading = false;
                                setState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selectedSection == 'news'? brandLightRed: brandRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Notícias', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.embedded) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/login_bg.png'), fit: BoxFit.cover)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.black.withValues(alpha: 0.7), Colors.black.withValues(alpha: 0.3)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            ),
          ),
        ),
        content,
      ]),
    );
  }

  Widget cardRoomAdminWidget({required Map<String, dynamic> room, }){
    return Column(
      children: [
        Row(
          children: [
            (room['imageUrl']?.toString() ?? '').isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(room['imageUrl'], width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.meeting_room))),
                )
              : Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.meeting_room)),
            SizedBox(width: 10,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
                Text(room['description'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),),
              ],
            ),
            Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                GestureDetector(
                  onTap: () => editRoom(room),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Editar', style: TextStyle(color: Colors.white),),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => deleteRoom(room['id']),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Excluir', style: TextStyle(color: Colors.white),),
                  ),
                ),
              ]
            ),
          ],
        ),        
        Divider(),
      ],
    );
  }

  Widget cardNewsAdminWidget({required Map<String, dynamic> newRegitered}){
    return Column(
      children: [
        Row(
          children: [
            // (room['imageUrl']?.toString() ?? '').isNotEmpty
            //   ? ClipRRect(
            //       borderRadius: BorderRadius.circular(8),
            //       child: Image.network(room['imageUrl'], width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: Colors.grey.shade200, child: const Icon(Icons.meeting_room))),
            //     )
            //   : Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.meeting_room)),
            // SizedBox(width: 10,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(newRegitered['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
                Text(newRegitered['content'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),),
              ],
            ),
            Spacer(),
            Row(
              mainAxisSize: MainAxisSize.min, 
              children: [
                GestureDetector(
                  onTap: () => editNews(newRegitered),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Editar', style: TextStyle(color: Colors.white),),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => deleteNews(newRegitered['id']),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Excluir', style: TextStyle(color: Colors.white),),
                  ),
                ),
              ]
            ),
          ],
        ),        
        Divider(),
      ],
    );
  }

  Widget cardAdAdminWidget({required Map<String, dynamic> ad, required AppLocalizations t, required String imgUrl}){
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketplaceDetailPage(token: widget.token, adId: ad['id'])));
      },
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imgUrl.isNotEmpty
                    ? Image.network(imgUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.image)))
                    : Container(width: 56, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.sell)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ad['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
                  Text('${ad['type']} • ${ad['status']} • ${ad['createdAt']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),),
                ],
              ),
              Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  GestureDetector(
                    onTap: () => approve(ad['id']),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t.approve, style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => complete(ad['id']),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t.complete, style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => suspendAuthor(ad['authorId']),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(t.suspendAuthor, style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      String currentType = ad['type'];
                      String currentStatus = ad['status'];
                      final titleCtrl = TextEditingController(text: ad['title']);
                      final descCtrl = TextEditingController(text: ad['description']);
                      final priceCtrl = TextEditingController(text: (ad['price'] ?? '').toString());
                      final ok = await showDialog<bool>(context: context, builder: (_) {
                        return AlertDialog(
                          title: const Text('Editar anúncio'),
                          content: Column(mainAxisSize: MainAxisSize.min, children: [
                            DropdownButton<String>(value: currentType, items: const [
                              DropdownMenuItem(value: 'venda', child: Text('Venda')),
                              DropdownMenuItem(value: 'compra', child: Text('Compra')),
                              DropdownMenuItem(value: 'troca', child: Text('Troca')),
                            ], onChanged: (v) => currentType = v ?? 'venda'),
                            DropdownButton<String>(value: currentStatus, items: const [
                              DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
                              DropdownMenuItem(value: 'aprovado', child: Text('Aprovado')),
                              DropdownMenuItem(value: 'concluido', child: Text('Concluído')),
                            ], onChanged: (v) => currentStatus = v ?? 'pendente'),
                            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
                            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
                            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Preço'), keyboardType: TextInputType.number),
                          ]),
                          actions: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(false),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(true),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Salvar', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                          ],
                        );
                      }) ?? false;
                      if (!ok) return;
                      await Api.setTokens(widget.token, null);
                      final body = {
                        'type': currentType,
                        'status': currentStatus,
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        'price': double.tryParse(priceCtrl.text),
                      };
                      final res = await Api.patch('/marketplace/ads/${ad['id']}', body);
                      feedback = res.statusCode == 200 ? 'Anúncio atualizado' : 'Falha ao atualizar';
                      setState(() {});
                      await load();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Editar', style: TextStyle(color: Colors.white),),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final ok = await showDialog<bool>(context: context, builder: (_) {
                        return AlertDialog(
                          title: const Text('Excluir anúncio?'),
                          actions: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(false),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(true),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Confirmar', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                          ],
                        );
                      }) ?? false;
                      if (!ok) return;
                      await Api.setTokens(widget.token, null);
                      final res = await Api.delete('/marketplace/ads/${ad['id']}');
                      feedback = (res.statusCode == 200 || res.statusCode == 204) ? 'Anúncio excluído' : 'Falha ao excluir';
                      setState(() {});
                      await load();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Excluir', style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ]),
            ],
          ),
          Divider(),
        ],
      ),
    );

    // return ListTile(
    //   leading: ClipRRect(
    //     borderRadius: BorderRadius.circular(8),
    //     child: imgUrl.isNotEmpty
    //         ? Image.network(imgUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.image)))
    //         : Container(width: 56, height: 56, color: Colors.grey.shade200, child: const Icon(Icons.sell)),
    //   ),
    //   title: Text(ad['title']),
    //   subtitle: Text('${ad['type']} • ${ad['status']} • ${ad['createdAt']}'),
    //   trailing: Row(
    //     mainAxisSize: MainAxisSize.min, 
    //     children: [
    //       GestureDetector(
    //         onTap: () => approve(ad['id']),
    //         child: Container(
    //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //           decoration: BoxDecoration(
    //             color: Colors.grey,
    //             borderRadius: BorderRadius.circular(8),
    //           ),
    //           child: Text(t.approve, style: TextStyle(color: Colors.white),),
    //         ),
    //       ),
    //       const SizedBox(width: 8),
    //       GestureDetector(
    //         onTap: () => complete(ad['id']),
    //         child: Container(
    //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //           decoration: BoxDecoration(
    //             color: Colors.grey,
    //             borderRadius: BorderRadius.circular(8),
    //           ),
    //           child: Text(t.complete, style: TextStyle(color: Colors.white),),
    //         ),
    //       ),
    //       const SizedBox(width: 8),
    //       GestureDetector(
    //         onTap: () => suspendAuthor(ad['authorId']),
    //         child: Container(
    //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //           decoration: BoxDecoration(
    //             color: Colors.grey,
    //             borderRadius: BorderRadius.circular(8),
    //           ),
    //           child: Text(t.suspendAuthor, style: TextStyle(color: Colors.white),),
    //         ),
    //       ),
    //       const SizedBox(width: 8),
    //       GestureDetector(
    //         onTap: () async {
    //           String currentType = ad['type'];
    //           String currentStatus = ad['status'];
    //           final titleCtrl = TextEditingController(text: ad['title']);
    //           final descCtrl = TextEditingController(text: ad['description']);
    //           final priceCtrl = TextEditingController(text: (ad['price'] ?? '').toString());
    //           final ok = await showDialog<bool>(context: context, builder: (_) {
    //             return AlertDialog(
    //               title: const Text('Editar anúncio'),
    //               content: Column(mainAxisSize: MainAxisSize.min, children: [
    //                 DropdownButton<String>(value: currentType, items: const [
    //                   DropdownMenuItem(value: 'venda', child: Text('Venda')),
    //                   DropdownMenuItem(value: 'compra', child: Text('Compra')),
    //                   DropdownMenuItem(value: 'troca', child: Text('Troca')),
    //                 ], onChanged: (v) => currentType = v ?? 'venda'),
    //                 DropdownButton<String>(value: currentStatus, items: const [
    //                   DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
    //                   DropdownMenuItem(value: 'aprovado', child: Text('Aprovado')),
    //                   DropdownMenuItem(value: 'concluido', child: Text('Concluído')),
    //                 ], onChanged: (v) => currentStatus = v ?? 'pendente'),
    //                 TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Título')),
    //                 TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descrição')),
    //                 TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Preço'), keyboardType: TextInputType.number),
    //               ]),
    //               actions: [
    //                 GestureDetector(
    //                   onTap: () => Navigator.of(context).pop(false),
    //                   child: Container(
    //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //                     decoration: BoxDecoration(
    //                       color: Colors.grey,
    //                       borderRadius: BorderRadius.circular(8),
    //                     ),
    //                     child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
    //                   ),
    //                 ),
    //                 GestureDetector(
    //                   onTap: () => Navigator.of(context).pop(true),
    //                   child: Container(
    //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //                     decoration: BoxDecoration(
    //                       color: Colors.grey,
    //                       borderRadius: BorderRadius.circular(8),
    //                     ),
    //                     child: const Text('Salvar', style: TextStyle(color: Colors.white),),
    //                   ),
    //                 ),
    //               ],
    //             );
    //           }) ?? false;
    //           if (!ok) return;
    //           await Api.setTokens(widget.token, null);
    //           final body = {
    //             'type': currentType,
    //             'status': currentStatus,
    //             'title': titleCtrl.text.trim(),
    //             'description': descCtrl.text.trim(),
    //             'price': double.tryParse(priceCtrl.text),
    //           };
    //           final res = await Api.patch('/marketplace/ads/${ad['id']}', body);
    //           feedback = res.statusCode == 200 ? 'Anúncio atualizado' : 'Falha ao atualizar';
    //           setState(() {});
    //           await load();
    //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
    //         },
    //         child: Container(
    //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //           decoration: BoxDecoration(
    //             color: Colors.grey,
    //             borderRadius: BorderRadius.circular(8),
    //           ),
    //           child: const Text('Editar', style: TextStyle(color: Colors.white),),
    //         ),
    //       ),
    //       const SizedBox(width: 8),
    //       GestureDetector(
    //         onTap: () async {
    //           final ok = await showDialog<bool>(context: context, builder: (_) {
    //             return AlertDialog(
    //               title: const Text('Excluir anúncio?'),
    //               actions: [
    //                 GestureDetector(
    //                   onTap: () => Navigator.of(context).pop(false),
    //                   child: Container(
    //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //                     decoration: BoxDecoration(
    //                       color: Colors.grey,
    //                       borderRadius: BorderRadius.circular(8),
    //                     ),
    //                     child: const Text('Cancelar', style: TextStyle(color: Colors.white),),
    //                   ),
    //                 ),
    //                 GestureDetector(
    //                   onTap: () => Navigator.of(context).pop(true),
    //                   child: Container(
    //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //                     decoration: BoxDecoration(
    //                       color: Colors.grey,
    //                       borderRadius: BorderRadius.circular(8),
    //                     ),
    //                     child: const Text('Confirmar', style: TextStyle(color: Colors.white),),
    //                   ),
    //                 ),
    //               ],
    //             );
    //           }) ?? false;
    //           if (!ok) return;
    //           await Api.setTokens(widget.token, null);
    //           final res = await Api.delete('/marketplace/ads/${ad['id']}');
    //           feedback = (res.statusCode == 200 || res.statusCode == 204) ? 'Anúncio excluído' : 'Falha ao excluir';
    //           setState(() {});
    //           await load();
    //           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(feedback)));
    //         },
    //         child: Container(
    //           padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //           decoration: BoxDecoration(
    //             color: Colors.grey,
    //             borderRadius: BorderRadius.circular(8),
    //           ),
    //           child: const Text('Excluir', style: TextStyle(color: Colors.white),),
    //         ),
    //       ),
    //     ]),
    //     onTap: () {
    //       Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketplaceDetailPage(token: widget.token, adId: ad['id'])));
    //     },
    //   );
  }

}
