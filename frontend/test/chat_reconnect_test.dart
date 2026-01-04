import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poketibia_platform_frontend/pages/chat.dart';

void main() {
  testWidgets('Chat exibe tentativa de reconexão e ação de nova conexão', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0In0.sig';
    await tester.pumpWidget(MaterialApp(home: ChatPage(token: token, roomId: 'sala-1')));
    await tester.pump(const Duration(milliseconds: 100));
    final state = tester.state(find.byType(ChatPage)) as dynamic;
    state.connected = false;
    state.reconnectAttempts = 3;
    state.info = 'Reconectando... tentativa ${state.reconnectAttempts}';
    // ignore: invalid_use_of_protected_member
    state.setState(() {});
    await tester.pump();
    expect(find.textContaining('Reconectando... tentativa 3'), findsNWidgets(2));
    expect(find.text('Nova conexão'), findsNWidgets(2));
  });
}
