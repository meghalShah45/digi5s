// Drives the real app: login -> dashboard -> flash news -> logout.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/login_flow_test.dart -d <device> \
//     --dart-define=API_BASE_URL=http://localhost:8000 \
//     --dart-define=LIVE_EMAIL=... --dart-define=LIVE_PASSWORD=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seicho_app/main.dart' as app;

const _email = String.fromEnvironment('LIVE_EMAIL');
const _password = String.fromEnvironment('LIVE_PASSWORD');

/// Pumps frames until any of [finders] matches; returns the index that matched.
Future<int> waitForAny(WidgetTester tester, List<Finder> finders, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    for (var i = 0; i < finders.length; i++) {
      if (finders[i].evaluate().isNotEmpty) return i;
    }
  }
  throw TestFailure('Timed out waiting for any of $finders');
}

Future<void> logout(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.account_circle_outlined).first);
  await waitFor(tester, find.text('Log out'));
  await tester.tap(find.text('Log out').last);
  await waitFor(tester, find.widgetWithText(FilledButton, 'Log out'));
  await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
  await waitFor(tester, find.text('Sign in to continue'));
}

/// Pumps frames until [finder] matches (the app has spinners that never
/// settle, so pumpAndSettle cannot be used).
Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> pumpFor(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('login, dashboard, flash news, logout', (tester) async {
    expect(_email, isNotEmpty, reason: 'pass --dart-define=LIVE_EMAIL');
    app.main();

    // A previous run may have left a session behind: start from a clean login.
    final start = await waitForAny(tester, [find.text('Sign in to continue'), find.textContaining('Hey, ')]);
    if (start == 1) await logout(tester);
    await binding.takeScreenshot('01_login');

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), _password);
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));

    // Dashboard header greets the user by first name.
    await waitFor(tester, find.textContaining('Hey, '));
    await pumpFor(tester, const Duration(seconds: 3)); // let counts / banners load
    await binding.takeScreenshot('02_dashboard');

    // Open flash news from the grid (below the fold) and come back.
    final flash = find.textContaining('Flash\nNews');
    await tester.scrollUntilVisible(flash, 200, scrollable: find.byType(Scrollable).first);
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.tap(flash.first);
    await waitFor(tester, find.text('Flash News'));
    await pumpFor(tester, const Duration(seconds: 2));
    await binding.takeScreenshot('03_flash_news');
    await tester.pageBack();
    await pumpFor(tester, const Duration(seconds: 1));
    await tester.scrollUntilVisible(find.textContaining('Hey, '), -300, scrollable: find.byType(Scrollable).first);
    await waitFor(tester, find.textContaining('Hey, '));

    // Logout via the account menu.
    await logout(tester);
    await binding.takeScreenshot('04_logged_out');
  });
}
