import 'package:bjj_dairy/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// ---- Mocks ----
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockDatabaseReference extends Mock implements DatabaseReference {}

class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockDatabaseReference mockDb;
  late MockDatabaseReference mockUsernames;
  late MockDatabaseReference mockUsersDetails;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockDb = MockDatabaseReference();
    mockUsernames = MockDatabaseReference();
    mockUsersDetails = MockDatabaseReference();

    // Stub child() lookups
    when(() => mockDb.child('USERNAMES/')).thenReturn(mockUsernames);
    when(() => mockDb.child('USERS_DETAILS/')).thenReturn(mockUsersDetails);

    // Provide our fake database
    repository = AuthRepositoryImpl(mockAuth, _FakeDatabase(mockDb));
  });

  test('validateUsernameInput catches empty', () async {
    expect(await repository.validateUsernameInput(''),
        'Username cannot be empty');
  });

  test('validateUsernameInput catches short name', () async {
    expect(await repository.validateUsernameInput('abc'),
        'Username must be at least 6 characters long');
  });

  test('validateUsernameInput catches invalid chars', () async {
    // Make sure it’s >= 6 chars so we hit the invalid-character rule
    expect(await repository.validateUsernameInput('abcdef@'),
        'Username can only contain letters, numbers, and underscores');
  });

  test('validateUsernameInput returns null for valid', () async {
    expect(await repository.validateUsernameInput('valid_123'), isNull);
  });

  test('getErrorMessage maps FirebaseAuthException codes', () {
    final e = FirebaseAuthException(code: 'wrong-password', message: 'oops');
    expect(repository.getErrorMessage(e), 'Incorrect password.');
  });

  test('getErrorMessage returns generic for unknown', () {
    final e = FirebaseAuthException(code: 'random', message: '??');
    expect(repository.getErrorMessage(e), contains('Unexpected error'));
  });
}

/// ---- Simple fake for FirebaseDatabase that always returns our mockDb ----
class _FakeDatabase implements FirebaseDatabase {
  final MockDatabaseReference refMock;
  _FakeDatabase(this.refMock);

  @override
  DatabaseReference ref([String? path]) => refMock;

  // Unused members can throw or return dummy data
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
