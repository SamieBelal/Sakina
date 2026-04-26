// Phase 5c regression test (2026-04-26).
// Captures the 2-step Delete Account confirmation flow that was verified
// end-to-end on iPhone 17 sim with QABot:
//   1) showDeleteAccountWarningDialog — Cancel/Continue
//   2) showDeleteAccountConfirmDialog — type DELETE to enable button
// Both functions return true ONLY on the affirmative tap. Cancel and
// barrier dismiss return false. The destructive Delete My Account button
// stays disabled until the user types exactly DELETE.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina/features/settings/widgets/delete_account_dialogs.dart';

void main() {
  group('showDeleteAccountWarningDialog (step 1)', () {
    testWidgets('renders title, body, and both buttons', (tester) async {
      // Schedule the dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDeleteAccountWarningDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
      expect(
        find.textContaining('permanently delete your account'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'streaks, saved reflections, journal entries, and preferences'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('Cancel returns false', (tester) async {
      Future<bool>? pending;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  pending = showDeleteAccountWarningDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await pending, isFalse);
    });

    testWidgets('Continue returns true', (tester) async {
      Future<bool>? pending;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  pending = showDeleteAccountWarningDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(await pending, isTrue);
    });
  });

  group('showDeleteAccountConfirmDialog (step 2)', () {
    testWidgets('renders title, prompt, text field, and both buttons',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDeleteAccountConfirmDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Type DELETE to confirm account deletion.'),
          findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete My Account'), findsOneWidget);
    });

    testWidgets('Delete My Account button is disabled until DELETE is typed',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showDeleteAccountConfirmDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final deleteBtn = find.widgetWithText(TextButton, 'Delete My Account');
      expect(
        tester.widget<TextButton>(deleteBtn).onPressed,
        isNull,
        reason: 'must be disabled before typing',
      );

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.pump();
      expect(
        tester.widget<TextButton>(deleteBtn).onPressed,
        isNull,
        reason: 'must remain disabled with non-matching input',
      );

      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();
      expect(
        tester.widget<TextButton>(deleteBtn).onPressed,
        isNotNull,
        reason: 'must enable when DELETE is typed exactly',
      );
    });

    testWidgets('Cancel returns false even after typing DELETE',
        (tester) async {
      Future<bool>? pending;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  pending = showDeleteAccountConfirmDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await pending, isFalse,
          reason: 'Cancel must abort the deletion regardless of typed text');
    });

    testWidgets('Tapping Delete My Account with DELETE typed returns true',
        (tester) async {
      Future<bool>? pending;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  pending = showDeleteAccountConfirmDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      await tester.tap(find.text('Delete My Account'));
      await tester.pumpAndSettle();
      expect(await pending, isTrue);
    });

    testWidgets('matches with leading/trailing whitespace (trim)',
        (tester) async {
      Future<bool>? pending;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  pending = showDeleteAccountConfirmDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  DELETE  ');
      await tester.pump();

      await tester.tap(find.text('Delete My Account'));
      await tester.pumpAndSettle();
      expect(await pending, isTrue);
    });
  });

}
