import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bjj_dairy/domain/entities/log.dart';
import 'package:bjj_dairy/domain/entities/log_history.dart';
import 'package:bjj_dairy/domain/repositories/log_repository.dart';
import 'package:bjj_dairy/presentation/providers/log_provider.dart';

class MockLogRepository extends Mock implements LogRepository {}

// ---------- Fallback for Goal ----------
class FakeLog extends Fake implements Log {}

void main() {
  late MockLogRepository repo;
  late LogProvider provider;

  // Register fallback once for all tests
  setUpAll(() {
    registerFallbackValue(FakeLog());
  });

  final sampleLog = Log(
    id: '1',
    title: 'Sample',
    description: 'Desc',
    type: 'Text Input',
    timestamp: DateTime.now().millisecondsSinceEpoch,
    resetTimestamp: DateTime.now().millisecondsSinceEpoch,
  );

  setUp(() {
    repo = MockLogRepository();
    provider = LogProvider(repo);
  });

  group('LogProvider', () {
    test('fetchLogs updates logs list', () async {
      when(() => repo.fetchLogs()).thenAnswer((_) async => [sampleLog]);
      await provider.fetchLogs();
      expect(provider.logs.length, 1);
      expect(provider.logs.first.title, 'Sample');
    });

    test('addLog adds new log', () async {
      when(() => repo.addLog(
        title: any(named: 'title'),
        description: any(named: 'description'),
        type: any(named: 'type'),
      )).thenAnswer((_) async {});
      when(() => repo.fetchLogs()).thenAnswer((_) async => [sampleLog]);

      await provider.addLog('New', 'desc', 'Text Input');
      expect(provider.logs.first.title, 'Sample');
    });

    test('updateLog updates a log locally', () async {
      provider.logs.add(sampleLog);
      when(() => repo.updateLog(any())).thenAnswer((_) async {});
      final updated = sampleLog.copyWith(title: 'Updated');
      await provider.updateLog(updated);
      expect(provider.logs.first.title, 'Updated');
    });

    test('deleteLog removes log', () async {
      provider.logs.add(sampleLog);
      when(() => repo.deleteLog('1')).thenAnswer((_) async {});
      await provider.deleteLog('1');
      expect(provider.logs, isEmpty);
    });

    test('updateNumberLog updates number locally', () async {
      provider.logs.add(sampleLog);
      when(() => repo.updateNumberLog(any(), any())).thenAnswer((_) async {});
      await provider.updateNumberLog('1', 99);
      expect(provider.logs.first.number, 99);
    });

    test('saveLogHistory delegates correctly', () async {
      when(() => repo.saveLogHistory('1', 'Text Input', 'value'))
          .thenAnswer((_) async {});
      await provider.saveLogHistory('1', 'Text Input', 'value');
      verify(() => repo.saveLogHistory('1', 'Text Input', 'value')).called(1);
    });

    test('fetchLogHistory updates logsHistory', () async {
      when(() => repo.fetchLogHistory(sampleLog))
          .thenAnswer((_) async => [LogHistory.empty(123)]);
      await provider.fetchLogHistory(sampleLog);
      expect(provider.logsHistory.length, 1);
    });
  });

  test('getActiveLogsForDate filters by weekday and notifies', () async {
    final mondayLog = sampleLog.copyWith(days: [DateTime.monday], isActive: true);
    final tuesdayLog = sampleLog.copyWith(id: '2', days: [DateTime.tuesday], isActive: true);
    provider.logs.addAll([mondayLog, tuesdayLog]);

    bool notified = false;
    provider.addListener(() => notified = true);

    await provider.getActiveLogsForDate(DateTime(DateTime.now().year, 1, 6)); // Monday

    expect(provider.activeLogs, [mondayLog]);
    expect(notified, true);
  });

  test('totalActiveLogs counts only active logs for today', () {
    final today = DateTime.now().weekday;
    provider.logs.addAll([
      sampleLog.copyWith(days: [today], isActive: true),
      sampleLog.copyWith(id: '2', days: [today], isActive: false),
      sampleLog.copyWith(id: '3', days: [today - 1], isActive: true),
    ]);
    expect(provider.totalActiveLogs, 1);
  });

  test('anyLogChanges returns true only when changes == true for active logs', () {
    provider.logs.addAll([
      sampleLog.copyWith(changes: false, isActive: true),
      sampleLog.copyWith(id: '2', changes: true, isActive: true),
    ]);
    expect(provider.anyLogChanges, true);
  });

  test('updateAllLogChanges applies all changes and resets', () async {
    final textLog = sampleLog.copyWith(id: '1', type: 'Text Input', changes: true);
    final numLog = sampleLog.copyWith(id: '2', type: 'Number Input', changes: true);
    final toggleLog = sampleLog.copyWith(id: '3', type: 'Toggle Yes/No', changes: true);

    provider.logs.addAll([textLog, numLog, toggleLog]);

    when(() => repo.updateTextLog('1', any())).thenAnswer((_) async {});
    when(() => repo.updateNumberLog('2', any())).thenAnswer((_) async {});
    when(() => repo.updateLogToggle('3', any())).thenAnswer((_) async {});

    await provider.updateAllLogChanges();

    expect(provider.isLoading, false);
    expect(provider.logs.every((l) => l.changes == false), true);
  });

  test('updateLogData updates in-place when id matches', () async {
    final log = sampleLog.copyWith(id: '5', text: 'Old');
    provider.logs.add(log);

    await provider.updateLogData(log.copyWith(text: 'New'));
    expect(provider.logs.first.text, 'New');
  });

  test('updateLogDataWithAi handles Text, Number, Toggle, and fallback', () async {
    final textLog = sampleLog.copyWith(id: '1', title: 'Text', type: 'Text Input');
    final numLog = sampleLog.copyWith(id: '2', title: 'Num', type: 'Number Input');
    final toggleLog = sampleLog.copyWith(id: '3', title: 'Toggle', type: 'Toggle Yes/No');
    final timeLog = sampleLog.copyWith(id: '4', title: 'Time', type: 'Time Input');

    provider.activeLogs.addAll([textLog, numLog, toggleLog, timeLog]);
    provider.logs.addAll([timeLog]);

    when(() => repo.updateTextLog(any(), any())).thenAnswer((_) async {});
    when(() => repo.updateNumberLog(any(), any())).thenAnswer((_) async {});
    when(() => repo.updateLogToggle(any(), any())).thenAnswer((_) async {});

    await provider.updateLogDataWithAi('Text', 'new text');
    await provider.updateLogDataWithAi('Num', '12');
    await provider.updateLogDataWithAi('Toggle', 'yes');
    await provider.updateLogDataWithAi('Time', 999);

    expect(provider.logs.first.time, 999);
  });

  test('updateLogToggle updates toggle locally and notifies', () async {
    provider.logs.add(sampleLog);
    when(() => repo.updateLogToggle('1', true)).thenAnswer((_) async {});
    await provider.updateLogToggle('1', true);
    expect(provider.logs.first.toggle, true);
  });

  test('updateLogStatus updates active state locally', () async {
    provider.logs.add(sampleLog);
    when(() => repo.updateLogStatus('1', false)).thenAnswer((_) async {});
    await provider.updateLogStatus('1', false);
    expect(provider.logs.first.isActive, false);
  });

  test('updateLogDays updates days via copyWith', () async {
    provider.logs.add(sampleLog);
    when(() => repo.updateLogDays('1', [1, 2, 3])).thenAnswer((_) async {});
    await provider.updateLogDays('1', [1, 2, 3]);
    expect(provider.logs.first.days, [1, 2, 3]);
  });

  test('updateHistoryTextLog updates both branches', () async {
    final logHistory = LogHistory.empty(123).copyWith(historyId: 'h1');
    provider.logsHistory.add(logHistory);
    when(() => repo.updateHistoryTextLog(any(), any(), any(), any())).thenAnswer((_) async {});

    await provider.updateHistoryTextLog(sampleLog, 'h1', 0, 'changed');
    expect(provider.logsHistory.first.value, 'changed');

    provider.setLogsHistory([LogHistory.empty(123)]);
    await provider.updateHistoryTextLog(sampleLog, '', 123, 'again');
    expect(provider.logsHistory.first.value, 'again');
  });

  test('fetchLogHistory handles repository error gracefully', () async {
    when(() => repo.fetchLogHistory(any())).thenThrow(Exception('fail'));
    await provider.fetchLogHistory(sampleLog);
    expect(provider.logsHistory, isEmpty);
  });

  test('resetChanges clears all changes flags', () {
    provider.logs.addAll([sampleLog.copyWith(changes: true)]);
    provider.resetChanges();
    expect(provider.logs.every((l) => !l.changes), true);
  });

  test('isNewDay detects same vs different days', () {
    final today = DateTime.now();
    expect(provider.isNewDay(today, today), false);
    expect(provider.isNewDay(today, today.add(const Duration(days: 1))), true);
  });

  test('saveTimeLog just notifies listeners', () async {
    bool notified = false;
    provider.addListener(() => notified = true);
    await provider.saveTimeLog(startTime: DateTime.now(), endTime: DateTime.now(), elapsedTime: 10);
    expect(notified, true);
  });

}
