import 'package:flutter_test/flutter_test.dart';

import 'package:carehub_plus/app/app.dart';
import 'package:carehub_plus/features/splash/presentation/pages/splash_page.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    // Splash page should render
    expect(find.byType(SplashPage), findsOneWidget);

    // Allow the splash timer and animations to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
