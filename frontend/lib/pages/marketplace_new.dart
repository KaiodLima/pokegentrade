import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import '../services/api.dart';
import '../widgets/status_banner.dart';
import '../l10n/app_localizations.dart';
import '../app/locator.dart';
import '../features/marketplace/domain/usecases/create_ad.dart';
import '../features/marketplace/domain/usecases/add_attachment.dart';

class MarketplaceNewPage extends StatefulWidget {
  final String token;
  const MarketplaceNewPage({super.key, required this.token});
  @override
  State<MarketplaceNewPage> createState() => _MarketplaceNewPageState();
}

class _MarketplaceNewPageState extends State<MarketplaceNewPage> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  String type = 'venda';
  String? categoryId;
  String? serverId;
  List<Map<String, String>> categories = [];
  List<Map<String, String>> servers = [];
  String feedback = '';
  String? actionText;
  List<PlatformFile> files = [];
  List<String> fileStatuses = [];
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  String _contentTypeFor(PlatformFile f) {
    final ext = (f.extension ?? '').toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> pickFiles() async {
    final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: true);
    if (res != null) {
      final maxBytes = 5 * 1024 * 1024;
      final selected = res.files;
      final allowedExt = {'png', 'jpg', 'jpeg', 'gif', 'webp', 'pdf', 'txt'};
      final allowed = selected.where((f) => f.size <= maxBytes && allowedExt.contains((f.extension ?? '').toLowerCase())).toList();
      files = allowed;
      if (allowed.length != selected.length) {
        feedback = 'Alguns arquivos foram ignorados (tipo inválido ou >5MB)';
      }
      fileStatuses = List.generate(files.length, (_) => 'Pendente');
      setState(() {});
    }
  }

  Future<void> uploadAndCreate() async {
    final payloadType = type;
    final payloadTitle = titleCtrl.text;
    final payloadDesc = descCtrl.text;
    final payloadPrice = double.tryParse(priceCtrl.text);
    if (payloadTitle.trim().isEmpty || payloadDesc.trim().isEmpty) {
      feedback = 'Informe título e descrição';
      actionText = null;
      setState(() {});
      return;
    }
    final createRes = await CreateAdUseCase(Locator.marketplace)(type: payloadType, title: payloadTitle, description: payloadDesc, price: payloadPrice, categoryId: categoryId, serverId: serverId);
    if (createRes.isOk && createRes.data != null) {
      final ad = createRes.data!;
      int index = 0;
      for (final f in files) {
        index++;
        feedback = 'Enviando arquivo $index/${files.length}...';
        actionText = null;
        setState(() {});
        final ctype = _contentTypeFor(f);
        Future<Uint8List?> _fileBytes(PlatformFile pf) async {
          if (pf.bytes != null) return pf.bytes!;
          if (pf.readStream != null) {
            final chunks = <int>[];
            final completer = Completer<Uint8List>();
            pf.readStream!.listen((data) {
              chunks.addAll(data);
            }, onDone: () => completer.complete(Uint8List.fromList(chunks)), onError: (_) => completer.complete(null), cancelOnError: true);
            return completer.future;
          }
          return null;
        }
        final pres = await Api.post('/uploads', {'filename': f.name, 'contentType': ctype});
        if (pres.statusCode == 429) {
          feedback = 'Muitas requisições, tente novamente em instantes';
          actionText = 'Tentar novamente';
          setState(() {});
          break;
        }
        if (pres.statusCode == 201 || pres.statusCode == 200) {
          final p = jsonDecode(pres.body);
          if (p is Map && (p['status'] ?? '') == 'blocked') {
            final ms = (p['remainingMs'] ?? 0).toString();
            feedback = 'Aguarde $ms ms para novo upload';
            actionText = 'Tentar novamente';
            setState(() {});
            break;
          }
          final bytes = await _fileBytes(f);
          if (bytes != null) {
            String objectUrl = '';
            if ((p['method'] ?? '') == 'POST') {
              final uri = Uri.parse(p['postUrl']);
              final req = http.MultipartRequest('POST', uri);
              final fields = (p['fields'] as Map?) ?? {};
              fields.forEach((k, v) => req.fields[k] = v.toString());
              req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: f.name));
              final resp = await req.send();
              if (resp.statusCode != 204 && resp.statusCode != 201) {
                feedback = 'Falha no upload (POST)';
                actionText = 'Tentar novamente';
                setState(() {});
                fileStatuses[index - 1] = 'Falha';
                break;
              }
              objectUrl = (p['objectUrl'] ?? '').toString();
            } else if ((p['method'] ?? '') == 'PUT') {
              await http.put(Uri.parse(p['uploadUrl']), headers: {'Content-Type': ctype}, body: bytes);
              objectUrl = p['uploadUrl'].toString().split('?').first;
            } else if ((p['method'] ?? '') == 'PROXY') {
              final resp = await Api.post('/uploads/direct', {'filename': f.name, 'contentType': ctype, 'base64': base64Encode(bytes)});
              if (!(resp.statusCode == 200 || resp.statusCode == 201)) {
                feedback = 'Falha no upload (proxy)';
                actionText = 'Tentar novamente';
                setState(() {});
                fileStatuses[index - 1] = 'Falha';
                break;
              }
              final j = jsonDecode(resp.body);
              objectUrl = (j['objectUrl'] ?? '').toString();
            }
            final attRes = await AddAttachmentUseCase(Locator.marketplace)(ad.id, url: objectUrl, type: ctype, meta: {'size': f.size});
            if (attRes.isOk) {
              fileStatuses[index - 1] = 'Enviado';
              setState(() {});
            } else {
              try {
                final aj = jsonDecode(attRes.error ?? '{}');
                if (aj is Map && (aj['status'] ?? '') == 'blocked' && aj['reason'] == 'file_too_large') {
                  feedback = 'Arquivo muito grande (>${(aj['maxBytes'] ?? 0)} bytes)';
                  actionText = null;
                  setState(() {});
                  fileStatuses[index - 1] = 'Muito grande';
                  break;
                }
                if (aj is Map && (aj['status'] ?? '') == 'blocked' && aj['reason'] == 'object_missing') {
                  feedback = 'Arquivo não encontrado no storage; tente novamente';
                  actionText = 'Tentar novamente';
                  setState(() {});
                  fileStatuses[index - 1] = 'Objeto ausente';
                  break;
                }
                if (aj is Map && (aj['status'] ?? '') == 'blocked' && aj['reason'] == 'invalid_content_type') {
                  feedback = 'Tipo de arquivo não permitido';
                  actionText = null;
                  setState(() {});
                  fileStatuses[index - 1] = 'Tipo inválido';
                  break;
                }
                if (aj is Map && (aj['status'] ?? '') == 'blocked' && aj['reason'] == 'content_type_mismatch') {
                  feedback = 'Tipo de arquivo enviado não confere com o informado';
                  actionText = null;
                  setState(() {});
                  fileStatuses[index - 1] = 'Tipo não confere';
                  break;
                }
              } catch (_) {
                feedback = 'Falha ao registrar anexo';
                actionText = 'Tentar novamente';
                setState(() {});
                fileStatuses[index - 1] = 'Falha ao anexar';
                break;
              }
            }
          }
        }
      }
      final msg = (ad.status.toLowerCase() == 'pendente')
          ? 'anúncio criado e aguardando aprovação do admin'
          : 'Anúncio criado com sucesso';
      feedback = msg;
      actionText = null;
      setState(() {});
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Marketplace'),
          content: Text(msg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(_).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }
    try {
      final aj = jsonDecode(createRes.error ?? '{}');
      if (aj is Map && (aj['status'] ?? '') == 'blocked') {
        final ms = (aj['remainingMs'] ?? 0).toString();
        feedback = 'Muitas requisições, aguarde $ms ms';
        actionText = 'Tentar novamente';
        setState(() {});
        return;
      }
    } catch (_) {}
    feedback = 'Erro ao criar (verifique os campos e tente novamente)';
    actionText = 'Tentar novamente';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    void loadMeta() async {
      try {
        final rc = await Api.get('/marketplace/categories');
        if (rc.statusCode == 200) {
          final list = jsonDecode(rc.body);
          if (list is List) {
            categories = list.map<Map<String, String>>((e) => {'id': (e['id'] ?? '').toString(), 'name': (e['name'] ?? '').toString()}).toList();
            setState(() {});
          }
        }
        final rs = await Api.get('/marketplace/servers');
        if (rs.statusCode == 200) {
          final list = jsonDecode(rs.body);
          if (list is List) {
            servers = list.map<Map<String, String>>((e) => {'id': (e['id'] ?? '').toString(), 'name': (e['name'] ?? '').toString()}).toList();
            setState(() {});
          }
        }
      } catch (_) {}
    }
    if (categories.isEmpty && servers.isEmpty) {
      loadMeta();
    }
    return Scaffold(
      appBar: AppBar(title: Text(t.newAd)),
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
              constraints: const BoxConstraints(maxWidth: 700),
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
                          children: [
                            const Icon(Icons.add_business, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(t.newAd, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        items: [
                          DropdownMenuItem(value: 'venda', child: Text(t.sale)),
                          DropdownMenuItem(value: 'compra', child: Text(t.buy)),
                          DropdownMenuItem(value: 'troca', child: Text(t.trade)),
                        ],
                        decoration: InputDecoration(prefixIcon: Icon(Icons.category, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                        onChanged: (v) => setState(() => type = v ?? 'venda'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: categoryId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Selecione um tipo')),
                          ...categories.map((c) => DropdownMenuItem(value: c['id'], child: Text(c['name'] ?? ''))),
                        ],
                        decoration: InputDecoration(prefixIcon: Icon(Icons.label, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), labelText: 'Tipo do item'),
                        onChanged: (v) => setState(() => categoryId = v),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: serverId,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Selecione um servidor')),
                          ...servers.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name'] ?? ''))),
                        ],
                        decoration: InputDecoration(prefixIcon: Icon(Icons.storage, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), labelText: 'Servidor'),
                        onChanged: (v) => setState(() => serverId = v),
                      ),
                      const SizedBox(height: 8),
                      TextField(controller: titleCtrl, decoration: InputDecoration(labelText: t.title, prefixIcon: Icon(Icons.title, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 8),
                      TextField(controller: descCtrl, decoration: InputDecoration(labelText: t.description, prefixIcon: Icon(Icons.description, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 8),
                      TextField(controller: priceCtrl, decoration: InputDecoration(labelText: t.price, prefixIcon: Icon(Icons.attach_money, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white), onPressed: pickFiles, child: Text(t.selectFiles)),
                          const SizedBox(width: 8),
                          Text('${files.length} ${t.selectedLabel}'),
                        ],
                      ),
                      if (files.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: files.where((f) {
                                final ext = (f.extension ?? '').toLowerCase();
                                return {'png','jpg','jpeg','gif','webp'}.contains(ext) && f.bytes != null;
                              }).map((f) => ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(f.bytes!, width: 60, height: 60, fit: BoxFit.cover),
                              )).toList(),
                            ),
                          ),
                        ),
                      const Spacer(),
                      SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white), onPressed: uploadAndCreate, child: const Text('Criar'))),
                      const SizedBox(height: 8),
                      if (fileStatuses.isNotEmpty)
                        Expanded(
                          child: ListView.builder(
                            itemCount: fileStatuses.length,
                            itemBuilder: (_, i) => ListTile(
                              title: Text(files[i].name),
                              subtitle: Text(fileStatuses[i]),
                            ),
                          ),
                        ),
                      if (feedback.isNotEmpty) StatusBanner(
                        text: feedback,
                        type: feedback.startsWith('Criado') ? 'success' : (feedback.startsWith('Falha') || feedback.startsWith('Erro') ? 'error' : 'info'),
                        actionText: actionText,
                        onAction: actionText != null ? uploadAndCreate : null,
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
