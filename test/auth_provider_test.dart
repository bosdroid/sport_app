import 'package:bjj_dairy/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bjj_dairy/presentation/providers/auth_provider.dart' as authProvider;


// ---- Mocks ----
class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository repository;
  late authProvider.AuthProvider provider;
  late MockUser mockUser;

  setUp(() {
    repository = MockAuthRepository();
    mockUser = MockUser();

    // ✅ Always stub this so constructor won't crash
    when(() => repository.loadUserFromSession())
        .thenAnswer((_) async => null);

    provider = authProvider.AuthProvider(repository);
  });

  test('initial loadUserFromSession is called', () async {
    // Create a new instance to trigger constructor call
    verify(() => repository.loadUserFromSession()).called(1);
  });

  test('loginWithEmail updates user', () async {
    when(() => repository.loginWithEmail('a@b.com', 'pass'))
        .thenAnswer((_) async => mockUser);

    await provider.loginWithEmail('a@b.com', 'pass');

    expect(provider.user, mockUser);
    expect(provider.isLoading, false);
    verify(() => repository.loginWithEmail('a@b.com', 'pass')).called(1);
  });

  test('signUpWithEmail updates user', () async {
    when(() => repository.signUpWithEmail('uname', 'a@b.com', 'pass'))
        .thenAnswer((_) async => mockUser);

    await provider.signUpWithEmail('uname', 'a@b.com', 'pass');

    expect(provider.user, mockUser);
    verify(() => repository.signUpWithEmail('uname', 'a@b.com', 'pass')).called(1);
  });

  test('logout clears user', () async {
    when(() => repository.logout()).thenAnswer((_) async {});

    await provider.logout();

    expect(provider.user, isNull);
    verify(() => repository.logout()).called(1);
  });

  test('validateUsernameInput delegates to repository', () {
    when(() => repository.validateUsernameInput('abc'))
        .thenReturn('Too short');

    final result = provider.validateUsernameInput('abc');
    expect(result, 'Too short');
  });

  test('getErrorMessage delegates to repository', () {
    when(() => repository.getErrorMessage(any()))
        .thenReturn('Custom Error');

    expect(provider.getErrorMessage(Exception()), 'Custom Error');
  });
}
