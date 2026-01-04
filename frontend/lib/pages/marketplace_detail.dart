import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/status_banner.dart';
import '../services/sanitize.dart';
import '../l10n/app_localizations.dart';
import '../widgets/marketplace_edit_dialog.dart';
import '../app/locator.dart';
import '../features/marketplace/domain/usecases/get_ad.dart';
import '../features/marketplace/domain/usecases/approve_ad.dart';
import '../features/marketplace/domain/usecases/complete_ad.dart';
import '../features/marketplace/domain/usecases/delete_ad.dart';
import '../features/marketplace/domain/usecases/suspend_author.dart';
// import '../services/payments.dart';

class MarketplaceDetailPage extends StatefulWidget {
  final String token;
  final String adId;
  const MarketplaceDetailPage({super.key, required this.token, required this.adId});
  @override
  State<MarketplaceDetailPage> createState() => _MarketplaceDetailPageState();
}

class _MarketplaceDetailPageState extends State<MarketplaceDetailPage> {
  Map<String, dynamic>? ad;
  bool loading = true;
  String feedback = '';
  bool isAdmin = false;
  String? myUserId;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  void _decodeRole() {
    try {
      final parts = widget.token.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        final role = payload['role']?.toString();
        final roles = (payload['roles'] is List) ? (payload['roles'] as List).map((e) => e.toString()).toList() : <String>[];
        isAdmin = role == 'Admin' || roles.contains('Admin');
        myUserId = payload['sub']?.toString();
      }
    } catch (_) {}
  }
  Future<void> load() async {
    final r = await GetAdUseCase(Locator.marketplace)(widget.adId);
    if (r.isOk && r.data != null) {
      final a = r.data!;
      ad = {
        'id': a.id,
        'title': a.title,
        'type': a.type,
        'price': a.price,
        'status': a.status,
        'description': a.description,
        'attachments': a.attachments.map((x) => {'url': x.url, 'type': x.type, 'meta': x.meta}).toList(),
        'authorId': a.authorId,
      };
    }
    loading = false;
    setState(() {});
  }
  Future<void> approve() async {
    final r = await ApproveAdUseCase(Locator.marketplace)(widget.adId);
    feedback = r.isOk ? 'Aprovado' : 'Falha ao aprovar';
    setState(() {});
    await load();
  }
  Future<void> complete() async {
    final r = await CompleteAdUseCase(Locator.marketplace)(widget.adId);
    feedback = r.isOk ? 'Concluído' : 'Falha ao concluir';
    setState(() {});
    await load();
  }
  // Pagamentos desabilitados por requisito atual
  Future<void> suspendAuthor() async {
    final authorId = ad?['authorId']?.toString() ?? '';
    if (authorId.isEmpty) return;
    final r = await SuspendAuthorUseCase(Locator.marketplace)(authorId, motivo: 'violação');
    feedback = r.isOk ? 'Autor suspenso' : 'Falha ao suspender';
    setState(() {});
  }
  Future<void> deleteAd() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (_) {
      return AlertDialog(
        title: Text(t.confirmDelete),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(t.cancel)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(t.confirm)),
        ],
      );
    }) ?? false;
    if (!ok) return;
    final r = await DeleteAdUseCase(Locator.marketplace)(widget.adId);
    if (r.isOk) {
      feedback = t.deleted;
      setState(() {});
      Navigator.of(context).pop();
    } else {
      feedback = t.failDelete;
      setState(() {});
    }
  }
  Future<void> editAd() async {
    final ok = await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
      return MarketplaceEditDialog(token: widget.token, adId: widget.adId);
    }) ?? false;
    if (ok) {
      await load();
    }
  }
  @override
  void initState() {
    super.initState();
    _decodeRole();
    load();
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.adDetail)),
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
                  padding: const EdgeInsets.all(16),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : ad == null
                          ? Center(child: Text(t.adNotFound))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.assignment, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(ad!['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('${ad!['type']} • ${ad!['status']} • ${ad!['price'] ?? ''}'),
                                const SizedBox(height: 8),
                                Text(ad!['description'] ?? ''),
                                const SizedBox(height: 12),
                                Text(t.attachments),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: (ad!['attachments'] as List? ?? []).length,
                                    itemBuilder: (_, i) {
                                      final at = (ad!['attachments'] as List)[i] as Map;
                                      final url = Sanitize.sanitizeImageUrl((at['url']?.toString() ?? ''));
                                      final type = (at['type']?.toString() ?? '');
                                      final isImage = type.startsWith('image/');
                                      return ListTile(
                                        title: Text(url),
                                        subtitle: Text(type),
                                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                                          ElevatedButton(onPressed: () => Clipboard.setData(ClipboardData(text: url)), child: Text(t.copyLink)),
                                        ]),
                                        leading: isImage ? Image.network(url, width: 48, height: 48, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)) : const Icon(Icons.attach_file),
                                        onTap: isImage ? () {
                                          showDialog(context: context, builder: (_) {
                                            return Dialog(child: InteractiveViewer(child: Image.network(url, errorBuilder: (_, __, ___) => const SizedBox(width: 300, height: 300))));
                                          });
                                        } : null,
                                      );
                                    },
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (isAdmin) ElevatedButton(onPressed: approve, child: Text(t.approve)),
                                    const SizedBox(width: 8),
                                    ElevatedButton(onPressed: complete, child: Text(t.complete)),
                                    const SizedBox(width: 8),
                                    if (isAdmin) ElevatedButton(onPressed: suspendAuthor, child: Text(t.suspendAuthor)),
                                    const SizedBox(width: 8),
                                    if (isAdmin || (ad?['authorId']?.toString() == myUserId)) ElevatedButton(onPressed: editAd, child: Text(t.edit)),
                                    const SizedBox(width: 8),
                                    if (isAdmin || (ad?['authorId']?.toString() == myUserId)) ElevatedButton(onPressed: deleteAd, child: Text(t.delete)),
                                    const SizedBox(width: 8),
                          // Pagamentos desabilitados
                                    if (feedback.isNotEmpty) Expanded(child: StatusBanner(text: feedback, type: feedback.startsWith('Falha') ? 'error' : 'success')),
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
