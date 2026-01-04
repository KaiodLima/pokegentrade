import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api.dart';
import '../widgets/status_banner.dart';
import '../l10n/app_localizations.dart';
import '../services/notify.dart';
import '../services/user_cache.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import '../features/dm/presentation/dm_controller.dart';

class DmPage extends StatefulWidget {
  final String token;
  final String userId;
  const DmPage({super.key, required this.token, required this.userId});
  @override
  State<DmPage> createState() => _DmPageState();
}

class _DmPageState extends State<DmPage> {
  final msgCtrl = TextEditingController();
  final scrollCtrl = ScrollController();
  List<Map<String, dynamic>> messages = [];
  String info = '';
  IO.Socket? socket;
  bool connected = false;
  String? myId;
  String? peerName;
  void Function(String)? _tokenListener;
  Timer? _typingDebounce;
  bool sending = false;
  int reconnectAttempts = 0;
  int _backoffMs = 2000;
  final int _backoffMaxMs = 30000;
  Timer? _backoffTimer;
  bool rateLimited = false;
  int _rateRemainingMs = 0;
  Timer? _rateTimer;
  bool loadingMore = false;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  List<Uint8List> attachThumbs = [];
  final DmController _controller = DmController();

  void connectSocket() {
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
    socket!.onConnect((_) {
      reconnectAttempts = 0;
      _backoffMs = 2000;
      _backoffTimer?.cancel();
      setState(() {
        connected = true;
        info = '';
      });
      socket!.emit('dm:join', {'userId': widget.userId});
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
    socket!.on('dm:message:new', (data) {
      if (data is Map) {
        messages.add({'id': data['id']?.toString() ?? '', 'content': data['content'], 'createdAt': data['createdAt'], 'from': data['from'], 'displayName': data['displayName']});
        if ((data['from']?.toString() ?? '') != (myId ?? '')) {
          Notify.maybeNotify('Nova DM', data['content']?.toString() ?? '');
        }
        setState(() {});
        if (scrollCtrl.hasClients) {
          scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
        }
      }
    });
    socket!.on('dm:read', (data) {
      if (data is Map) {
        final at = (data['at'] ?? '').toString();
        final reader = (data['userId'] ?? '').toString();
        if (reader == widget.userId) {
          for (final m in messages) {
            if (m['from'] == myId && (m['readAt'] == null || (m['readAt'] as String).isEmpty)) {
              m['readAt'] = at;
            }
          }
          setState(() {});
        }
      }
    });
    socket!.on('dm:message:edit', (data) {
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
    socket!.on('dm:message:delete', (data) {
      if (data is Map) {
        final id = (data['id'] ?? '').toString();
        final idx = messages.indexWhere((m) => (m['id'] ?? '') == id);
        if (idx >= 0) {
          messages.removeAt(idx);
          setState(() {});
        }
      }
    });
    socket!.on('dm:typing', (data) {
      if (data is Map) {
        final name = (data['displayName'] ?? 'Usuário').toString();
        setState(() => info = '$name digitando...');
        Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => info = '');
        });
      }
    });
    socket!.on('dm:rate_limit:error', (data) {
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
    if (!connected || sending) return;
    sending = true;
    setState(() {});
    socket?.emit('dm:message:send', {'userId': widget.userId, 'content': content});
    msgCtrl.clear();
    Timer(const Duration(milliseconds: 300), () {
      sending = false;
      if (mounted) setState(() {});
    });
  }
  Future<void> attachImage() async {
    final res = await FilePicker.platform.pickFiles(withReadStream: true, allowMultiple: false);
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    final allowedExt = {'png','jpg','jpeg','gif','webp'};
    final ext = (f.extension ?? '').toLowerCase();
    if (!allowedExt.contains(ext) || (f.bytes == null)) return;
    attachThumbs = [f.bytes!];
    setState(() {});
    final ct = ext == 'png' ? 'image/png' : (ext == 'gif' ? 'image/gif' : (ext == 'webp' ? 'image/webp' : 'image/jpeg'));
    final pres = await Api.post('/uploads', {'filename': f.name, 'contentType': ct});
    if (!(pres.statusCode == 200 || pres.statusCode == 201)) return;
    final p = jsonDecode(pres.body);
    String objectUrl = '';
    if ((p['method'] ?? '') == 'POST') {
      final uri = Uri.parse(p['postUrl']);
      final req = http.MultipartRequest('POST', uri);
      final fields = (p['fields'] as Map?) ?? {};
      fields.forEach((k, v) => req.fields[k] = v.toString());
      req.files.add(http.MultipartFile.fromBytes('file', f.bytes!, filename: f.name));
      final resp = await req.send();
      if (resp.statusCode != 204 && resp.statusCode != 201) return;
      objectUrl = (p['objectUrl'] ?? '').toString();
    } else {
      await http.put(Uri.parse(p['uploadUrl']), headers: {'Content-Type': ct}, body: f.bytes);
      objectUrl = p['uploadUrl'].toString().split('?').first;
    }
    if (objectUrl.isEmpty) return;
    socket?.emit('dm:message:send', {'userId': widget.userId, 'content': objectUrl});
    attachThumbs = [];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    Api.init();
    try {
      final parts = widget.token.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        myId = payload['sub']?.toString();
      }
    } catch (_) {}
    connectSocket();
    loadHistory();
    UserCache.getName(widget.userId).then((n) {
      if (n.isNotEmpty) {
        peerName = n;
        if (mounted) setState(() {});
      }
    });
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

  Future<void> loadHistory() async {
    final loaded = await _controller.loadHistory(widget.userId);
    if (loaded.isNotEmpty) {
      messages = loaded;
      setState(() {});
    } else {
      info = 'Erro ao carregar histórico';
      setState(() {});
    }
    await _controller.markRead(widget.userId);
    socket?.emit('dm:read', {'userId': widget.userId});
  }
  Future<void> loadMore() async {
    if (loadingMore || messages.isEmpty) return;
    loadingMore = true;
    setState(() {});
    final oldest = (messages.first['createdAt'] ?? '').toString();
    if (oldest.isEmpty) {
      loadingMore = false;
      setState(() {});
      return;
    }
    final more = await _controller.loadMore(widget.userId, oldest);
    if (more.isNotEmpty) {
      messages = [...more, ...messages];
      setState(() {});
    }
    loadingMore = false;
    setState(() {});
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
      appBar: AppBar(title: Text(peerName != null && peerName!.isNotEmpty ? 'DM com $peerName' : 'DM com ${widget.userId}')),
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
                          itemCount: messages.length,
                          itemBuilder: (_, i) {
                            final m = messages[i];
                            final isMe = myId != null && m['from'] == myId;
                  return ListTile(
                  title: ((m['content'] ?? '') as String).toLowerCase().contains(RegExp(r'\.(png|jpg|jpeg|gif|webp)$')) || ((m['content'] ?? '') as String).startsWith('http')
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(isMe ? 'Você' : (m['displayName'] ?? ''), style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 6),
                          Image.network((m['content'] ?? ''), height: 160, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                        ])
                      : Text(((m['content'] ?? '') as String) + ((m['edited'] == true) ? ' (${t.edited})' : '')),
                  subtitle: Text(m['createdAt'] ?? ''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isMe) Padding(padding: const EdgeInsets.only(right: 8), child: Text(m['readAt'] != null ? t.read : t.delivered, style: const TextStyle(fontSize: 12))),
                    Text(isMe ? 'Você' : (m['displayName'] ?? ''), style: const TextStyle(fontSize: 12)),
                  ]),
                              onLongPress: isMe ? () async {
                                final action = await showModalBottomSheet<String>(context: context, builder: (_) {
                                  return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                                    ListTile(title: Text(t.edit), onTap: () => Navigator.of(context).pop('edit')),
                                    ListTile(title: Text(t.delete), onTap: () => Navigator.of(context).pop('delete')),
                                  ]));
                                });
                                if (action == 'edit') {
                                  final edited = await showDialog<String>(context: context, builder: (_) {
                                    final ctrl = TextEditingController(text: m['content'] ?? '');
                                    return AlertDialog(
                                      title: Text(t.editMessage),
                                      content: TextField(controller: ctrl),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text(t.cancel)),
                                        ElevatedButton(onPressed: () => Navigator.of(context).pop(ctrl.text.trim()), child: Text(t.save)),
                                      ],
                                    );
                                  });
                                  if (edited != null && edited.isNotEmpty) {
                                    final id = (m['id'] ?? '').toString();
                                    if (id.isNotEmpty) {
                                      socket?.emit('dm:message:edit', {'userId': widget.userId, 'id': id, 'content': edited});
                                    }
                                  }
                                } else if (action == 'delete') {
                                  final id = (m['id'] ?? '').toString();
                                  if (id.isNotEmpty) {
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
                                    socket?.emit('dm:message:delete', {'userId': widget.userId, 'id': id});
                                  }
                                }
                              } : null,
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
                              socket?.emit('dm:typing', {'userId': widget.userId});
                              _typingDebounce = Timer(const Duration(seconds: 2), () {
                                _typingDebounce = null;
                              });
                            }, enabled: connected && !rateLimited)),
                            const SizedBox(width: 8),
                            IconButton(onPressed: attachImage, icon: const Icon(Icons.attach_file)),
                            const SizedBox(width: 4),
                            ElevatedButton(onPressed: (!connected || sending || rateLimited) ? null : sendMessage, child: Text(sending ? t.sending : t.send)),
                            const SizedBox(width: 8),
                            OutlinedButton(onPressed: reconnect, child: Text(t.retryConnect)),
                            const SizedBox(width: 8),
                            OutlinedButton(onPressed: restartConnection, child: Text(t.newConnection)),
                          ],
                        ),
                      ),
                      if (attachThumbs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: attachThumbs.map((b) => ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.memory(b, width: 60, height: 60, fit: BoxFit.cover),
                              )).toList(),
                            ),
                          ),
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
