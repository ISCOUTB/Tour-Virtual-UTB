import 'package:flutter_test/flutter_test.dart';

import 'package:utb_virtual_placeholder/main.dart';

void main() {
  testWidgets('UTB Virtual placeholder carga tabs principales', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const UtbVirtualApp());

    expect(find.text('UTB Virtual · MVP Placeholder'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Recorrido'), findsOneWidget);
    expect(find.text('POI'), findsOneWidget);
  });
}
