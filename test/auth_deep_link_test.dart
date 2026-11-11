import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/app/router.dart';

void main() {
  testWidgets('email link callback lands on Discover, not an error page', (
    tester,
  ) async {
    final router = createAppRouter();
    await tester.pumpWidget(ProviderScope(child: ShotbookApp(router: router)));
    await tester.pumpAndSettle();

    router.go('/login-callback?code=abc');
    await tester.pumpAndSettle();
    expect(find.text('Find a frame'), findsOneWidget);
    expect(find.textContaining('Page Not Found'), findsNothing);

    router.go('com.shotbook.shotbook://login-callback?code=abc');
    await tester.pumpAndSettle();
    expect(find.text('Find a frame'), findsOneWidget);
  });
}
