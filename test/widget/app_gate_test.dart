import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safishoe_app/features/auth/data/model/user_model.dart';
import 'package:safishoe_app/features/auth/data/repository/auth_repository.dart';
import 'package:safishoe_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safishoe_app/features/auth/presentation/screens/app_gate.dart';
import 'package:safishoe_app/features/auth/presentation/screens/login_screen.dart';
import 'package:safishoe_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

const cashier = UserModel(
  id: 'u1',
  username: 'cash',
  email: 'c@x.com',
  role: 'cashier',
  branchIds: ['b1'],
);

Widget app(MockAuthRepo repo) => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    home: AppGate(
      minSplash: const Duration(milliseconds: 1000),
      destinationBuilder: (_) => const Text('DASHBOARD'),
    ),
  ),
);

void main() {
  late MockAuthRepo repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockAuthRepo();
    when(() => repo.refreshUser()).thenAnswer((_) async => null);
  });

  Future<void> step(WidgetTester t, int ms, {void Function()? check}) async {
    // 100ms ke tukron mein, har tukre par check (login kabhi na chamke).
    for (var i = 0; i < ms ~/ 100; i++) {
      await t.pump(const Duration(milliseconds: 100));
      check?.call();
    }
  }

  testWidgets('splash first, then login screen when nobody is logged in', (
    t,
  ) async {
    when(() => repo.getCurrentUser()).thenAnswer((_) async => null);
    await t.pumpWidget(app(repo));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    await step(t, 1500); // min splash + fade
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets(
    'logged-in user goes straight to the dashboard, login never shows',
    (t) async {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => cashier);
      await t.pumpWidget(app(repo));

      expect(find.byType(SplashScreen), findsOneWidget);
      await step(
        t,
        2000,
        check: () => expect(find.byType(LoginScreen), findsNothing),
      );

      expect(find.text('DASHBOARD'), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
    },
  );

  testWidgets('slow session restore keeps the splash (no login flash)', (
    t,
  ) async {
    final gate = Completer<UserModel?>();
    when(() => repo.getCurrentUser()).thenAnswer((_) => gate.future);
    await t.pumpWidget(app(repo));

    // min splash guzar gaya, lekin restore abhi baqi hai.
    await step(
      t,
      2500,
      check: () {
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(LoginScreen), findsNothing);
      },
    );

    gate.complete(cashier);
    await step(
      t,
      900,
      check: () => expect(find.byType(LoginScreen), findsNothing),
    );
    expect(find.text('DASHBOARD'), findsOneWidget);
  });

  testWidgets('restore error falls back to login (not a stuck splash)', (
    t,
  ) async {
    when(() => repo.getCurrentUser()).thenThrow(Exception('storage broken'));
    await t.pumpWidget(app(repo));
    await step(t, 1600);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
