import 'package:flutter/material.dart';
import 'dart:convert';
import 'marketplace_new.dart';
import 'marketplace_detail.dart';
import '../services/sanitize.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../app/locator.dart';
import '../features/marketplace/domain/usecases/get_ads.dart';
import '../widgets/guest_app_bar.dart';
import '../services/api.dart';
import '../widgets/app_modal.dart';
import 'login.dart';
import 'register.dart';

class MarketplaceListPage extends StatefulWidget {
  final String token;
  final bool embedded;
  const MarketplaceListPage({super.key, required this.token, this.embedded = false});
  @override
  State<MarketplaceListPage> createState() => _MarketplaceListPageState();
}

class _MarketplaceListPageState extends State<MarketplaceListPage> {
  List<Map<String, dynamic>> ads = [];
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  List<String> _priceParts(String price) {
    final clean = price.replaceAll(RegExp(r'[^0-9.]'), '');
    final d = double.tryParse(clean) ?? 0.0;
    final cents = (d * 100).round();
    final intPart = (cents ~/ 100).toString();
    final fracPart = (cents % 100).toString().padLeft(2, '0');
    return [intPart, fracPart];
  }
  Future<void> load() async {
    final r = await GetAdsUseCase(Locator.marketplace)();
    if (r.isOk) {
      final list = r.data ?? [];
      ads = list.map<Map<String, dynamic>>((a) => {
        'id': a.id,
        'title': a.title,
        'type': a.type,
        'price': a.price,
        'status': a.status,
        'createdAt': a.createdAt,
        'attachments': a.attachments.map((x) => x.toMap()).toList(),
      }).where((m) => (m['status']?.toString() ?? '') == 'aprovado').toList();
      setState(() {});
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('marketplace_ads_cache', jsonEncode(ads));
      } catch (_) {}
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cache = prefs.getString('marketplace_ads_cache');
        if (cache != null && cache.isNotEmpty) {
          final list = jsonDecode(cache);
          if (list is List) {
            ads = list.map<Map<String, dynamic>>((e) => {
              'id': e is Map ? (e['id'] ?? '') : '',
              'title': e is Map ? (e['title'] ?? '') : '',
              'type': e is Map ? (e['type'] ?? '') : '',
              'price': e is Map ? (e['price']?.toString() ?? '') : '',
              'status': e is Map ? (e['status'] ?? '') : '',
              'createdAt': e is Map ? (e['createdAt'] ?? '') : '',
              'attachments': e is Map ? (e['attachments'] ?? []) : [],
            }).toList();
            setState(() {});
          }
        }
      } catch (_) {}
    }
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
        constraints: const BoxConstraints(maxWidth: 980),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white.withValues(alpha: 0.95),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                margin: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.sell, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('Marketplace', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      onPressed: () async {
                        if ((widget.token).isEmpty) {
                          final t2 = AppLocalizations.of(context);
                          await showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
                            return AppModal(
                              title: t2.newAd,
                              actions: [
                                TextButton(onPressed: () => Navigator.of(_).pop(false), child: Text(t2.cancel)),
                              ],
                              content: Row(children: [
                                Expanded(child: ElevatedButton(onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginPage(onLoggedIn: (a, r) async {
                                    await Api.setTokens(a, r);
                                  })));
                                }, child: Text(t2.enter))),
                                const SizedBox(width: 8),
                                Expanded(child: ElevatedButton(onPressed: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterPage(onRegistered: (a, r) async {
                                    await Api.setTokens(a, r);
                                  })));
                                }, child: Text(t2.createAccount))),
                              ]),
                            );
                          });
                        } else {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketplaceNewPage(token: widget.token)));
                          await load();
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = constraints.maxWidth;
                    final cross = (maxW / 280).floor().clamp(2, 6);
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cross, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72),
                        itemCount: ads.length,
                        itemBuilder: (_, i) {
                          final a = ads[i];
                          final atts = (a['attachments'] as List? ?? []);
                          final firstImg = atts.cast<Map>().firstWhere((x) => (x['type']?.toString() ?? '').startsWith('image/'), orElse: () => {});
                          final imgUrl = Sanitize.sanitizeImageUrl((firstImg['url']?.toString() ?? ''));
                          final parts = _priceParts((a['price'] ?? '').toString());
                          return InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketplaceDetailPage(token: widget.token, adId: a['id'])));
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                                    child: imgUrl.isNotEmpty
                                        ? Image.network(imgUrl, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey.shade200, child: const Icon(Icons.image)))
                                        : Container(height: 160, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))), child: const Icon(Icons.sell)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('R\$ ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18)),
                                            Text(parts[0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 22)),
                                            Text(parts[1], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.embedded) {
      return content;
    }
    return Scaffold(
      appBar: (widget.token.isEmpty) ? GuestAppBar(selectedSection: "marketplace",) : AppBar(title: Text(t.marketplace)),
      body: Stack(fit: StackFit.expand, children: [
        Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/login_bg.png'), fit: BoxFit.cover)),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [brandBlack.withValues(alpha: 0.7), brandBlack.withValues(alpha: 0.3)], begin: Alignment.bottomCenter, end: Alignment.topCenter),
            ),
          ),
        ),
        content,
      ]),
    );
  }
}
