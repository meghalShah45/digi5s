import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:seicho_app/features/zone_member/screens/my_tasks_screen.dart';

void main() {
  group('MyTasksScreen Tests', () {
    testWidgets('should display loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MyTasksScreen(),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MyTasksScreen(),
        ),
      );

      // Check if app bar title is present
      expect(find.text('My Tasks'), findsOneWidget);
    });

    testWidgets('should display tab bar with correct tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MyTasksScreen(),
        ),
      );

      // Check if tabs are present in the app bar
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
    });
  });
} 