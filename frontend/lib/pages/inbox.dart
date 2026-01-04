import 'package:flutter/material.dart';
import 'dart:async';
import 'dm.dart';
import '../services/api.dart';
import '../services/user_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/status_banner.dart';
import '../l10n/app_localizations.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../features/dm/presentation/inbox_controller.dart';

class InboxPage extends StatefulWidget {
  final String token;
  final bool embedded;
  const InboxPage({super.key, required this.token, this.embedded = false});
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<Map<String, dynamic>> items = [];
  Map<String, String> lastSeen = {};
  Timer? timer;
  String query = '';
  Timer? _persistDebounce;
  String feedback = '';
  bool onlyUnread = false;
  String sortMode = 'unread_first';
  int displayCount = 20;
  IO.Socket? socket;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  final InboxController _controller = InboxController();
  Future<void> load() async {
    final list = await _controller.load();
    if (list.isNotEmpty) {
      items = list;
      items.sort((a, b) {
        final ua = int.tryParse((a['unread'] ?? 0).toString()) ?? 0;
        final ub = int.tryParse((b['unread'] ?? 0).toString()) ?? 0;
        if (ua != ub) return ub.compareTo(ua);
        DateTime? da, db;
        try { da = DateTime.tryParse((a['lastAt'] ?? '').toString()); } catch (_) {}
        try { db = DateTime.tryParse((b['lastAt'] ?? '').toString()); } catch (_) {}
        if (da != null && db != null) return db.compareTo(da);
        return ((b['lastAt'] ?? '') as String).compareTo((a['lastAt'] ?? '') as String);
      });
      for (final it in items) {
        if ((it['peerName'] ?? '').toString().isEmpty) {
          UserCache.getName(it['peerId']).then((name) {
            if (name.isNotEmpty) {
              it['peerName'] = name;
              if (mounted) setState(() {});
            }
          });
        }
      }
      feedback = '';
      setState(() {});
    }
  }
  @override
  void initState() {
    super.initState();
    _loadQuery();
    load();
    _connectSocket();
  }
  void _connectSocket() {
    final authToken = Api.currentAccessToken() ?? widget.token;
    socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setRandomizationFactor(0.5)
          .setAuth({'token': authToken})
          .build(),
    );
    socket!.on('dm:unread:update', (data) async {
      try {
        if (data is List) {
          for (final it in items) {
            final mList = data.cast<dynamic>();
            final found = mList.firstWhere((u) => (u)['peerId'] == it['peerId'], orElse: () => {'count': 0});
            it['unread'] = found['count'] ?? 0;
          }
          setState(() {});
        }
      } catch (_) {}
    });
    socket!.on('dm:message:new', (_) {
      load();
    });
  }
  Future<void> _loadQuery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final q = prefs.getString('inbox_query') ?? '';
      onlyUnread = prefs.getBool('inbox_only_unread') ?? false;
      sortMode = prefs.getString('inbox_sort') ?? 'unread_first';
      displayCount = prefs.getInt('inbox_display_count') ?? 20;
      if (q.isNotEmpty) {
        setState(() => query = q);
      }
      setState(() {});
    } catch (_) {}
  }
  @override
  void dispose() {
    timer?.cancel();
    socket?.disconnect();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final totalUnread = items.fold<int>(0, (acc, e) => acc + (int.tryParse((e['unread'] ?? 0).toString()) ?? 0));
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white.withValues(alpha: 0.95),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                      const Icon(Icons.mail, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(totalUnread > 0 ? '${t.inboxDMs} ($totalUnread)' : t.inboxDMs, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(onPressed: load, icon: const Icon(Icons.refresh, color: Colors.white)),
                      TextButton(
                        onPressed: () async {
                          final peers = items.map((e) => e['peerId'].toString()).toSet().toList();
                          await _controller.markAllRead(peers);
                          load();
                        },
                        child: Text(t.markAllRead, style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                if (feedback.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: StatusBanner(text: feedback, type: 'error', actionText: 'Tentar novamente', onAction: load)),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    decoration: InputDecoration(labelText: t.searchByNameOrId, prefixIcon: Icon(Icons.search, color: brandRed), filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    onChanged: (v) {
                      setState(() => query = v.trim());
                      _persistDebounce?.cancel();
                      _persistDebounce = Timer(const Duration(milliseconds: 400), () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('inbox_query', query);
                        } catch (_) {}
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilterChip(
                        label: Text(t.unreadOnly),
                        selected: onlyUnread,
                        onSelected: (v) async {
                          setState(() => onlyUnread = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('inbox_only_unread', onlyUnread);
                        },
                      ),
                      DropdownButton<String>(
                        value: sortMode,
                        items: [
                          DropdownMenuItem(value: 'unread_first', child: Text(t.unreadFirst)),
                          DropdownMenuItem(value: 'recent', child: Text(t.mostRecent)),
                        ],
                        onChanged: (v) async {
                          if (v == null) return;
                          setState(() => sortMode = v);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setString('inbox_sort', sortMode);
                        },
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          setState(() => displayCount += 20);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('inbox_display_count', displayCount);
                        },
                        child: Text(t.loadMore),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered().length,
                    itemBuilder: (_, i) {
                      final it = _filtered()[i];
                      return ListTile(
                        title: Text((it['peerName'] ?? it['peerId']).toString()),
                        subtitle: Text(it['lastContent']),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          if ((it['unread'] ?? 0) > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: brandRed, borderRadius: BorderRadius.circular(10)), child: Text('${it['unread']}', style: const TextStyle(color: Colors.white))),
                          const SizedBox(width: 6),
                          Text(it['lastAt']),
                        ]),
                        onTap: () {
                          lastSeen[it['peerId']] = it['lastAt'] ?? '';
                          _controller.markRead(it['peerId']);
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => DmPage(token: widget.token, userId: it['peerId'])));
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
    );
    if (widget.embedded) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(title: Text(totalUnread > 0 ? '${t.inboxDMs} ($totalUnread)' : t.inboxDMs)),
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
          content,
        ],
      ),
    );
  }
  List<Map<String, dynamic>> _filtered() {
    List<Map<String, dynamic>> list = items.where((it) {
      final name = (it['peerName'] ?? '').toString().toLowerCase();
      final id = (it['peerId'] ?? '').toString().toLowerCase();
      final q = query.toLowerCase();
      final passesQuery = q.isEmpty || name.contains(q) || id.contains(q);
      final passesUnread = !onlyUnread || ((int.tryParse((it['unread'] ?? 0).toString()) ?? 0) > 0);
      return passesQuery && passesUnread;
    }).toList();
    if (sortMode == 'recent') {
      list.sort((a, b) {
        DateTime? da, db;
        try { da = DateTime.tryParse((a['lastAt'] ?? '').toString()); } catch (_) {}
        try { db = DateTime.tryParse((b['lastAt'] ?? '').toString()); } catch (_) {}
        if (da != null && db != null) return db.compareTo(da);
        return ((b['lastAt'] ?? '') as String).compareTo((a['lastAt'] ?? '') as String);
      });
    } else {
      list.sort((a, b) {
        final ua = int.tryParse((a['unread'] ?? 0).toString()) ?? 0;
        final ub = int.tryParse((b['unread'] ?? 0).toString()) ?? 0;
        if (ua != ub) return ub.compareTo(ua);
        DateTime? da, db;
        try { da = DateTime.tryParse((a['lastAt'] ?? '').toString()); } catch (_) {}
        try { db = DateTime.tryParse((b['lastAt'] ?? '').toString()); } catch (_) {}
        if (da != null && db != null) return db.compareTo(da);
        return ((b['lastAt'] ?? '') as String).compareTo((a['lastAt'] ?? '') as String);
      });
    }
    if (list.length > displayCount) {
      list = list.take(displayCount).toList();
    }
    return list;
  }
}
