import 'package:flutter_test/flutter_test.dart';

import 'package:carehub_plus/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Splash page should render
    expect(find.text('Carehub'), findsOneWidget);
  });
}
