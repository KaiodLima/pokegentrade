import '../../dm/domain/usecases/get_inbox.dart';
import '../../dm/domain/usecases/mark_peer_read.dart';
import '../../../app/locator.dart';

class InboxController {
  Future<List<Map<String, dynamic>>> load() async {
    final r = await GetInboxUseCase(Locator.dm)();
    if (!r.isOk) return <Map<String, dynamic>>[];
    return (r.data ?? []).map<Map<String, dynamic>>((e) => {
      'peerId': e.peerId,
      'peerName': e.peerName,
      'lastContent': e.lastContent,
      'lastAt': e.lastAt,
      'unread': e.unread,
    }).toList();
  }
  Future<void> markAllRead(List<String> peers) async {
    for (final p in peers) {
      await MarkPeerReadUseCase(Locator.dm)(p);
    }
  }
  Future<bool> markRead(String peerId) async {
    final r = await MarkPeerReadUseCase(Locator.dm)(peerId);
    return r.isOk;
  }
}
