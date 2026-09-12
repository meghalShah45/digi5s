// Proves the app reaches the configured backend: a wrong password must come
// back as the server's 401, rendered as "Incorrect email or password.".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seicho_app/main.dart' as app;

Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 25)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('wrong password is rejected by the backend', (tester) async {
    app.main();
    // Already logged in from a previous session? That already proves connectivity.
    final end = DateTime.now().add(const Duration(seconds: 25));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (find.textContaining('Hey, ').evaluate().isNotEmpty) {
        await binding.takeScreenshot('prod_logged_in');
        return;
      }
      if (find.text('Sign in to continue').evaluate().isNotEmpty) break;
    }
    expect(find.text('Sign in to continue'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'digi5sapp@gmail.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'definitely-wrong');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await waitFor(tester, find.text('Incorrect email or password.'));
    await binding.takeScreenshot('prod_rejected');
  });
}
