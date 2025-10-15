import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/log.dart';
import '../../domain/entities/log_history.dart';
import '../../domain/repositories/log_repository.dart';

class LogRepositoryImpl implements LogRepository {
  final DatabaseReference logRef;
  final DatabaseReference historyRef;
  final FirebaseAuth auth;

  LogRepositoryImpl({
    required this.logRef,
    required this.historyRef,
    required this.auth,
  });

  Future<String?> _getUserId() async {
    final user = auth.currentUser;
    if (user == null) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }

  @override
  Future<List<Log>> fetchLogs() async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final snapshot = await logRef.child(userId).get();
    if (!snapshot.exists || snapshot.value is! Map) return [];

    final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
    final List<Log> fetchedLogs = [];

    for (final entry in data.entries) {
      final key = entry.key as String;
      final value = Map<String, dynamic>.from(entry.value as Map);
      Log log = Log.fromMap(value, key);

      // Reset if new day
      final lastResetDate = DateTime.fromMillisecondsSinceEpoch(
          (log.resetTimestamp == null || log.resetTimestamp == 0)
              ? log.timestamp
              : log.resetTimestamp ?? 0);
      final now = DateTime.now();

      if (isNewDay(lastResetDate, now)) {
        log = log.resetValues();
        await logRef.child(userId).child(log.id).set(log.toMap());
      }

      fetchedLogs.add(log);
    }
    return fetchedLogs;
  }

  @override
  Future<void> addLog({required String title, required String description, required String type}) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final String logId = logRef.child(userId).push().key!;
    final List<int> allDays = [1, 2, 3, 4, 5, 6, 7];

    final log = Log(
      id: logId,
      title: title,
      description: description,
      type: type,
      isActive: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      resetTimestamp: DateTime.now().millisecondsSinceEpoch,
      days: allDays,
    );

    await logRef.child("$userId/$logId").set(log.toMap());
  }

  @override
  Future<void> updateLog(Log updatedLog) async {
    final userId = await _getUserId();
    if (userId == null) return;

    await logRef.child('$userId/${updatedLog.id}').update({
      'title': updatedLog.title,
      'description': updatedLog.description,
      'type': updatedLog.type,
      'isActive': updatedLog.isActive,
    });
  }

  @override
  Future<void> deleteLog(String logId) async {
    final userId = await _getUserId();
    if (userId == null) return;
    await logRef.child("$userId/$logId").remove();
  }

  @override
  Future<void> updateLogToggle(String logId, bool toggle) async {
    final userId = await _getUserId();
    if (userId == null) return;
    await logRef.child('$userId/$logId').update({'toggle': toggle});
  }

  @override
  Future<void> updateLogStatus(String logId, bool isActive) async {
    final userId = await _getUserId();
    if (userId == null) return;
    await logRef.child('$userId/$logId').update({'isActive': isActive});
  }

  @override
  Future<void> updateNumberLog(String logId, int newNumber) async {
    final userId = await _getUserId();
    if (userId == null) return;
    await logRef.child('$userId/$logId').update({'number': newNumber});
  }

  @override
  Future<void> updateTextLog(String logId, String newText) async {
    final userId = await _getUserId();
    if (userId == null) return;
    await logRef.child('$userId/$logId').update({'text': newText});
  }

  @override
  Future<void> updateLogDays(String logId, List<int> days) async {
    final userId = await _getUserId();
    if (userId == null) return;
    await logRef.child('$userId/$logId').update({'days': days});
  }

  @override
  Future<void> saveLogHistory(String logId, String type, dynamic value) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final String historyId = historyRef.child("$userId/$logId").push().key!;
    final historyData = {
      'historyId': historyId,
      'type': type,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await historyRef.child("$userId/$logId/$historyId").set(historyData);
  }

  @override
  Future<List<LogHistory>> fetchLogHistory(Log log) async {
    final userId = await _getUserId();
    if (userId == null) return [];

    final creationDate = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final currentDate = DateTime.now();
    final allDates = getDatesBetween(creationDate, currentDate);

    final snapshot = await historyRef.child("$userId/${log.id}").get();
    Map<int, LogHistory> map = {};

    if (snapshot.exists && snapshot.value is Map) {
      final Map<dynamic, dynamic> data = snapshot.value as Map;
      for (var entry in data.entries) {
        final value = Map<String, dynamic>.from(entry.value as Map);
        final logHistory = LogHistory.fromMap(value, entry.key);
        final date = DateTime.fromMillisecondsSinceEpoch(logHistory.timestamp);
        final normalized = getStartOfDay(date).millisecondsSinceEpoch;
        map[normalized] = logHistory;
      }
    }

    return allDates.map((date) {
      final normalized = getStartOfDay(date).millisecondsSinceEpoch;
      return map[normalized] ?? LogHistory.empty(normalized);
    }).toList();
  }

  @override
  Future<void> updateHistoryNumberLog(Log parentLog, String historyId, int timestamp, int newNumber) async {
    await _updateHistory(parentLog, historyId, timestamp, newNumber);
  }

  @override
  Future<void> updateHistoryTextLog(Log parentLog, String historyId, int timestamp, String newText) async {
    await _updateHistory(parentLog, historyId, timestamp, newText);
  }

  @override
  Future<void> updateHistoryToggleLog(Log parentLog, String historyId, int timestamp, bool value) async {
    await _updateHistory(parentLog, historyId, timestamp, value);
  }

  Future<void> _updateHistory(Log parentLog, String historyId, int timestamp, dynamic newValue) async {
    final userId = await _getUserId();
    if (userId == null) return;

    if (historyId.isNotEmpty) {
      await historyRef.child('$userId/${parentLog.id}/$historyId').update({'value': newValue});
    } else {
      final newHistoryId = historyRef.child("$userId/${parentLog.id}").push().key!;
      final historyData = {
        'historyId': newHistoryId,
        'type': parentLog.type,
        'value': newValue,
        'timestamp': timestamp,
      };
      await historyRef.child("$userId/${parentLog.id}/$newHistoryId").set(historyData);
    }
  }

  // Helpers
  bool isNewDay(DateTime lastReset, DateTime current) =>
      lastReset.year != current.year || lastReset.month != current.month || lastReset.day != current.day;

  List<DateTime> getDatesBetween(DateTime start, DateTime end) {
    List<DateTime> dates = [];
    DateTime current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  DateTime getStartOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  @override
  Future<void> updateLogDataWithAi(String title, dynamic value) async {
    final logs = await fetchLogs();
    final logIndex = logs.indexWhere((log) => log.title.toLowerCase() == title.toLowerCase());
    if (logIndex == -1) return;

    final log = logs[logIndex];
    if (log.type == 'Text Input') {
      await updateTextLog(log.id, value.toString());
    } else if (log.type == 'Number Input') {
      final number = int.tryParse(value.toString());
      if (number != null) {
        await updateNumberLog(log.id, number);
      }
    } else if (log.type == 'Toggle Yes/No') {
      final bool toggle = value.toString().toLowerCase() != "no";
      await updateLogToggle(log.id, toggle);
    } else {
      await updateTimeLog(log.id, value.toString());
    }
  }

  @override
  Future<void> updateTimeLog(String logId, String time) async {
    final userId = await _getUserId();
    if (userId == null) return;
    await logRef.child('$userId/$logId').update({'time': time});
  }
}
