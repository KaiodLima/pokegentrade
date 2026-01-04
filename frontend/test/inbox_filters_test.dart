import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poketibia_platform_frontend/pages/inbox.dart';

void main() {
  testWidgets('Inbox filtra por apenas não lidas e ordena', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0In0.sig';
    await tester.pumpWidget(MaterialApp(home: InboxPage(token: token)));
    await tester.pump(const Duration(milliseconds: 100));
    final state = tester.state(find.byType(InboxPage)) as dynamic;
    state.items = [
      {'peerId': '1', 'peerName': 'Alice', 'lastContent': 'Oi', 'lastAt': '2025-01-01T10:00:00Z', 'unread': 0},
      {'peerId': '2', 'peerName': 'Bob', 'lastContent': 'Hi', 'lastAt': '2025-01-02T10:00:00Z', 'unread': 3},
      {'peerId': '3', 'peerName': 'Carol', 'lastContent': 'Hello', 'lastAt': '2025-01-03T10:00:00Z', 'unread': 1},
    ];
    state.onlyUnread = true;
    state.sortMode = 'recent';
    state.query = '';
    state.displayCount = 10;
    // ignore: invalid_use_of_protected_member
    state.setState(() {});
    await tester.pump();
    final tiles = find.byType(ListTile);
    expect(tiles, findsNWidgets(2));
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);
    // Order by recent means Carol (2025-01-03) first
    final firstTitle = tester.widget<ListTile>(find.byType(ListTile).first).title as Text;
    expect(firstTitle.data, equals('Carol'));
  });
}
