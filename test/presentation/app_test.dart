import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:h20remind/app.dart';
import 'package:h20remind/domain/repositories/auth_repository.dart';

import '../support/fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late InMemoryWaterLog waterLog;
  late InMemoryGoals goals;
  late FakeReminderScheduler reminders;
  late FakeHealthSync health;

  setUp(() {
    auth = FakeAuthRepository();
    waterLog = InMemoryWaterLog([entry('a', 250, DateTime.now())]);
    goals = InMemoryGoals(2000);
    reminders = FakeReminderScheduler();
    health = FakeHealthSync();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // Pixel-sized phone viewport.
    if (tester.view.physicalSize == const Size(2400, 1800)) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
    }
    await tester.pumpWidget(
      H20RemindApp(
        authRepository: auth,
        reminderScheduler: reminders,
        healthSync: health,
        userRepositories: (_) => (waterLog: waterLog, goals: goals),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('signing in shows today’s progress', (tester) async {
    await pumpApp(tester);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('of 2,000 ml'), findsOneWidget);
    expect(find.text('13%'), findsOneWidget);
    expect(find.text('1,750 ml'), findsOneWidget);
  });

  testWidgets('sign-in errors are shown, cancellation is silent', (
    tester,
  ) async {
    await pumpApp(tester);

    auth.nextSignInError = const AuthCancelledException();
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('cancelled'), findsNothing);

    auth.nextSignInError = const AuthException('No network');
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.text('No network'), findsOneWidget);
  });

  testWidgets('quick add, custom add and delete with undo', (tester) async {
    auth = FakeAuthRepository(initialUser: testUser);
    await pumpApp(tester);

    final quickAdd = find.bySemanticsLabel('Add 500 ml');
    await tester.scrollUntilVisible(quickAdd, 200);
    await tester.tap(quickAdd);
    await tester.pumpAndSettle();
    expect(waterLog.all.map((e) => e.amountMl), [250, 500]);

    await tester.tap(find.text('Add water'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '330');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(waterLog.all.map((e) => e.amountMl), [250, 500, 330]);
    expect(find.text('1,080'), findsOneWidget);

    final delete = find.byTooltip('Delete').first;
    await tester.scrollUntilVisible(delete, 200);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(waterLog.all, hasLength(2));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(waterLog.all, hasLength(3));
  });

  testWidgets('reminder prompt turns on reminders', (tester) async {
    auth = FakeAuthRepository(initialUser: testUser);
    await pumpApp(tester);

    await tester.scrollUntilVisible(find.text('Turn on'), 200);
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(reminders.enabled, isTrue);
    expect(find.text('Get hourly reminders'), findsNothing);
  });

  testWidgets('history tab and settings goal editing', (tester) async {
    auth = FakeAuthRepository(initialUser: testUser);
    await pumpApp(tester);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Today'), findsWidgets);

    await tester.tap(find.byTooltip('Account').last);
    await tester.pumpAndSettle();
    expect(find.text('ada@example.com'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daily goal'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '100');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Enter 500'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '2500');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('2,500 ml'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('settings turns on Health Connect sync', (tester) async {
    auth = FakeAuthRepository(initialUser: testUser);
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Account').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Connected apps'), findsOneWidget);
    await tester.tap(find.text('Sync with Health Connect'));
    await tester.pump();
    // Let the debounced sync fire.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(health.granted, isTrue);
    expect(health.syncCalls, isNotEmpty);
    expect(health.syncCalls.last.ownerId, testUser.id);
    expect(find.textContaining('Last synced'), findsOneWidget);
    expect(find.text('Manage in Health Connect'), findsOneWidget);
  });

  testWidgets('uses a navigation rail on wide windows', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    auth = FakeAuthRepository(initialUser: testUser);
    await pumpApp(tester);

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
