import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safishoe_app/features/auth/data/model/user_model.dart';
import 'package:safishoe_app/features/auth/data/repository/auth_repository.dart';
import 'package:safishoe_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:safishoe_app/features/auth/presentation/providers/auth_state.dart';
import 'package:safishoe_app/features/auth/presentation/providers/workspace_selection_provider.dart';
import 'package:safishoe_app/features/branch/shared/current_branch_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthRepo extends Mock implements AuthRepository {}

const cashier = UserModel(
    id: 'u1',
    username: 'cash',
    email: 'c@x.com',
    role: 'cashier',
    branchIds: ['b1', 'b2']);

void main() {
  late MockAuthRepo repo;

  ProviderContainer make() {
    final c = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = MockAuthRepo();
    when(() => repo.getCurrentUser()).thenAnswer((_) async => null);
    when(() => repo.logout()).thenAnswer((_) async {});
  });

  group('login', () {
    test('success -> authenticated', () async {
      when(() => repo.login(email: 'c@x.com', password: 'pw'))
          .thenAnswer((_) async => cashier);
      final c = make();
      await c.read(authProvider.notifier).login('c@x.com', 'pw');
      expect(c.read(authProvider).isAuthenticated, isTrue);
      expect(c.read(authProvider).user!.role, 'cashier');
    });

    test('wrong password -> error, not authenticated', () async {
      when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('Invalid login credentials'));
      final c = make();
      await c.read(authProvider.notifier).login('c@x.com', 'bad');
      final s = c.read(authProvider);
      expect(s.status, AuthStatus.error);
      expect(s.errorMessage, 'Invalid login credentials');
      expect(s.isAuthenticated, isFalse);
    });

    test('empty email/password handled as error (no crash)', () async {
      when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('Email required'));
      final c = make();
      await c.read(authProvider.notifier).login('', '');
      expect(c.read(authProvider).isAuthenticated, isFalse);
    });

    test('[BUG-L1] network error message must stay readable (Exception: stripping)', () async {
      when(() => repo.login(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(Exception('SocketException: Failed host lookup'));
      final c = make();
      await c.read(authProvider.notifier).login('a@b.c', 'x');
      expect(c.read(authProvider).user, isNull);
      expect(c.read(authProvider).errorMessage, contains('Failed host lookup'));
      // replaceAll('Exception: ','') also eats the tail of 'SocketException: '
      expect(c.read(authProvider).errorMessage, contains('SocketException'));
    });
  });

  group('logout / session', () {
    test('logout clears user and selected branch', () async {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => cashier);
      final c = make();
      c.listen(authProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(authProvider).isAuthenticated, isTrue);
      await c.read(selectedBranchIdProvider.notifier).select('b2');
      expect(c.read(currentBranchIdProvider), 'b2');

      await c.read(authProvider.notifier).logout();

      expect(c.read(authProvider).user, isNull);
      expect(c.read(authProvider).isAuthenticated, isFalse);
      expect(c.read(selectedBranchIdProvider), '');
      expect(c.read(currentBranchIdProvider), '');
      verify(() => repo.logout()).called(1);
    });

    test('saved session restored on start', () async {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => cashier);
      final c = make();
      c.listen(authProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(authProvider).user?.id, 'u1');
    });
  });

  group('currentBranchIdProvider', () {
    test('selected branch not owned by user is ignored', () async {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => cashier);
      final c = make();
      c.listen(authProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await c.read(selectedBranchIdProvider.notifier).select('someone-elses');
      expect(c.read(currentBranchIdProvider), 'b1');
    });

    test('user with no branch -> empty id', () async {
      when(() => repo.getCurrentUser()).thenAnswer((_) async => const UserModel(
          id: 'u', username: 'x', email: 'x@x', role: 'cashier'));
      final c = make();
      c.listen(authProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(currentBranchIdProvider), '');
    });
  });

  group('UserModel.fromJson', () {
    test('parses nested branch ids and missing fields', () {
      final u = UserModel.fromJson({
        'id': 'u1',
        'username': 'a',
        'email': 'a@a',
        'role': 'manager',
        'user_branches': [
          {'branch_id': 'b1'},
          {'branch_id': ''},
        ],
      });
      expect(u.id, 'u1');
      expect(u.role, 'manager');
    });
  });
}
