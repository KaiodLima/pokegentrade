import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poketibia_platform_frontend/pages/chat.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Chat bloqueia input e enviar durante rate limit', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0In0.sig';
    await tester.pumpWidget(MaterialApp(home: ChatPage(token: token, roomId: 'sala-1')));
    await tester.pump(const Duration(milliseconds: 100));
    final state = tester.state(find.byType(ChatPage)) as dynamic;
    state.connected = true;
    state.rateLimited = true;
    state.info = 'Aguarde 5s';
    // ignore: invalid_use_of_protected_member
    state.setState(() {});
    await tester.pump();
    final textField = find.byType(TextField);
    final sendButton = find.widgetWithText(ElevatedButton, 'Enviar');
    expect(textField, findsOneWidget);
    expect(sendButton, findsOneWidget);
    // TextField disabled when rateLimited
    final tfWidget = tester.widget<TextField>(textField);
    expect(tfWidget.enabled, isFalse);
    // Button disabled when rateLimited
    final btnWidget = tester.widget<ElevatedButton>(sendButton);
    expect(btnWidget.onPressed, isNull);
    expect(find.textContaining('Aguarde'), findsWidgets);
  });
}
