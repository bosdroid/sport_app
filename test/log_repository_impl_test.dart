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

    test('_getUserId returns null when SharedPreferences has no user_name', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      SharedPreferences.setMockInitialValues({}); // no user_name
      final result = await repository.fetchLogs(); // indirectly triggers _getUserId()
      expect(result, isEmpty);
    });

    test('fetchLogs returns parsed logs and resets new day', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      final now = DateTime.now();
      final oldTimestamp = now.subtract(const Duration(days: 1)).millisecondsSinceEpoch;

      final snapshot = MockDataSnapshot();
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn({
        'log1': {
          'id': 'log1',
          'title': 'Run',
          'description': 'Morning run',
          'type': 'Number Input',
          'timestamp': oldTimestamp,
          'resetTimestamp': oldTimestamp,
        }
      });
      when(() => logRef.get()).thenAnswer((_) async => snapshot);
      when(() => logRef.set(any())).thenAnswer((_) async {});

      final logs = await repository.fetchLogs();
      expect(logs.length, 1);
      verify(() => logRef.set(any())).called(1); // reset happened
    });

    test('fetchLogs returns empty when snapshot.value is not a Map', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      final snapshot = MockDataSnapshot();
      when(() => snapshot.exists).thenReturn(true);
      when(() => snapshot.value).thenReturn('invalid');
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.get()).thenAnswer((_) async => snapshot);
      final logs = await repository.fetchLogs();
      expect(logs, isEmpty);
    });

    test('deleteLog removes log at correct path', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.remove()).thenAnswer((_) async {});
      await repository.deleteLog('abc');
      verify(() => logRef.remove()).called(1);
    });

    test('updateLogToggle updates toggle field', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.update(any())).thenAnswer((_) async {});
      await repository.updateLogToggle('log1', true);
      verify(() => logRef.update({'toggle': true})).called(1);
    });

    test('updateLogStatus updates isActive field', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.update(any())).thenAnswer((_) async {});
      await repository.updateLogStatus('log1', false);
      verify(() => logRef.update({'isActive': false})).called(1);
    });

    test('updateTextLog updates text', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.update(any())).thenAnswer((_) async {});
      await repository.updateTextLog('log1', 'new text');
      verify(() => logRef.update({'text': 'new text'})).called(1);
    });

    test('updateLogDays updates days', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.update(any())).thenAnswer((_) async {});
      await repository.updateLogDays('log1', [1,2,3]);
      verify(() => logRef.update({'days': [1,2,3]})).called(1);
    });

    test('updateTimeLog updates time', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);
      when(() => logRef.update(any())).thenAnswer((_) async {});
      await repository.updateTimeLog('log1', '10:00');
      verify(() => logRef.update({'time': '10:00'})).called(1);
    });


    test('_updateHistory updates existing history when id not empty', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => historyRef.child(any())).thenReturn(historyRef);
      when(() => historyRef.update(any())).thenAnswer((_) async {});
      final log = Log(id: 'log1', title: 't', description: 'd', type: 'Number Input', timestamp: 1, resetTimestamp: 1);
      await repository.updateHistoryNumberLog(log, 'h123', 123, 99);
      verify(() => historyRef.update({'value': 99})).called(1);
    });

    test('_updateHistory creates new history when id empty', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => historyRef.child(any())).thenReturn(historyRef);
      when(() => historyRef.push()).thenReturn(historyRef);
      when(() => historyRef.key).thenReturn('newHist');
      when(() => historyRef.set(any())).thenAnswer((_) async {});
      final log = Log(id: 'log1', title: 't', description: 'd', type: 'Text Input', timestamp: 1, resetTimestamp: 1);
      await repository.updateHistoryTextLog(log, '', 999, 'changed');
      verify(() => historyRef.set(any())).called(1);
    });

    test('fetchLogHistory normalizes and fills missing days', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => historyRef.child(any())).thenReturn(historyRef);
      final snapshot = MockDataSnapshot();
      when(() => snapshot.exists).thenReturn(true);
      final now = DateTime.now().millisecondsSinceEpoch;
      when(() => snapshot.value).thenReturn({
        'h1': {
          'historyId': 'h1',
          'type': 'Number Input',
          'value': 10,
          'timestamp': now,
        },
      });
      when(() => historyRef.get()).thenAnswer((_) async => snapshot);
      final log = Log(id: 'log1', title: 'run', description: '', type: 'Number Input', timestamp: now - 86400000, resetTimestamp: now - 86400000);
      final history = await repository.fetchLogHistory(log);
      expect(history.length, greaterThan(1)); // filled missing days
      expect(history.any((h) => h.historyId == 'h1'), true);
    });

    test('updateLogDataWithAi delegates by type', () async {
      when(() => auth.currentUser).thenReturn(mockUser);
      when(() => logRef.child(any())).thenReturn(logRef);

      // 🔹 Mock the snapshot
      when(() => logRef.get()).thenAnswer((_) async {
        final snapshot = MockDataSnapshot();
        when(() => snapshot.exists).thenReturn(true);
        when(() => snapshot.value).thenReturn({
          'l1': {
            'id': 'l1',
            'title': 'TextLog',
            'description': 'mock description',
            'type': 'Text Input',
            'timestamp': 1,
            'resetTimestamp': 1,
          },
          'l2': {
            'id': 'l2',
            'title': 'NumLog',
            'description': 'mock description',
            'type': 'Number Input',
            'timestamp': 1,
            'resetTimestamp': 1,
          },
          'l3': {
            'id': 'l3',
            'title': 'ToggleLog',
            'description': 'mock description',
            'type': 'Toggle Yes/No',
            'timestamp': 1,
            'resetTimestamp': 1,
          },
          'l4': {
            'id': 'l4',
            'title': 'TimeLog',
            'description': 'mock description',
            'type': 'Time',
            'timestamp': 1,
            'resetTimestamp': 1,
          },
        });
        return snapshot;
      });

      // 🔹 Add missing async mocks
      when(() => logRef.update(any())).thenAnswer((_) async {});
      when(() => logRef.set(any())).thenAnswer((_) async {}); // 👈 This fixes your error

      // 🔹 Run test
      await repository.updateLogDataWithAi('TextLog', 'new text');
      await repository.updateLogDataWithAi('NumLog', 42);
      await repository.updateLogDataWithAi('ToggleLog', 'no');
      await repository.updateLogDataWithAi('TimeLog', '12:00');

      verify(() => logRef.update(any())).called(greaterThan(3));
    });


    test('_isNewDay returns true only for date change', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      expect(repository.isNewDay(yesterday, now), isTrue);
      expect(repository.isNewDay(now, now), isFalse);
    });

    test('_getDatesBetween includes start and end', () {
      final start = DateTime(2023, 1, 1);
      final end = DateTime(2023, 1, 3);
      final result = repository.getDatesBetween(start, end);
      expect(result.length, 3);
    });

    test('_getStartOfDay normalizes time', () {
      final date = DateTime(2023, 1, 1, 12, 30);
      final start = repository.getStartOfDay(date);
      expect(start.hour, 0);
      expect(start.minute, 0);
    });


  });
}
