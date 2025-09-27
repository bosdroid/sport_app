import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bjj_dairy/domain/entities/log.dart';
import 'package:bjj_dairy/domain/entities/log_history.dart';
import 'package:bjj_dairy/data/repositories/log_repository_impl.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late MockDatabaseReference logRef;
  late MockDatabaseReference historyRef;
  late MockFirebaseAuth auth;
  late MockUser mockUser;
  late LogRepositoryImpl repository;

  setUp(() {
    logRef = MockDatabaseReference();
    historyRef = MockDatabaseReference();
    auth = MockFirebaseAuth();
    mockUser = MockUser();
    repository = LogRepositoryImpl(
      logRef: logRef,
      historyRef: historyRef,
      auth: auth,
    );
    SharedPreferences.setMockInitialValues({'user_name': 'testUser'});
  });

  group('LogRepositoryImpl', () {
    test('fetchLogs returns empty when no user', () async {
      when(() => auth.currentUser).thenReturn(null);

      final logs = await repository.fetchLogs();
      expect(logs, isEmpty);
    });

    test('addLog calls firebase set with correct data', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.push()).thenReturn(logRef);
      when(() => logRef.key).thenReturn('log123');
      when(() => logRef.set(any())).thenAnswer((_) async => {});

      await repository.addLog(
        title: 'title',
        description: 'desc',
        type: 'Number Input',
      );

      verify(() => logRef.set(any())).called(1);
    });

    test('updateLog updates correct fields', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.update(any())).thenAnswer((_) async => {});

      final log = Log(
        id: 'abc',
        title: 't',
        description: 'd',
        type: 'Text Input',
        timestamp: 1,
        resetTimestamp: 1,
      );

      await repository.updateLog(log);
      verify(() => logRef.update({
        'title': 't',
        'description': 'd',
        'type': 'Text Input',
        'isActive': false,
      })).called(1);
    });

    test('updateNumberLog works', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.update(any())).thenAnswer((_) async => {});
      await repository.updateNumberLog('log1', 99);
      verify(() => logRef.update({'number': 99})).called(1);
    });

    test('saveLogHistory pushes to correct path', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => historyRef.child(any())).thenReturn(historyRef);
      when(() => historyRef.push()).thenReturn(historyRef);
      when(() => historyRef.key).thenReturn('hist123');
      when(() => historyRef.set(any())).thenAnswer((_) async => {});
      await repository.saveLogHistory('log1', 'Number Input', 5);
      verify(() => historyRef.set(any())).called(1);
    });

    test('fetchLogHistory returns empty if no user', () async {
      when(() => auth.currentUser).thenReturn(null);
      final log = Log(
        id: 'abc',
        title: 'title',
        description: 'desc',
        type: 'Text Input',
        timestamp: 1,
        resetTimestamp: 1,
      );
      final history = await repository.fetchLogHistory(log);
      expect(history, isEmpty);
    });
  });
}
