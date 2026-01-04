import '../../dm/domain/usecases/get_peer_messages.dart';
import '../../dm/domain/usecases/mark_peer_read.dart';
import '../../../app/locator.dart';

class DmController {
  Future<List<Map<String, dynamic>>> loadHistory(String peerId) async {
    final r = await GetPeerMessagesUseCase(Locator.dm)(peerId, limit: 50);
    if (!r.isOk) return <Map<String, dynamic>>[];
    return (r.data ?? []);
  }
  Future<List<Map<String, dynamic>>> loadMore(String peerId, String oldestIso) async {
    final r = await GetPeerMessagesUseCase(Locator.dm)(peerId, limit: 50, before: oldestIso);
    if (!r.isOk) return <Map<String, dynamic>>[];
    return (r.data ?? []);
  }
  Future<bool> markRead(String peerId) async {
    final r = await MarkPeerReadUseCase(Locator.dm)(peerId);
    return r.isOk;
  }
}
