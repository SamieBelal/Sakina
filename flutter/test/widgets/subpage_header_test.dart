// SubpageHeader widget tests pin three things that matter for the
// back-navigation refactor on /quests, /settings, /store:
//   1. When inside a route that can pop, a back button is rendered and
//      tapping it actually pops.
//   2. When at the root of a navigator (canPop == false), no back button
//      is rendered (so the title stays aligned).
//   3. The optional `trailing` slot renders to the right of the title
//      (used by Quests for the token chip).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sakina/widgets/subpage_header.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const Key('go-to-sub'),
                onPressed: () => context.push('/sub'),
                child: const Text('open sub'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/sub',
          builder: (context, state) => const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SubpageHeader(
                  title: 'Sub Page',
                  subtitle: 'Subtitle here',
                  trailing: Text('TRAIL', key: Key('trailing')),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  testWidgets('renders back button on a pushed sub-route and pops on tap',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Push to /sub via the in-page button.
    await tester.tap(find.byKey(const Key('go-to-sub')));
    await tester.pumpAndSettle();

    expect(find.text('Sub Page'), findsOneWidget,
        reason: 'router should have pushed to /sub');

    // Back button is present and tapping it returns to the root page.
    final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backButton, findsOneWidget);

    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('open sub'), findsOneWidget,
        reason: 'tapping back button should pop back to root');
    expect(find.text('Sub Page'), findsNothing);
  });

  testWidgets('omits back button when canPop is false', (tester) async {
    // Build a router that lands directly on the SubpageHeader — no push,
    // no stack to pop. canPop() should be false here.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SubpageHeader(title: 'Root'),
              ),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('renders trailing widget when provided', (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.tap(find.byKey(const Key('go-to-sub')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trailing')), findsOneWidget);
    expect(find.text('Subtitle here'), findsOneWidget);
  });
}
