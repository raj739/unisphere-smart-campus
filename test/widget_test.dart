import 'package:flutter_test/flutter_test.dart';
import 'package:unisphere_mobile/main.dart';

void main() {
  testWidgets('UniSphere app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const UniSphereApp());

    expect(find.byType(UniSphereApp), findsOneWidget);
  });
}
