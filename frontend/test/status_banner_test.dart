import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poketibia_platform_frontend/widgets/status_banner.dart';

void main() {
  testWidgets('StatusBanner mostra texto e ação quando fornecida', (WidgetTester tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatusBanner(text: 'Erro ao carregar', type: 'error', actionText: 'Tentar novamente', onAction: () { pressed = true; }),
      ),
    ));
    expect(find.text('Erro ao carregar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    expect(pressed, isTrue);
  });
  testWidgets('StatusBanner sem ação não mostra botão', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatusBanner(text: 'Informação', type: 'info'),
      ),
    ));
    expect(find.text('Informação'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });
}
