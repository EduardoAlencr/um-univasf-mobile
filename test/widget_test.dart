import 'package:flutter_test/flutter_test.dart';

import 'package:um_univasf_mobile/main.dart';

void main() {
  testWidgets('App abre na Home com módulos visíveis', (WidgetTester tester) async {
    await tester.pumpWidget(const UmUnivasfApp());
    await tester.pumpAndSettle();

    expect(find.text('Olá! 👋'), findsOneWidget);
    expect(find.text('Discente'), findsOneWidget);
    expect(find.text('Restaurante'), findsOneWidget);
  });

  testWidgets('Tab Calendário sem login mostra tela de bloqueio', (WidgetTester tester) async {
    await tester.pumpWidget(const UmUnivasfApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendário'));
    await tester.pumpAndSettle();

    expect(find.text('Sua agenda é só sua'), findsOneWidget);
  });
}
