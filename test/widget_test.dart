import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:carehub_plus/app/app.dart';
import 'package:carehub_plus/features/auth/data/repositories/auth_repository.dart';
import 'package:carehub_plus/features/splash/presentation/pages/splash_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final mockAuthRepository = MockAuthRepository();
    when(() => mockAuthRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(App(authRepository: mockAuthRepository));
    // Splash page should render
    expect(find.byType(SplashPage), findsOneWidget);

    // Allow the splash timer and animations to complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
