import 'package:flutter/material.dart';
import 'package:poketibia_platform_frontend/widgets/guest_app_bar.dart';
import 'dart:convert';
import 'login.dart';
import 'register.dart';
import 'rooms.dart';
import 'inbox.dart';
import 'marketplace_list.dart';
import 'admin.dart';
import 'profile.dart';
import 'settings.dart';
import '../services/api.dart';
import '../l10n/app_localizations.dart';
import '../services/sanitize.dart';
import '../app/locator.dart';
import '../features/news/domain/usecases/get_news.dart';
import '../widgets/app_modal.dart';

class HomePage extends StatefulWidget {
  final String? token;
  final Future<void> Function()? onLogout;
  final Future<void> Function(String t, String? r)? onLoggedIn;
  const HomePage({super.key, this.token, this.onLogout, this.onLoggedIn});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  bool isAdmin = false;
  String? meName;
  String selectedSection = 'welcome';
  List<Map<String, dynamic>> rooms = [];
  Map<String, Map<String, String>> roomsSummary = {};
  List<Map<String, dynamic>> inboxItems = [];
  List<Map<String, dynamic>> ads = [];
  List<Map<String, dynamic>> popularRooms = [];
  List<Map<String, dynamic>> topUsers = [];
  List<Map<String, dynamic>> news = [];
  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return iso;
    }
  }
  @override
  void initState() {
    super.initState();
    _hydrate();
  }
  Future<void> _hydrate() async {
    await Api.init();
    try {
      final t = Api.currentAccessToken() ?? widget.token ?? '';
      final parts = t.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        final role = payload['role']?.toString();
        final roles = (payload['roles'] is List) ? (payload['roles'] as List).map((e) => e.toString()).toList() : <String>[];
        isAdmin = role == 'Admin' || role == 'SuperAdmin' || roles.contains('Admin') || roles.contains('SuperAdmin');
        meName = (payload['name'] ?? '').toString();
      }
    } catch (_) {}
    setState(() {});
    await loadPopularAndTop();
    await loadNews();
  }
  Future<void> loadNews() async {
    final uc = GetNewsUseCase(Locator.news);
    final r = await uc();
    if (r.isOk) {
      news = (r.data ?? []).map<Map<String, dynamic>>((e) => {
        'id': e.id,
        'title': e.title,
        'content': e.content,
        'createdAt': e.createdAt,
        'attachments': e.attachments,
      }).toList();
    }
    setState(() {});
  }
  Future<void> loadPopularAndTop() async {
    final pop = await Api.get('/rooms/popular');
    if (pop.statusCode == 200) {
      final list = jsonDecode(pop.body);
      if (list is List) {
        popularRooms = list.map<Map<String, dynamic>>((e) => {
          'id': (e['id'] ?? '').toString(),
          'name': (e['name'] ?? '').toString(),
          'count': int.tryParse((e['count'] ?? '0').toString()) ?? 0,
          'lastAt': (e['lastAt'] ?? '').toString(),
        }).toList();
      }
    }
    final top = await Api.get('/users/top');
    if (top.statusCode == 200) {
      final list = jsonDecode(top.body);
      if (list is List) {
        topUsers = list.map<Map<String, dynamic>>((e) => {
          'id': (e['id'] ?? '').toString(),
          'displayName': (e['displayName'] ?? '').toString(),
          'avatarUrl': (e['avatarUrl'] ?? '').toString(),
          'trustScore': int.tryParse((e['trustScore'] ?? '0').toString()) ?? 0,
        }).toList();
      }
    }
    setState(() {});
  }
  Future<void> loadRooms() async {
    final res = await Api.get('/rooms');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        rooms = list.map<Map<String, dynamic>>((e) => {
          'id': (e['id'] ?? '').toString(),
          'name': (e['name'] ?? '').toString(),
          'description': (e['description'] ?? '').toString(),
        }).toList();
      }
    }
    final sum = await Api.get('/rooms/summary');
    if (sum.statusCode == 200) {
      final list = jsonDecode(sum.body);
      if (list is List) {
        roomsSummary = {
          for (final e in list)
            (e['id'] ?? '').toString(): {
              'lastContent': (e['lastContent'] ?? '').toString(),
              'lastAt': (e['lastAt'] ?? '').toString(),
            }
        };
      }
    }
    setState(() {});
  }
  Future<void> loadInbox() async {
    final res = await Api.get('/dm/inbox');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        inboxItems = list.map<Map<String, dynamic>>((e) => {
          'fromId': e['fromId'] ?? '',
          'toId': e['toId'] ?? '',
          'content': e['content'] ?? '',
          'createdAt': e['createdAt'] ?? '',
        }).toList();
      }
    }
    setState(() {});
  }
  Future<void> loadAds() async {
    final res = await Api.get('/marketplace/ads');
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
          'attachments': e['attachments'] ?? [],
        }).toList();
      }
    }
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final hasToken = (Api.currentAccessToken() ?? widget.token)?.isNotEmpty == true;
    return Scaffold(
      appBar: (hasToken == false) ? GuestAppBar(selectedSection: "welcome",): AppBar(
        title: Text(meName != null && meName!.isNotEmpty ? 'Bem-vindo, $meName' : 'Bem-vindo'),
        actions: [
          TextButton(
            onPressed: () {
              selectedSection = 'welcome';
              setState(() {});
              loadPopularAndTop();
            },
            child: const Text('Início', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              selectedSection = 'rooms';
              setState(() {});
              loadRooms();
            },
            child: Text(t.publicRooms, style: const TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              selectedSection = 'inbox';
              setState(() {});
              loadInbox();
            },
            child: Text(t.inboxDMs, style: const TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              selectedSection = 'marketplace';
              setState(() {});
              loadAds();
            },
            child: Text(t.marketplace, style: const TextStyle(color: Colors.white)),
          ),
          if (isAdmin)
            TextButton(
              onPressed: () {
                selectedSection = 'admin';
                setState(() {});
              },
              child: Text(t.admin, style: const TextStyle(color: Colors.white)),
            ),
          TextButton(
            onPressed: () {
              selectedSection = 'profile';
              setState(() {});
            },
            child: Text(t.profile, style: const TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              selectedSection = 'settings';
              setState(() {});
            },
            child: Text(t.settings, style: const TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              await (widget.onLogout ?? () async {})();
            },
            child: Text(t.logout, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
              constraints: (selectedSection == 'admin') ? const BoxConstraints(maxWidth: 1300): const BoxConstraints(maxWidth: 1200),
              child: (selectedSection == 'welcome')
                ? bodyWelcomePage(hasToken: hasToken, enter: t.enter, createAccount: t.createAccount) 
                : bodyPage(hasToken: hasToken, enter: t.enter, createAccount: t.createAccount),
            ),
          ),
        ],
      ),
    );
  }

  Widget bodyWelcomePage({required bool hasToken, required String enter, required String createAccount}){
    return Row(
      children: [
        Expanded(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white.withValues(alpha: 0.95),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: hasToken
                  ? SingleChildScrollView(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.catching_pokemon, color: brandRed),
                              const SizedBox(width: 8),
                              Text(meName != null && meName!.isNotEmpty ? 'Bem-vindo, $meName' : 'Bem-vindo', style: TextStyle(color: brandBlack, fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ValueListenableBuilder<bool>(
                            valueListenable: _showMore,
                            builder: (context, showMore, _) {
                              return cardWelcomeHomeWidget(context);
                            }
                          ),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                                Row(
                                  children: const [
                                    Icon(Icons.newspaper),
                                    SizedBox(width: 8),
                                    Text('Notícias de Mercado', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (news.isEmpty)
                                  const Text('Sem notícias ainda')
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: news.length,
                                    itemBuilder: (_, i) {
                                      final n = news[i];
                                      final atts = (n['attachments'] as List?) ?? [];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ListTile(
                                            leading: ((n['attachments'] as List?)?.isNotEmpty == true)
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      Sanitize.sanitizeImageUrl(((n['attachments'] as List).first).toString()),
                                                      width: 48,
                                                      height: 48,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                                                    ),
                                                  )
                                                : null,
                                            title: Text(n['title']),
                                            subtitle: Text(n['content'], maxLines: 3, overflow: TextOverflow.ellipsis),
                                            trailing: Text(_fmt(n['createdAt']), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                          ),
                                          if (atts.isNotEmpty)
                                            SizedBox(
                                              height: 140,
                                              child: PageView.builder(
                                                itemCount: atts.length,
                                                controller: PageController(viewportFraction: 0.9),
                                                itemBuilder: (_, idx) {
                                                  final url = Sanitize.sanitizeImageUrl(atts[idx].toString());
                                                  return Padding(
                                                    padding: const EdgeInsets.only(right: 8),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                              ]),
                            ),
                          ),
                        ],
                      ),
                  )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.catching_pokemon, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Bem-vindo ao Sistema', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginPage(onLoggedIn: (widget.onLoggedIn ?? (a, b) async {}))));
                              },
                              child: Text(enter),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterPage(onRegistered: (widget.onLoggedIn ?? (a, b) async {}))));
                              },
                              child: Text(createAccount),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 280,
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
                      gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(children: const [Icon(Icons.whatshot, color: Colors.white), SizedBox(width: 8), Text('Chats populares', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: popularRooms.length,
                      itemBuilder: (_, i) {
                        final r = popularRooms[i];
                        return ListTile(
                          title: Text(r['name']),
                          subtitle: Text(r['lastAt']),
                          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)), child: Text('${r['count']}')),
                          onTap: () {
                            final hasToken = (Api.currentAccessToken() ?? widget.token)?.isNotEmpty == true;
                            if (!hasToken) {
                              final t2 = AppLocalizations.of(context);
                              showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
                                return AppModal(
                                  title: t2.publicRooms,
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
                              selectedSection = 'rooms';
                              setState(() {});
                              loadRooms();
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(children: const [Icon(Icons.verified, color: Colors.white), SizedBox(width: 8), Text('Ranking confiança', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: topUsers.length,
                      itemBuilder: (_, i) {
                        final u = topUsers[i];
                        final img = Sanitize.sanitizeImageUrl((u['avatarUrl'] ?? '').toString());
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: img.isNotEmpty ? Image.network(img, width: 32, height: 32, fit: BoxFit.cover) : Container(width: 32, height: 32, color: Colors.grey.shade200, child: const Icon(Icons.person)),
                          ),
                          title: Text(u['displayName']),
                          trailing: Text('${u['trustScore']}'),
                          onTap: () {
                            final hasToken = (Api.currentAccessToken() ?? widget.token)?.isNotEmpty == true;
                            if (!hasToken) {
                              final t2 = AppLocalizations.of(context);
                              showDialog<bool>(context: context, barrierDismissible: false, builder: (_) {
                                return AppModal(
                                  title: t2.profile,
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
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget bodyPage({required bool hasToken, required String enter, required String createAccount}){
    return Padding(
      padding: const EdgeInsets.all(20),
      child: hasToken
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedSection == 'rooms') ...[
                SizedBox(
                  height: 570,
                  child: RoomsPage(
                    token: (Api.currentAccessToken() ?? widget.token ?? ''),
                    onLogout: () async { await (widget.onLogout ?? () async {})(); },
                    embedded: true,
                  ),
                ),
              ] else if (selectedSection == 'inbox') ...[
                SizedBox(
                  height: 570,
                  child: InboxPage(
                    token: (Api.currentAccessToken() ?? widget.token ?? ''),
                    embedded: true,
                  ),
                ),
              ] else if (selectedSection == 'marketplace') ...[
                SizedBox(
                  height: 570,
                  child: MarketplaceListPage(
                    token: (Api.currentAccessToken() ?? widget.token ?? ''),
                    embedded: true,
                  ),
                ),
              ] else if (selectedSection == 'admin') ...[
                SizedBox(
                  height: 570,
                  child: AdminPage(
                    token: (Api.currentAccessToken() ?? widget.token ?? ''),
                    embedded: true,
                  ),
                ),
              ] else if (selectedSection == 'profile') ...[
                SizedBox(
                  height: 570,
                  child: const ProfilePage(embedded: true),
                ),
              ] else if (selectedSection == 'settings') ...[
                SizedBox(
                  height: 570,
                  child: const SettingsPage(embedded: true),
                ),
              ],
            ]
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: [brandRed, brandBlack], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.catching_pokemon, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('Bem-vindo ao Sistema', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginPage(onLoggedIn: (widget.onLoggedIn ?? (a, b) async {}))));
                    },
                    child: Text(enter),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterPage(onRegistered: (widget.onLoggedIn ?? (a, b) async {}))));
                    },
                    child: Text(createAccount),
                  ),
                ],
              ),
            ],
          ),
    );
  }


  final ValueNotifier<bool> _showMore = ValueNotifier<bool>(true);
  Widget cardWelcomeHomeWidget(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/welcome_bg.jpg',
                  fit: BoxFit.cover,
                ),

                Container(
                  color: Colors.black.withOpacity(0.35),
                ),

                // Conteúdo sobre a imagem
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [brandBlack, brandRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.catching_pokemon, color: brandRed),
                          const SizedBox(width: 8),
                          const Text(
                            'Novo por aqui?',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // BOTÃO (lado direito)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {
                        _showMore.value = !_showMore.value;
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          _showMore.value ? Icons.keyboard_arrow_down: Icons.keyboard_arrow_up,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
              ],
            ),
          ),
          if(_showMore.value)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "Seja muito bem-vindo ao PokeGenTrade, o seu ponto de encontro para comunicação, compra, venda e troca de itens relacionados ao universo Poketibia!\n\nAqui você encontra uma comunidade feita por jogadores e para jogadores, criada para facilitar negociações, compartilhar oportunidades e conectar treinadores que buscam evoluir sua jornada no jogo.",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [brandBlack, brandRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Row(
                      children: const [
                        Icon(Icons.catching_pokemon, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Regras de Convivência da Comunidade',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    '''
                    Para manter um ambiente seguro, justo e agradável para todos, siga as regras abaixo. 
                    O descumprimento pode resultar em advertências, suspensões ou banimento da plataforma.

                    🤝 1. Respeito é fundamental
                      • Trate todos os membros com educação e cordialidade.
                      • Não serão tolerados insultos, ameaças, discriminação, discurso de ódio ou assédio de qualquer tipo.

                    💬 2. Comunicação clara e honesta
                      • Utilize uma linguagem adequada nos chats, anúncios e mensagens privadas.
                      • Evite spam, flood, conteúdo ofensivo ou mensagens enganosas.

                    🔄 3. Negociações justas e transparentes
                      • Seja claro sobre valores, itens, condições e prazos.
                      • Não tente enganar, aplicar golpes ou omitir informações relevantes.
                      • Honre todos os acordos firmados.

                    🛑 4. Proibição de golpes e fraudes
                      • Qualquer tentativa de scam, falsificação de provas, uso de contas falsas ou má-fé resultará em punição severa.
                      • Negociações suspeitas devem ser denunciadas à administração.

                    📸 5. Sistema de avaliação e comprovação
                      • Após uma negociação concluída com sucesso, o usuário pode solicitar uma avaliação.
                      • É obrigatório enviar comprovações válidas da negociação.
                      • As avaliações e pontuações são realizadas exclusivamente pela administração, garantindo imparcialidade.

                    🧑‍⚖️ 6. Decisões da administração
                      • A equipe administrativa é responsável por analisar denúncias, provas e avaliações.
                      • As decisões são tomadas visando o bem coletivo da comunidade.
                      • Tentativas de burlar regras ou decisões resultarão em penalidades adicionais.

                    🔐 7. Uso responsável da conta
                      • Cada usuário é totalmente responsável pelas ações realizadas em sua conta.
                      • Não compartilhe seus dados de acesso com terceiros.

                    📢 8. Anúncios e conteúdos
                      • Anúncios devem ser claros, verdadeiros e relacionados ao universo PokeTibia.
                      • Conteúdos ilegais, impróprios ou fora do tema serão removidos sem aviso prévio.

                    ⚠️ 9. Denúncias
                      • Utilize os canais apropriados para denunciar comportamentos inadequados.
                      • Denúncias falsas ou feitas de má-fé também estão sujeitas a punições.

                    🧩 10. Convivência e espírito de comunidade
                      • Este espaço foi criado para ajudar, conectar e fortalecer a comunidade.
                      • Cooperação, paciência e empatia são essenciais para um bom ambiente.

                    Ao utilizar a plataforma, você concorda com todas as regras acima.
                          ''',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () {
                          _showMore.value = !_showMore.value;
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.all(6),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

}
