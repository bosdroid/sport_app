import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bjj_dairy/data/repositories/profile_repository_impl.dart';
import 'package:bjj_dairy/domain/entities/user.dart';

// ----- Mocks -----
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DataSnapshot {}
class MockFirebaseAuth extends Mock implements auth.FirebaseAuth {}
class MockFirebaseUser extends Mock implements auth.User {}

void main() {
  late MockDatabaseReference mockRef;
  late MockFirebaseAuth mockAuth;
  late ProfileRepositoryImpl repository;

  setUp(() {
    mockRef = MockDatabaseReference();
    mockAuth = MockFirebaseAuth();
    repository = ProfileRepositoryImpl(
      usersDetailsRef: mockRef,
      firebaseAuth: mockAuth,
    );
  });

  group('getUserDetails', () {
    test('returns User from database if snapshot exists', () async {
      SharedPreferences.setMockInitialValues({'user_name': 'john'});
      final mockSnapshot = MockDatabaseEvent();
      final childRef = MockDatabaseReference();

      when(() => mockRef.child('john')).thenReturn(childRef);
      when(() => childRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn({
        'id': '1',
        'username': 'john',
        'email': 'john@example.com',
        'type': 'email'
      });

      final user = await repository.getUserDetails();

      expect(user, isNotNull);
      expect(user!.username, 'john');
      verify(() => mockRef.child('john')).called(1);
    });

    test('returns fallback User if snapshot does not exist', () async {
      SharedPreferences.setMockInitialValues({'user_name': 'john'});
      final mockSnapshot = MockDatabaseEvent();
      final childRef = MockDatabaseReference();
      final mockUser = MockFirebaseUser();

      when(() => mockRef.child('john')).thenReturn(childRef);
      when(() => childRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('uid123');
      when(() => mockUser.email).thenReturn('email@test.com');

      final user = await repository.getUserDetails();

      expect(user, isNotNull);
      expect(user!.id, 'uid123');
      expect(user.email, 'email@test.com');
    });

    test('returns null if user_name not in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final user = await repository.getUserDetails();
      expect(user, isNull);
    });
  });

  group('updateUserProfile', () {
    test('updates user data in database', () async {
      final testUser = User(
        id: '1',
        username: 'john',
        email: 'john@example.com',
        type: 'email',
      );

      final childRef = MockDatabaseReference();
      when(() => mockRef.child(testUser.username)).thenReturn(childRef);
      when(() => childRef.update(any())).thenAnswer((_) async => {});

      await repository.updateUserProfile(testUser);

      verify(() => childRef.update(testUser.toMap())).called(1);
    });
  });
}
