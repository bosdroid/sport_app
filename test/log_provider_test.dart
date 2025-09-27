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
}
