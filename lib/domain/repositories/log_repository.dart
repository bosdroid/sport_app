import '../entities/log.dart';
import '../entities/log_history.dart';

/// Contract for managing Logs and their history.
abstract class LogRepository {
  Future<List<Log>> fetchLogs();
  Future<void> addLog({required String title, required String description, required String type});
  Future<void> updateLog(Log updatedLog);
  Future<void> deleteLog(String logId);

  Future<void> updateLogToggle(String logId, bool toggle);
  Future<void> updateLogStatus(String logId, bool isActive);
  Future<void> updateNumberLog(String logId, int newNumber);
  Future<void> updateTextLog(String logId, String newText);
  Future<void> updateLogDays(String logId, List<int> days);
  Future<void> updateTimeLog(String logId, String time);

  Future<void> saveLogHistory(String logId, String type, dynamic value);
  Future<List<LogHistory>> fetchLogHistory(Log log);
  Future<void> updateHistoryNumberLog(Log parentLog, String historyId, int timestamp, int newNumber);
  Future<void> updateHistoryTextLog(Log parentLog, String historyId, int timestamp, String newText);
  Future<void> updateHistoryToggleLog(Log parentLog, String historyId, int timestamp, bool value);
  Future<void> updateLogDataWithAi(String title, dynamic value);
}
