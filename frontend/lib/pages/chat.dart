import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api.dart';
import '../widgets/status_banner.dart';
import '../services/net_error.dart';
import '../l10n/app_localizations.dart';
import '../services/notify.dart';
import '../services/user_cache.dart';
import '../features/chat/presentation/chat_controller.dart';
import '../app/locator.dart';
import '../widgets/user_hover_card.dart';

class ChatPage extends StatefulWidget {
  final String token;
  final String roomId;
  const ChatPage({super.key, required this.token, required this.roomId});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final msgCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  List<Map<String, dynamic>> messages = [];
  String info = '';
  Timer? _typingDebounce;
  IO.Socket? socket;
  bool connected = false;
  bool joined = false;
  bool sending = false;
  String? userId;
  bool loadingMore = false;
  int reconnectAttempts = 0;
  int _backoffMs = 2000;
  final int _backoffMaxMs = 30000;
  Timer? _backoffTimer;
  bool rateLimited = false;
  int _rateRemainingMs = 0;
  Timer? _rateTimer;
  void Function(String)? _tokenListener;
  final Map<String, Map<String, String>> _userInfo = {};
  final List<String> openMiniUserIds = [];
  OverlayEntry? _hoverEntry;
  bool _hoverOverTarget = false;
  bool _hoverOverCard = false;
  Timer? _hoverHideTimer;
  final ChatController _controller = ChatController();
  void _scheduleHoverHide() {
    _hoverHideTimer?.cancel();
    _hoverHideTimer = Timer(const Duration(milliseconds: 180), () {
      if (!_hoverOverTarget && !_hoverOverCard) {
        try { _hoverEntry?.remove(); _hoverEntry = null; } catch (_) {}
      }
    });
  }
  void _showUserCard(LayerLink link, String uid, String name, String avatar) {
    if (_hoverEntry != null) {
      // already visible; just update tracking
      return;
    }
    _hoverEntry = OverlayEntry(builder: (_) {
      return UserHoverCard(
        link: link,
        userId: uid,
        displayName: name,
        avatarUrl: avatar,
        onMessage: () {
          try { _hoverEntry?.remove(); _hoverEntry = null; } catch (_) {}
          if (!openMiniUserIds.contains(uid)) {
            setState(() => openMiniUserIds.add(uid));
          }
        },
        onClose: () {
          try { _hoverEntry?.remove(); _hoverEntry = null; } catch (_) {}
        },
        onEnterCard: () { _hoverOverCard = true; },
        onExitCard: () { _hoverOverCard = false; _scheduleHoverHide(); },
      );
    });
    Overlay.of(context).insert(_hoverEntry!);
  }

  Future<void> loadHistory() async {
    final loaded = await _controller.loadHistory(widget.roomId);
    if (loaded.isNotEmpty) {
      messages = loaded;
      final ids = messages.map((m) => (m['userId'] ?? '').toString()).where((x) => x.isNotEmpty).toSet();
      for (final uid in ids) { ensureUserInfo(uid); }
      setState(() {});
      final mr = await _controller.markRead(widget.roomId);
      if (mr) {
        try { socket?.emit('rooms:read', {'roomId': widget.roomId}); } catch (_) {}
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (scrollCtrl.hasClients) {
            scrollCtrl.animateTo(
              scrollCtrl.position.maxScrollExtent + 100,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        } catch (_) {}
      });
    } else {
      info = 'Erro ao carregar histórico';
      setState(() {});
    }
  }
  Future<void> ensureUserInfo(String uid) async {
    if (uid.isEmpty || _userInfo.containsKey(uid)) return;
    final name = await UserCache.getName(uid);
    String avatarUrl = '';
    final ur = await Locator.users.getById(uid);
    if (ur.isOk && ur.data != null) {
      avatarUrl = ur.data!.avatarUrl;
    }
    _userInfo[uid] = {'displayName': name, 'avatarUrl': avatarUrl};
    if (mounted) setState(() {});
  }
  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    } catch (_) {
      return iso;
    }
  }
  Future<void> loadMore() async {
    if (loadingMore || messages.isEmpty) return;
    loadingMore = true;
    final oldest = messages.first['createdAt'] ?? '';
    final res = await Api.get('/rooms/${widget.roomId}/messages?limit=50&before=$oldest');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List && list.isNotEmpty) {
        final more = list.reversed.map<Map<String, dynamic>>((e) => {
          'id': e is Map ? (e['id']?.toString() ?? '') : '',
          'content': e is Map ? e['content'] ?? '' : e.toString(),
          'createdAt': e is Map ? e['createdAt'] ?? '' : '',
          'userId': e is Map ? e['userId'] ?? '' : '',
          'displayName': e is Map ? e['displayName'] ?? '' : '',
        }).toList();
        messages = [...more, ...messages];
        setState(() {});
      }
    } else {
      info = NetError.isTimeout(res) ? 'Tempo esgotado ao carregar mais mensagens' : 'Erro ao carregar mais mensagens';
      setState(() {});
    }
    loadingMore = false;
  }

  void connectSocket() {
    final authToken = Api.currentAccessToken() ?? widget.token;
    socket = IO.io('http://localhost:3000', IO.OptionBuilder()
        .setTransports(['websocket','polling'])
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000)
        .setRandomizationFactor(0.5)
        .setAuth({'token': authToken})
        .setQuery({'token': authToken})
        .setPath('/socket.io')
        .build());
    socket!.onConnect((_) {
      reconnectAttempts = 0;
      _backoffMs = 2000;
      _backoffTimer?.cancel();
      setState(() {
        connected = true;
        info = '';
      });
      socket!.emit('rooms:join', {'roomId': widget.roomId});
    });
    socket!.on('rooms:joined', (data) {
      joined = true;
      setState(() {});
    });
    socket!.onConnectError((err) async {
      final ok = await Api.refresh();
      if (ok) {
        final t = Api.currentAccessToken() ?? widget.token;
        final opts = (socket!.io.options ?? {});
        opts['auth'] = {'token': t};
        socket!.io.options = opts;
        socket!.connect();
      }
    });
    socket!.on('reconnect_attempt', (_) {
      reconnectAttempts += 1;
      setState(() {
        info = 'Reconectando... tentativa $reconnectAttempts';
        connected = false;
      });
    });
    socket!.on('reconnect', (_) {
      setState(() {
        info = '';
        connected = true;
      });
    });
    socket!.on('reconnect_error', (_) {
      setState(() {
        info = 'Falha na reconexão';
      });
    });
    socket!.on('reconnect_failed', (_) {
      setState(() {
        info = 'Reconexão esgotada';
        connected = false;
      });
      _backoffTimer?.cancel();
      _backoffTimer = Timer(Duration(milliseconds: _backoffMs), () {
        restartConnection();
        _backoffMs = ((_backoffMs * 2).clamp(2000, _backoffMaxMs)).toInt();
      });
    });
    socket!.on('rooms:message:new', (data) {
      if (data is Map) {
        final id = (data['id']?.toString() ?? '');
        final exists = messages.any((m) => (m['id'] ?? '') == id);
        if (!exists) {
          messages.add({'id': id, 'content': data['content'], 'createdAt': data['createdAt'], 'userId': data['userId']});
        }
        final sender = (data['userId']?.toString() ?? '');
        if (sender.isNotEmpty) ensureUserInfo(sender);
        if (sender != (userId ?? '')) Notify.maybeNotify('Nova mensagem', data['content']?.toString() ?? '');
        setState(() {});
        if (scrollCtrl.hasClients) {
          scrollCtrl.animateTo(
            scrollCtrl.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
    socket!.on('rooms:message:edit', (data) {
      if (data is Map) {
        final id = (data['id'] ?? '').toString();
        final idx = messages.indexWhere((m) => (m['id'] ?? '') == id);
        if (idx >= 0) {
          messages[idx]['content'] = data['content'] ?? messages[idx]['content'];
          messages[idx]['edited'] = true;
          setState(() {});
        }
      }
    });
    socket!.on('rooms:message:delete', (data) {
      if (data is Map) {
        final id = (data['id'] ?? '').toString();
        final idx = messages.indexWhere((m) => (m['id'] ?? '') == id);
        if (idx >= 0) {
          messages.removeAt(idx);
          setState(() {});
        }
      }
    });
    socket!.on('rooms:rate_limit:error', (data) {
      if (data is Map && data['remaining_ms'] is int) {
        _rateTimer?.cancel();
        rateLimited = true;
        _rateRemainingMs = data['remaining_ms'] as int;
        setState(() => info = 'Aguarde ${(_rateRemainingMs / 1000).ceil()}s');
        _rateTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          _rateRemainingMs -= 1000;
          if (_rateRemainingMs <= 0) {
            rateLimited = false;
            info = '';
            t.cancel();
          } else {
            info = 'Aguarde ${(_rateRemainingMs / 1000).ceil()}s';
          }
          if (mounted) setState(() {});
        });
      }
    });
    socket!.on('rooms:typing', (data) {
      if (data is Map) {
        final name = (data['displayName'] ?? 'Usuário').toString();
        setState(() => info = '$name digitando...');
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => info = '');
        });
      }
    });
    socket!.onDisconnect((_) => setState(() => connected = false));
  }
  void restartConnection() {
    try {
      socket?.disconnect();
      socket = null;
      connectSocket();
    } catch (_) {}
  }
  void reconnect() {
    try {
      final t = Api.currentAccessToken() ?? widget.token;
      if (socket != null) {
        final opts = (socket!.io.options ?? {});
        opts['auth'] = {'token': t};
        socket!.io.options = opts;
        socket!.connect();
      } else {
        connectSocket();
      }
    } catch (_) {}
  }

  Future<void> sendMessage() async {
    final content = msgCtrl.text.trim();
    if (content.isEmpty) return;
    if (!connected || !joined || sending) return;
    sending = true;
    setState(() {});
    socket?.emit('rooms:message:send', {'roomId': widget.roomId, 'content': content});
    final now = DateTime.now().toIso8601String();
    final localId = 'local:$now:${userId ?? ''}';
    messages.add({'id': localId, 'content': content, 'createdAt': now, 'userId': userId ?? ''});
    if (scrollCtrl.hasClients) {
      scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
    }
    msgCtrl.clear();
    Timer(const Duration(milliseconds: 300), () {
      sending = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    Api.init();
    try {
      final parts = widget.token.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        userId = payload['sub']?.toString();
      }
    } catch (_) {}
    loadHistory();
    connectSocket();
    _tokenListener = (t) {
      try {
        if (socket != null) {
          final opts = (socket!.io.options ?? {});
          opts['auth'] = {'token': t};
          socket!.io.options = opts;
          if (!connected) socket!.connect();
        }
      } catch (_) {}
    };
    Api.addTokenListener(_tokenListener!);
  }

  @override
  void dispose() {
    if (_tokenListener != null) {
      Api.removeTokenListener(_tokenListener!);
    }
    socket?.disconnect();
    msgCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Sala ${widget.roomId}')),
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
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.black.withValues(alpha: 0.3)],
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: StatusBanner(
                          text: connected ? t.connected : (info.isNotEmpty ? info : t.disconnected),
                          type: connected ? 'success' : (info.contains('Falha') || info.contains('esgotada') ? 'error' : 'warning'),
                          actionText: connected ? null : t.newConnection,
                          onAction: connected ? null : restartConnection,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: messages.length,
                          itemBuilder: (_, i) {
                            final m = messages[i];
                            final uid = (m['userId'] ?? '').toString();
                            final mine = (userId != null && uid == (userId ?? ''));
                            final info = _userInfo[uid] ?? {};
                            final name = (info['displayName'] ?? (m['displayName'] ?? '')).toString();
                            final avatar = (info['avatarUrl'] ?? '').toString();
                            if (uid.isNotEmpty && !_userInfo.containsKey(uid)) { ensureUserInfo(uid); }
                            final dateText = _fmt((m['createdAt'] ?? '').toString());
                            final bubbleColor = mine ? Colors.red.shade50 : Colors.grey.shade200;
                            final align = mine ? Alignment.centerRight : Alignment.centerLeft;
                            final radius = mine
                                ? const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12))
                                : const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12));
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: [
                                      if (!mine)
                                        Builder(builder: (context) {
                                          final link = LayerLink();
                                          return CompositedTransformTarget(
                                            link: link,
                                            child: MouseRegion(
                                              onEnter: (_) { _hoverOverTarget = true; _showUserCard(link, uid, name, avatar); },
                                              onExit: (_) { _hoverOverTarget = false; _scheduleHoverHide(); },
                                              child: GestureDetector(
                                                onTap: () { _hoverOverTarget = true; _showUserCard(link, uid, name, avatar); },
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: avatar.isNotEmpty
                                                      ? Image.network(avatar, width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 28, height: 28, color: Colors.grey.shade200, child: const Icon(Icons.person)))
                                                      : Container(width: 28, height: 28, color: Colors.grey.shade200, child: const Icon(Icons.person)),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      const SizedBox(width: 8),
                                      Builder(builder: (context) {
                                        final linkName = LayerLink();
                                        return CompositedTransformTarget(
                                          link: linkName,
                                          child: MouseRegion(
                                            onEnter: (_) { _hoverOverTarget = true; _showUserCard(linkName, uid, name, avatar); },
                                            onExit: (_) { _hoverOverTarget = false; _scheduleHoverHide(); },
                                            child: GestureDetector(
                                              onTap: () { _hoverOverTarget = true; _showUserCard(linkName, uid, name, avatar); },
                                              child: Text(mine ? 'Você' : (name.isNotEmpty ? name : uid), style: const TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  Align(
                                    alignment: align,
                                    child: Container(
                                      constraints: const BoxConstraints(maxWidth: 620),
                                      decoration: BoxDecoration(color: bubbleColor, borderRadius: radius),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      child: Column(
                                        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          Text(((m['content'] ?? '') as String) + ((m['edited'] == true) ? ' (${t.edited})' : '')),
                                          const SizedBox(height: 6),
                                          Text(dateText, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(onPressed: loadMore, child: Text(t.loadMore)),
                      ),
                      if (info.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: StatusBanner(text: info, type: info.contains('Falha') ? 'error' : 'warning', actionText: t.retryConnect, onAction: reconnect)),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(child: TextField(controller: msgCtrl, decoration: InputDecoration(labelText: t.message), onChanged: (_) {
                              if (_typingDebounce != null) return;
                              socket?.emit('rooms:typing', {'roomId': widget.roomId});
                              _typingDebounce = Timer(const Duration(seconds: 2), () {
                                _typingDebounce = null;
                              });
                            }, enabled: connected && !rateLimited)),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: (!connected || sending || rateLimited || !joined) ? null : sendMessage,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(sending ? t.sending : t.send, style: TextStyle(color: Colors.white),),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(onPressed: reconnect, child: Text(t.retryConnect)),
                            const SizedBox(width: 8),
                            OutlinedButton(onPressed: restartConnection, child: Text(t.newConnection)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: SizedBox(
              width: 900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: openMiniUserIds.map((uid) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _MiniDmPopup(token: (Api.currentAccessToken() ?? widget.token), userId: uid, onClose: () {
                    setState(() => openMiniUserIds.remove(uid));
                  }),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniDmPopup extends StatefulWidget {
  final String token;
  final String userId;
  final VoidCallback onClose;
  const _MiniDmPopup({required this.token, required this.userId, required this.onClose});
  @override
  State<_MiniDmPopup> createState() => _MiniDmPopupState();
}
class _MiniDmPopupState extends State<_MiniDmPopup> {
  final msgCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();
  List<Map<String, dynamic>> messages = [];
  String displayName = '';
  String avatarUrl = '';
  IO.Socket? socket;
  String? myId;
  bool sending = false;
  @override
  void initState() {
    super.initState();
    try {
      final parts = (Api.currentAccessToken() ?? widget.token).split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        myId = payload['sub']?.toString();
      }
    } catch (_) {}
    _loadPeer();
    _connect();
  }
  Future<void> _loadPeer() async {
    final res = await Api.get('/users/${widget.userId}');
    if (res.statusCode == 200) {
      try {
        final j = jsonDecode(res.body);
        displayName = (j['displayName'] ?? '').toString();
        avatarUrl = (j['avatarUrl'] ?? '').toString();
        setState(() {});
      } catch (_) {}
    }
  }
  void _connect() {
    final t = Api.currentAccessToken() ?? widget.token;
    socket = IO.io('http://localhost:3000', IO.OptionBuilder()
        .setTransports(['websocket','polling'])
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000)
        .setAuth({'token': t})
        .build());
    socket!.onConnect((_) {
      socket!.emit('dm:join', {'userId': widget.userId});
    });
    socket!.on('dm:message:new', (data) {
      if (data is Map) {
        messages.add({'id': data['id']?.toString() ?? '', 'content': data['content'], 'createdAt': data['createdAt'], 'from': data['from'], 'displayName': data['displayName']});
        setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (scrollCtrl.hasClients) {
              scrollCtrl.animateTo(
                scrollCtrl.position.maxScrollExtent + 100,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          } catch (_) {}
        });
      }
    });
  }
  Future<void> _send() async {
    final c = msgCtrl.text.trim();
    if (c.isEmpty || sending) return;
    sending = true;
    setState(() {});
    try {
      socket?.emit('dm:message:send', {'userId': widget.userId, 'content': c});
      final now = DateTime.now().toIso8601String();
      messages.add({'id': 'local:$now', 'content': c, 'createdAt': now, 'from': myId ?? ''});
      msgCtrl.clear();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (scrollCtrl.hasClients) {
            scrollCtrl.animateTo(
              scrollCtrl.position.maxScrollExtent + 100,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        } catch (_) {}
      });
    } catch (_) {}
    sending = false;
    setState(() {});
  }
  @override
  void dispose() {
    socket?.disconnect();
    msgCtrl.dispose();
    scrollCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: avatarUrl.isNotEmpty ? Image.network(avatarUrl, width: 28, height: 28, fit: BoxFit.cover) : Container(width: 28, height: 28, color: Colors.white.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(displayName.isNotEmpty ? displayName : widget.userId, style: const TextStyle(color: Colors.white))),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, color: Colors.white, size: 18)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: messages.length,
                itemBuilder: (_, i) {
                  final m = messages[i];
                  final mine = (m['from']?.toString() ?? '') == (myId ?? '');
                  final align = mine ? Alignment.centerRight : Alignment.centerLeft;
                  final color = mine ? Colors.red.shade50 : Colors.grey.shade200;
                  final radius = mine
                      ? const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12))
                      : const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12));
                  return Align(
                    alignment: align,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(color: color, borderRadius: radius),
                      child: Text((m['content'] ?? '').toString()),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: msgCtrl, decoration: const InputDecoration(labelText: 'Mensagem'))),
                  IconButton(onPressed: sending ? null : _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
