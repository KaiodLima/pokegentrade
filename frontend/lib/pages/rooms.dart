import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'chat.dart';
import 'inbox.dart';
import 'contacts.dart';
import 'marketplace_list.dart';
import 'admin.dart';
import '../services/api.dart';
import '../widgets/status_banner.dart';
import 'profile.dart';
import '../services/me_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diagnostics.dart';
import '../l10n/app_localizations.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../services/user_cache.dart';
import '../widgets/user_hover_card.dart';
import '../features/chat/presentation/rooms_controller.dart';
import '../app/locator.dart';

class RoomsPage extends StatefulWidget {
  final String token;
  final Future<void> Function() onLogout;
  final bool embedded;
  const RoomsPage({super.key, required this.token, required this.onLogout, this.embedded = false});
  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  List<Map<String, dynamic>> rooms = [];
  String? selectedRoom;
  final msgCtrl = TextEditingController();
  final ScrollController roomScrollCtrl = ScrollController();
  String feedback = '';
  bool sending = false;
  int dmUnread = 0;
  Map<String, int> roomsUnread = {};
  Map<String, Map<String, String>> roomsSummary = {};
  String roomsFilter = '';
  Timer? _timer;
  IO.Socket? dmSocket;
  bool isAdmin = false;
  String? meName;
  String? myId;
  final Color brandRed = const Color(0xFFD32F2F);
  final Color brandBlack = Colors.black;
  List<Map<String, dynamic>> roomMessages = [];
  final Map<String, List<Map<String, dynamic>>> messagesByRoom = {};
  List<Uint8List> attachThumbs = [];
  final RoomsController _controller = RoomsController();
  OverlayEntry? _hoverEntry;
  bool _hoverOverTarget = false;
  bool _hoverOverCard = false;
  Timer? _hoverHideTimer;
  void _scheduleHoverHide() {
    _hoverHideTimer?.cancel();
    _hoverHideTimer = Timer(const Duration(milliseconds: 180), () {
      if (!_hoverOverTarget && !_hoverOverCard) {
        try { _hoverEntry?.remove(); _hoverEntry = null; } catch (_) {}
      }
    });
  }
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        if (roomScrollCtrl.hasClients) {
          roomScrollCtrl.animateTo(
            roomScrollCtrl.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      } catch (_) {}
    });
  }
  void _decodeRole() {
    try {
      final parts = widget.token.split('.');
      if (parts.length == 3) {
        final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        final role = payload['role']?.toString();
        final roles = (payload['roles'] is List) ? (payload['roles'] as List).map((e) => e.toString()).toList() : <String>[];
        isAdmin = role == 'Admin' || role == 'SuperAdmin' || roles.contains('Admin') || roles.contains('SuperAdmin');
        myId = payload['sub']?.toString();
      }
    } catch (_) {}
  }

  Future<void> loadRooms() async {
    await Api.init();
    final res = await Api.get('/rooms');
    final sumRes = await Api.get('/rooms/summary');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        rooms = list.map<Map<String, dynamic>>((e) => {
          'id': (e['id'] ?? '').toString(),
          'name': (e['name'] ?? '').toString(),
        }).toList();
      } else {
        rooms = [];
      }
      if (sumRes.statusCode == 200) {
        final s = jsonDecode(sumRes.body);
        if (s is List) {
          roomsSummary = {};
          for (final it in s) {
            final rid = (it['id'] ?? '').toString();
            roomsSummary[rid] = {
              'lastContent': (it['lastContent'] ?? '').toString(),
              'lastAt': (it['lastAt'] ?? '').toString(),
            };
          }
        }
      }
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('selected_room');
      if (saved != null && rooms.any((r) => r['id'] == saved)) {
        selectedRoom = saved;
      } else {
        selectedRoom = rooms.isNotEmpty ? rooms.first['id'].toString() : null;
      }
      setState(() {});
      if (selectedRoom != null) {
        roomMessages = messagesByRoom[selectedRoom!] ?? [];
        setState(() {});
        await loadRoomMessages();
        dmSocket?.emit('rooms:join', {'roomId': selectedRoom});
      }
    }
  }
  Future<void> loadMe() async {
    meName = await MeCache.getName();
    setState(() {});
  }
  Future<void> loadRoomMessages({String q = ''}) async {
    if (selectedRoom == null) return;
    final loaded = await _controller.loadMessages(selectedRoom!);
    if (loaded.isNotEmpty) {
      messagesByRoom[selectedRoom!] = loaded;
      roomMessages = loaded;
      final ids = loaded.map((m) => (m['userId'] ?? '').toString()).where((x) => x.isNotEmpty).toSet();
      for (final uid in ids) { ensureUserInfo(uid); }
      setState(() {});
      _scrollToEnd();
    }
  }
  final Map<String, Map<String, String>> _userInfo = {};
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

  Future<void> sendMessage() async {
    if (selectedRoom == null) return;
    if (msgCtrl.text.trim().isEmpty) return;
    if (sending) return;
    sending = true;
    setState(() {});
    // Tenta via socket (tempo real)
    try {
      dmSocket?.emit('rooms:message:send', {'roomId': selectedRoom, 'content': msgCtrl.text});
      final optimistic = {
        'id': '${DateTime.now().toIso8601String()}:${'me'}',
        'content': msgCtrl.text,
        'createdAt': DateTime.now().toIso8601String(),
        'userId': 'me',
        'displayName': meName ?? '',
      };
      final rid = selectedRoom!;
      final list = messagesByRoom[rid] ?? [];
      list.add(optimistic);
      messagesByRoom[rid] = list;
      roomMessages = List<Map<String, dynamic>>.from(list);
      setState(() {});
    } catch (_) {}
    final sr = await _controller.send(selectedRoom!, msgCtrl.text);
    if (sr) {
      feedback = 'Enviado';
      msgCtrl.clear();
      await loadRoomMessages();
    } else {
      feedback = 'Erro ao enviar';
    }
    sending = false;
    setState(() {});
  }
  Future<void> attachImage() async {
    if (selectedRoom == null) return;
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
    await Api.post('/rooms/$selectedRoom/messages', {'roomId': selectedRoom, 'content': objectUrl});
    await loadRoomMessages();
    attachThumbs = [];
    setState(() {});
  }
  void openSearch() {
    showDialog(context: context, builder: (_) {
      final ctrl = TextEditingController();
      return AlertDialog(
        title: const Text('Buscar mensagens'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Termo de busca')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
          ElevatedButton(onPressed: () {
            final q = ctrl.text.trim();
            Navigator.of(context).pop();
            loadRoomMessages(q: q);
          }, child: const Text('Buscar')),
        ],
      );
    });
  }

  @override
  void initState() {
    super.initState();
    loadRooms();
    loadUnread();
    loadMe();
    _connectUnreadSocket();
    _decodeRole();
  }
  void _connectUnreadSocket() {
    final authToken = Api.currentAccessToken() ?? widget.token;
    dmSocket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
          .setTransports(['websocket','polling'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setRandomizationFactor(0.5)
          .setAuth({'token': authToken})
          .setQuery({'token': authToken})
          .setPath('/socket.io')
          .build(),
    );
    dmSocket!.on('dm:unread:update', (data) {
      try {
        if (data is List) {
          dmUnread = data.fold<int>(0, (acc, e) => acc + (int.tryParse(((e as dynamic)['count'] ?? 0).toString()) ?? 0));
          setState(() {});
        }
      } catch (_) {}
    });
    dmSocket!.on('rooms:unread:update', (data) {
      try {
        if (data is List) {
          roomsUnread = {};
          for (final e in data) {
            final rid = ((e as dynamic)['roomId'] ?? '').toString();
            final c = int.tryParse(((e as dynamic)['count'] ?? 0).toString()) ?? 0;
            if (rid.isNotEmpty) roomsUnread[rid] = c;
          }
          setState(() {});
        }
      } catch (_) {}
    });
    dmSocket!.on('rooms:message:new', (data) {
      try {
        if (data is Map) {
          final rid = (data['roomId']?.toString() ?? '');
          final id = (data['id']?.toString() ?? '');
          final msg = {'id': id, 'content': data['content'], 'createdAt': data['createdAt'], 'userId': data['userId'], 'displayName': (data['displayName'] ?? '').toString()};
          final list = messagesByRoom[rid] ?? [];
          // Remove otimista do mesmo conteúdo
          final idxOpt = list.indexWhere((m) => (m['userId'] ?? '') == 'me' && (m['content'] ?? '') == (data['content'] ?? ''));
          if (idxOpt >= 0) list.removeAt(idxOpt);
          // Evita duplicata por id
          final exists = list.any((m) => (m['id'] ?? '') == id);
          if (!exists) list.add(msg);
          messagesByRoom[rid] = list;
          if (selectedRoom == rid) {
            roomMessages = List<Map<String, dynamic>>.from(list);
            setState(() {});
            _scrollToEnd();
          }
        }
      } catch (_) {}
    });
    dmSocket!.on('rooms:message:edit', (data) {
      try {
        if (data is Map) {
          final id = (data['id'] ?? '').toString();
          final idx = roomMessages.indexWhere((m) => (m['id'] ?? '') == id);
          if (idx >= 0) {
            roomMessages[idx]['content'] = data['content'] ?? roomMessages[idx]['content'];
            roomMessages[idx]['edited'] = true;
            setState(() {});
          }
        }
      } catch (_) {}
    });
    dmSocket!.on('rooms:message:delete', (data) {
      try {
        if (data is Map) {
          final id = (data['id'] ?? '').toString();
          final idx = roomMessages.indexWhere((m) => (m['id'] ?? '') == id);
          if (idx >= 0) {
            roomMessages.removeAt(idx);
            setState(() {});
          }
        }
      } catch (_) {}
    });
  }
  Future<void> loadUnread() async {
    final res = await Api.get('/dm/unread');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      if (list is List) {
        dmUnread = list.fold<int>(0, (acc, e) => acc + (int.tryParse((e['count'] ?? 0).toString()) ?? 0));
        setState(() {});
      }
    }
    final resRooms = await Api.get('/rooms/unread');
    if (resRooms.statusCode == 200) {
      final list = jsonDecode(resRooms.body);
      if (list is List) {
        roomsUnread = {};
        for (final e in list) {
          final rid = (e['roomId'] ?? '').toString();
          final c = int.tryParse((e['count'] ?? 0).toString()) ?? 0;
          if (rid.isNotEmpty) roomsUnread[rid] = c;
        }
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    Widget contentBody = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Row(
          children: [
            Expanded(
              flex: 2,
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
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.list, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Salas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Buscar salas'),
                        onChanged: (v) {
                          setState(() => roomsFilter = v.trim().toLowerCase());
                        },
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: rooms.where((r) {
                            if (roomsFilter.isEmpty) return true;
                            final n = (r['name'] ?? '').toString().toLowerCase();
                            final rid = (r['id'] ?? '').toString().toLowerCase();
                            final last = (roomsSummary[r['id']]?['lastContent'] ?? '').toLowerCase();
                            return n.contains(roomsFilter) || rid.contains(roomsFilter) || last.contains(roomsFilter);
                          }).length,
                          itemBuilder: (_, i) {
                            final filtered = rooms.where((r) {
                              if (roomsFilter.isEmpty) return true;
                              final n = (r['name'] ?? '').toString().toLowerCase();
                              final rid = (r['id'] ?? '').toString().toLowerCase();
                              final last = (roomsSummary[r['id']]?['lastContent'] ?? '').toLowerCase();
                              return n.contains(roomsFilter) || rid.contains(roomsFilter) || last.contains(roomsFilter);
                            }).toList();
                            final r = filtered[i];
                            final rid = r['id'].toString();
                            final unread = roomsUnread[rid] ?? 0;
                            final lastContent = roomsSummary[rid]?['lastContent'] ?? '';
                            final lastAt = roomsSummary[rid]?['lastAt'] ?? '';
                            final selected = selectedRoom == rid;
                            return ListTile(
                              selected: selected,
                              title: Text(r['name']),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                if (lastContent.isNotEmpty) Text(lastContent, maxLines: 1, overflow: TextOverflow.ellipsis),
                                if (lastAt.isNotEmpty) Text(lastAt, style: const TextStyle(fontSize: 11)),
                              ]),
                              trailing: unread > 0 ? Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: brandRed, borderRadius: BorderRadius.circular(10)), child: Text('$unread', style: const TextStyle(color: Colors.white))) : null,
                              onTap: () async {
                                setState(() => selectedRoom = rid);
                                await loadRoomMessages();
                                dmSocket?.emit('rooms:join', {'roomId': rid});
                                _scrollToEnd();
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
            Expanded(
              flex: 7,
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
                            const Icon(Icons.forum, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(t.publicRooms, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            IconButton(onPressed: openSearch, icon: const Icon(Icons.search, color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRoom,
                        items: rooms.map<DropdownMenuItem<String>>((r) {
                          final rid = r['id'].toString();
                          final name = r['name'].toString();
                          final count = roomsUnread[rid] ?? 0;
                          return DropdownMenuItem<String>(value: rid, child: Text(count > 0 ? '$name ($count)' : name));
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: t.publicRooms,
                          prefixIcon: Icon(Icons.meeting_room, color: brandRed),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (v) async {
                          setState(() => selectedRoom = v);
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('selected_room', v ?? '');
                          } catch (_) {}
                          roomMessages = messagesByRoom[selectedRoom!] ?? [];
                          setState(() {});
                          await loadRoomMessages();
                          if (v != null) {
                            dmSocket?.emit('rooms:join', {'roomId': v});
                          }
                          _scrollToEnd();
                        },
                      ),
                      if (selectedRoom != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(roomsSummary[selectedRoom!]?['lastContent']?.isNotEmpty == true ? roomsSummary[selectedRoom!]!['lastContent']! : 'Sem mensagens recentes', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              Text(roomsSummary[selectedRoom!]?['lastAt']?.isNotEmpty == true ? roomsSummary[selectedRoom!]!['lastAt']! : '', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            ]),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
                          onPressed: () {
                            if (selectedRoom == null || (selectedRoom ?? '').isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione uma sala primeiro')));
                              return;
                            }
                            _scrollToEnd();
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage(token: widget.token, roomId: selectedRoom!)));
                          },
                          child: Text(t.openRealtimeChat),
                        ),
                      ),
                      Expanded(
                        child: (selectedRoom == null || roomMessages.isEmpty)
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, color: brandRed, size: 48),
                                    const SizedBox(height: 8),
                                    Text('Nenhuma mensagem ainda', style: TextStyle(color: brandBlack.withValues(alpha: 0.8))),
                                    const SizedBox(height: 4),
                                    Text('Seja o primeiro a enviar', style: TextStyle(color: brandBlack.withValues(alpha: 0.6), fontSize: 12)),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: roomScrollCtrl,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: roomMessages.length,
                                itemBuilder: (_, i) {
                                  final m = roomMessages[i];
                                  final uid = (m['userId'] ?? '').toString();
                                  final mine = (myId != null && uid == (myId ?? '')) || uid == 'me';
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
                                  final isImage = ((m['content'] ?? '') as String).toLowerCase().contains(RegExp(r'\.(png|jpg|jpeg|gif|webp)$')) || ((m['content'] ?? '') as String).startsWith('http');
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
                                                    onEnter: (_) {
                                                      _hoverOverTarget = true;
                                                      if (_hoverEntry == null) {
                                                        _hoverEntry = OverlayEntry(builder: (_) {
                                                          return UserHoverCard(
                                                            link: link,
                                                            userId: uid,
                                                            displayName: name,
                                                            avatarUrl: avatar,
                                                            onMessage: () {
                                                              try { _hoverEntry?.remove(); _hoverEntry = null; } catch (_) {}
                                                              openMiniChat(uid);
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
                                                    },
                                                    onExit: (_) { _hoverOverTarget = false; _scheduleHoverHide(); },
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _hoverOverTarget = true;
                                                        if (_hoverEntry == null) {
                                                          _hoverEntry = OverlayEntry(builder: (_) {
                                                            return UserHoverCard(
                                                              link: link,
                                                              userId: uid,
                                                              displayName: name,
                                                              avatarUrl: avatar,
                                                              onMessage: () {
                                                                try { _hoverEntry?.remove(); _hoverEntry = null; } catch (_) {}
                                                                openMiniChat(uid);
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
                                                      },
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
                                            GestureDetector(
                                              child: Builder(builder: (context) {
                                                final linkName = LayerLink();
                                                return CompositedTransformTarget(
                                                  link: linkName,
                                                  child: MouseRegion(
                                                    onEnter: (_) {
                                                      _hoverOverTarget = true;
                                                      if (_hoverEntry == null) {
                                                        _hoverEntry = OverlayEntry(builder: (_) {
                                                          return UserHoverCard(
                                                            link: linkName,
                                                            userId: uid,
                                                            displayName: name,
                                                            avatarUrl: avatar,
                                                            onMessage: () {
                                                              try { _hoverEntry?.remove(); _hoverEntry = null; } catch (_) {}
                                                              openMiniChat(uid);
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
                                                    },
                                                    onExit: (_) { _hoverOverTarget = false; _scheduleHoverHide(); },
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        _hoverOverTarget = true;
                                                        if (_hoverEntry == null) {
                                                          _hoverEntry = OverlayEntry(builder: (_) {
                                                            return UserHoverCard(
                                                              link: linkName,
                                                              userId: uid,
                                                              displayName: name,
                                                              avatarUrl: avatar,
                                                              onMessage: () {
                                                                try { _hoverEntry?.remove(); _hoverEntry = null; } catch (_) {}
                                                                openMiniChat(uid);
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
                                                      },
                                                      child: Text(mine ? 'Você' : (name.isNotEmpty ? name : uid), style: const TextStyle(fontSize: 12)),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
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
                                                if (isImage) ...[
                                                  Image.network((m['content'] ?? ''), height: 160, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported)),
                                                ] else ...[
                                                  Text(((m['content'] ?? '') as String) + ((m['edited'] == true) ? ' (editada)' : '')),
                                                ],
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
                      Row(
                        children: [
                          Expanded(child: TextField(controller: msgCtrl, decoration: InputDecoration(labelText: t.message, filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
                          const SizedBox(width: 8),
                          IconButton(onPressed: attachImage, icon: const Icon(Icons.attach_file)),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: brandRed, foregroundColor: Colors.white),
                            onPressed: sending ? null : sendMessage,
                            child: Text(sending ? t.sending : t.send),
                          ),
                        ],
                      ),
                      if (attachThumbs.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
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
                      const SizedBox(height: 8),
                      if (feedback.isNotEmpty) StatusBanner(
                        text: feedback,
                        type: feedback.startsWith('Erro') ? 'error' : (feedback.startsWith('Aguarde') ? 'warning' : 'success'),
                        actionText: feedback.startsWith('Erro') || feedback.startsWith('Aguarde') ? t.tryAgain : null,
                        onAction: (feedback.startsWith('Erro') || feedback.startsWith('Aguarde')) && !sending ? sendMessage : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
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
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        child: Row(
                          children: const [
                            Icon(Icons.menu, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Atalhos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ContactsPage(token: widget.token)));
                        },
                        child: Text(t.contacts),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => InboxPage(token: widget.token)));
                        },
                        child: Text(dmUnread > 0 ? '${t.inboxDMs} ($dmUnread)' : t.inboxDMs),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketplaceListPage(token: widget.token)));
                        },
                        child: Text(t.marketplace),
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
      return Stack(
        fit: StackFit.expand,
        children: [
          contentBody,
          Positioned(
            right: 12,
            bottom: 12,
            child: SizedBox(
              width: 900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: openMiniUserIds.map((uid) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: MiniDmPopup(token: widget.token, userId: uid, onClose: () {
                    setState(() => openMiniUserIds.remove(uid));
                  }),
                )).toList(),
              ),
            ),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(meName != null && meName!.isNotEmpty ? '${t.publicRooms} • $meName' : t.publicRooms), actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            children: [
              const Icon(Icons.mail),
              const SizedBox(width: 4),
              Text(dmUnread > 0 ? '$dmUnread' : ''),
            ],
          ),
        ),
        IconButton(onPressed: loadRooms, icon: const Icon(Icons.refresh)),
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminPage(token: widget.token)));
              },
              child: Text(t.admin),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())).then((_) => loadMe());
            },
            child: Text(t.profile),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiagnosticsPage()));
            },
            child: Text(t.diagnostics),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
            child: Text(t.settings),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            onPressed: () async {
              await widget.onLogout();
            },
            child: Text(t.logout),
          ),
        ),
      ]),
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
          contentBody,
          Positioned(
            right: 12,
            bottom: 12,
            child: SizedBox(
              width: 900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: openMiniUserIds.map((uid) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: MiniDmPopup(token: widget.token, userId: uid, onClose: () {
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
  final List<String> openMiniUserIds = [];
  void openMiniChat(String uid) {
    if (uid.isEmpty) return;
    if (!openMiniUserIds.contains(uid)) {
      setState(() => openMiniUserIds.add(uid));
    }
  }
  @override
  void dispose() {
    _timer?.cancel();
    dmSocket?.disconnect();
    msgCtrl.dispose();
    roomScrollCtrl.dispose();
    super.dispose();
  }
}
class MiniDmPopup extends StatefulWidget {
  final String token;
  final String userId;
  final VoidCallback onClose;
  const MiniDmPopup({super.key, required this.token, required this.userId, required this.onClose});
  @override
  State<MiniDmPopup> createState() => _MiniDmPopupState();
}
class _MiniDmPopupState extends State<MiniDmPopup> {
  final msgCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();
  List<Map<String, dynamic>> messages = [];
  String info = '';
  IO.Socket? socket;
  String? myId;
  String displayName = '';
  String avatarUrl = '';
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
              scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
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
            scrollCtrl.jumpTo(scrollCtrl.position.maxScrollExtent);
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
                  Expanded(child: Text(displayName.isNotEmpty ? displayName : widget.userId)),
                  IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close, size: 18)),
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
