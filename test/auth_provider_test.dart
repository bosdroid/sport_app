import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bjj_dairy/presentation/providers/auth_provider.dart'  as authProvider;
import 'package:bjj_dairy/domain/repositories/auth_repository.dart';

/// ---- Mocks ----
class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}

void main() {
  late MockAuthRepository repository;
  late authProvider.AuthProvider provider;
  late MockUser mockUser;

  setUp(() {
    repository = MockAuthRepository();
    mockUser = MockUser();

    // ✅ Stub default so constructor runs safely
    when(() => repository.loadUserFromSession())
        .thenAnswer((_) async => null);

    provider = authProvider.AuthProvider(repository);
  });

  group('AuthProvider', () {
    test('initial loadUserFromSession is called', () async {
      verify(() => repository.loadUserFromSession()).called(1);
    });

    test('_loadUserFromSession loads non-null user', () async {
      when(() => repository.loadUserFromSession())
          .thenAnswer((_) async => mockUser);

      final newProvider = authProvider.AuthProvider(repository);
      await Future.delayed(Duration.zero); // allow async constructor

      expect(newProvider.user, mockUser);
    });

    test('loginWithEmail updates user (success)', () async {
      when(() => repository.loginWithEmail('a@b.com', 'pass'))
          .thenAnswer((_) async => mockUser);

      await provider.loginWithEmail('a@b.com', 'pass');

      expect(provider.user, mockUser);
      expect(provider.isLoading, false);
      verify(() => repository.loginWithEmail('a@b.com', 'pass')).called(1);
    });

    test('loginWithEmail resets loading on error', () async {
      when(() => repository.loginWithEmail('a@b.com', 'pass'))
          .thenThrow(Exception('fail'));

      await provider.loginWithEmail('a@b.com', 'pass')
          .catchError((_) {}); // prevent test crash

      expect(provider.isLoading, false);
      expect(provider.user, isNull);
    });

    test('signUpWithEmail updates user (success)', () async {
      when(() => repository.signUpWithEmail('uname', 'a@b.com', 'pass'))
          .thenAnswer((_) async => mockUser);

      await provider.signUpWithEmail('uname', 'a@b.com', 'pass');

      expect(provider.user, mockUser);
      expect(provider.isLoading, false);
    });

    test('signUpWithEmail resets loading on error', () async {
      when(() => repository.signUpWithEmail('uname', 'a@b.com', 'pass'))
          .thenThrow(Exception('error'));

      await provider.signUpWithEmail('uname', 'a@b.com', 'pass')
          .catchError((_) {});

      expect(provider.isLoading, false);
      expect(provider.user, isNull);
    });

    test('loginWithGoogle success updates user', () async {
      when(() => repository.loginWithGoogle())
          .thenAnswer((_) async => mockUser);

      await provider.loginWithGoogle();

      expect(provider.user, mockUser);
      expect(provider.isLoading, false);
      verify(() => repository.loginWithGoogle()).called(1);
    });

    test('loginWithGoogle error resets loading', () async {
      when(() => repository.loginWithGoogle())
          .thenThrow(Exception('google fail'));

      await provider.loginWithGoogle().catchError((_) {});

      expect(provider.isLoading, false);
      expect(provider.user, isNull);
    });

    test('loginWithApple success updates user', () async {
      when(() => repository.loginWithApple())
          .thenAnswer((_) async => mockUser);

      await provider.loginWithApple();

      expect(provider.user, mockUser);
      expect(provider.isLoading, false);
      verify(() => repository.loginWithApple()).called(1);
    });

    test('loginWithApple error resets loading', () async {
      when(() => repository.loginWithApple())
          .thenThrow(Exception('apple fail'));

      await provider.loginWithApple().catchError((_) {});

      expect(provider.isLoading, false);
      expect(provider.user, isNull);
    });

    test('logout clears user and notifies', () async {
      when(() => repository.logout()).thenAnswer((_) async {});
      when(() => repository.loadUserFromSession())
          .thenAnswer((_) async => mockUser);

      provider = authProvider.AuthProvider(repository);
      await Future.delayed(Duration.zero);

      expect(provider.user, mockUser);

      await provider.logout();

      expect(provider.user, isNull);
      verify(() => repository.logout()).called(1);
    });


    test('getErrorMessage delegates to repository', () {
      when(() => repository.getErrorMessage(any()))
          .thenReturn('Custom Error');

      final msg = provider.getErrorMessage(Exception('e'));
      expect(msg, 'Custom Error');
    });

    test('getAppleLoginErrorMessage delegates to repository', () {
      when(() => repository.getAppleLoginErrorMessage(any()))
          .thenReturn('Apple Error');

      final msg = provider.getAppleLoginErrorMessage(Exception('apple'));
      expect(msg, 'Apple Error');
    });

    test('validateUsernameInput delegates to repository', () {
      when(() => repository.validateUsernameInput('abc'))
          .thenReturn('Too short');

      final result = provider.validateUsernameInput('abc');
      expect(result, 'Too short');
    });
  });
}
