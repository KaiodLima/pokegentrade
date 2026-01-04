import '../../../../core/result.dart';
import '../entities/inbox_item.dart';

abstract class DmRepository {
  Future<Result<List<InboxItem>>> getInbox();
  Future<Result<List<Map<String, dynamic>>>> getUnreadCounts();
  Future<Result<bool>> markPeerRead(String peerId);
  Future<Result<List<Map<String, dynamic>>>> getPeerMessages(String peerId, {int limit = 50, String? before});
}
