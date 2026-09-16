// Drives the first-run experience: intro -> get started -> subscribe pricing
// -> free trial form -> sign in -> dashboard -> logout.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/onboarding_flow_test.dart -d <device> \
//     --dart-define=API_BASE_URL=http://localhost:8000 \
//     --dart-define=LIVE_EMAIL=... --dart-define=LIVE_PASSWORD=...
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:seicho_app/core/auth/session.dart';
import 'package:seicho_app/main.dart' as app;
import 'package:seicho_app/screens/login_screen.dart';

const _email = String.fromEnvironment('LIVE_EMAIL');
const _password = String.fromEnvironment('LIVE_PASSWORD');

Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

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

Future<void> pumpFor(WidgetTester tester, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> logout(WidgetTester tester) async {
  final menu = find.byIcon(Icons.account_circle_outlined);
  if (menu.evaluate().isNotEmpty) {
    await tester.tap(menu.first);
    await waitFor(tester, find.text('Log out'));
    await tester.tap(find.text('Log out').last);
  } else {
    await tester.tap(find.byIcon(Icons.logout).first);
  }
  await waitFor(tester, find.widgetWithText(FilledButton, 'Log out'));
  await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
  await waitFor(tester, find.text('Welcome to Digi5S'));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('intro, get started, subscribe pricing, free trial, sign in', (tester) async {
    expect(_email, isNotEmpty, reason: 'pass --dart-define=LIVE_EMAIL');
    // Force the intro to show regardless of previous runs.
    await const FlutterSecureStorageResetter().reset();
    app.main();

    final start = await waitForAny(tester, [
      find.text('Digital 5S Management Platform'), // intro
      find.text('Choose how you want to get started:'), // get started
      find.textContaining('Hey, '), // dashboard (stale session)
      find.text('Super Admin Dashboard'),
    ]);
    if (start >= 2) await logout(tester);

    if (find.text('Digital 5S Management Platform').evaluate().isNotEmpty) {
      await pumpFor(tester, const Duration(seconds: 1));
      await binding.takeScreenshot('10_intro_1');
      // Walk all six pages with Next, then Get Started.
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await pumpFor(tester, const Duration(milliseconds: 500));
      }
      expect(find.text('5S News'), findsOneWidget);
      await binding.takeScreenshot('11_intro_last');
      await tester.tap(find.text('Get Started'));
    }

    await waitFor(tester, find.text('Choose how you want to get started:'));
    await pumpFor(tester, const Duration(seconds: 1));
    await binding.takeScreenshot('12_get_started');

    // Subscribe -> Show Pricing against the backend.
    await tester.tap(find.text('Subscribe'));
    await waitFor(tester, find.text('Subscription Registration'));
    await binding.takeScreenshot('13_subscribe');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await tester.enterText(find.widgetWithText(TextFormField, 'Name of the Organization'), 'Drive Test Org $stamp');
    await tester.enterText(find.widgetWithText(TextFormField, 'Unit Name or No.'), 'Unit 1');
    await tester.enterText(find.widgetWithText(TextFormField, 'Organization Admin Name'), 'Drive Tester');
    await tester.enterText(find.widgetWithText(TextFormField, 'Organization Admin Ph No.'), '9${stamp.toString().substring(4, 13)}');
    await tester.enterText(find.widgetWithText(TextFormField, 'Organization Admin E-mail'), 'drive.$stamp@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'No. of Employees to be subscribed'), '25');
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.text('Show Pricing'));
    await waitFor(tester, find.text('Total payable'));
    await binding.takeScreenshot('14_pricing');
    await tester.pageBack();
    await waitFor(tester, find.text('Choose how you want to get started:'));

    // Free trial form renders (not submitted: it would email a real address).
    await tester.tap(find.text('Start Free Trial'));
    await waitFor(tester, find.text('Free Trial Registration'));
    await binding.takeScreenshot('15_free_trial');
    await tester.pageBack();
    await waitFor(tester, find.text('Choose how you want to get started:'));

    // Sign in.
    await tester.tap(find.text('Sign In'));
    await waitFor(tester, find.text('Welcome Back'));
    await binding.takeScreenshot('16_login');
    final login = find.byType(LoginScreen);
    await tester.enterText(find.descendant(of: login, matching: find.widgetWithText(TextFormField, 'Email')), _email);
    await tester.enterText(find.descendant(of: login, matching: find.widgetWithText(TextFormField, 'Password')), _password);
    await pumpFor(tester, const Duration(milliseconds: 300));
    await tester.tap(find.descendant(of: login, matching: find.widgetWithText(ElevatedButton, 'Login')));
    final home = await waitForAny(tester, [find.textContaining('Hey, '), find.text('Super Admin Dashboard')]);
    await pumpFor(tester, const Duration(seconds: 2));
    await binding.takeScreenshot('17_home');

    if (home == 1) {
      await tester.tap(find.textContaining('Manage Active'));
      await waitFor(tester, find.text('Organization Status Overview'));
      await pumpFor(tester, const Duration(seconds: 2));
      await binding.takeScreenshot('18_organisations');
      await tester.pageBack();
      await waitFor(tester, find.text('Super Admin Dashboard'));
    }
    await logout(tester);
    await binding.takeScreenshot('19_logged_out');
  });
}

/// Clears the intro flag so the walkthrough shows on every run.
class FlutterSecureStorageResetter {
  const FlutterSecureStorageResetter();
  Future<void> reset() async {
    final store = SessionStore();
    await store.clear();
    // No API to unset the intro flag; write it back as unseen.
    await store.resetIntro();
  }
}
