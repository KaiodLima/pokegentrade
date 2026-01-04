import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/api.dart';
import '../widgets/status_banner.dart';
import '../services/me_cache.dart';
import '../app/locator.dart';
import '../features/users/domain/usecases/get_me.dart';
import '../features/users/domain/usecases/update_display_name.dart';
import '../features/users/domain/usecases/update_avatar.dart';

class ProfilePage extends StatefulWidget {
  final bool embedded;
  const ProfilePage({super.key, this.embedded = false});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameCtrl = TextEditingController();
  String? info;
  String? error;
  bool loading = false;
  String avatarUrl = '';
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  Future<void> load() async {
    final r = await GetMeUseCase(Locator.users)();
    if (r.isOk && r.data != null) {
      final j = r.data!;
      nameCtrl.text = (j['displayName'] ?? j['name'] ?? '').toString();
      avatarUrl = (j['avatarUrl'] ?? '').toString();
      setState(() {});
    }
  }
  Future<void> save() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty || name.length < 2) {
      setState(() => error = 'Informe um nome válido');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      info = null;
    });
    final r = await UpdateDisplayNameUseCase(Locator.users)(name);
    if (r.isOk) {
      info = 'Nome atualizado';
      await Api.refresh();
      MeCache.setName(name);
    } else {
      error = 'Falha ao salvar';
    }
    loading = false;
    setState(() {});
  }
  Future<void> uploadAvatar() async {
    final pick = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: false, type: FileType.custom, allowedExtensions: ['png','jpg','jpeg','gif','webp']);
    if (pick == null || pick.files.isEmpty) return;
    final f = pick.files.first;
    if (f.bytes == null) return;
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
        final r = await UpdateAvatarUseCase(Locator.users)(objectUrl);
        if (r.isOk) {
          setState(() {
            avatarUrl = objectUrl;
            info = 'Foto atualizada';
            error = null;
          });
        } else {
          setState(() => error = 'Falha ao atualizar foto');
        }
      }
    }
  }
  @override
  void initState() {
    super.initState();
    load();
  }
  @override
  Widget build(BuildContext context) {
    final inner = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white.withValues(alpha: 0.95),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  child: Row(
                    children: const [
                      Icon(Icons.person, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: avatarUrl.isNotEmpty
                          ? Image.network(avatarUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.person)))
                          : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.person)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: uploadAvatar, child: const Text('Alterar foto')),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nome exibido', prefixIcon: Icon(Icons.badge, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white), onPressed: loading ? null : save, child: Text(loading ? 'Salvando...' : 'Salvar'))),
                const SizedBox(height: 8),
                if (error != null) StatusBanner(text: error!, type: 'error'),
                if (info != null) StatusBanner(text: info!, type: 'success'),
              ],
            ),
          ),
        ),
      ),
    );
    if (widget.embedded) {
      return inner;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/login_bg.png'), fit: BoxFit.cover)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [brandBlack.withValues(alpha: 0.7), brandBlack.withValues(alpha: 0.3)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            ),
          ),
        ),
        inner,
      ]),
    );
  }
}
