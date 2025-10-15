import 'package:flutter/material.dart';

import '../../domain/entities/log.dart';
import '../../domain/entities/log_history.dart';
import '../../domain/repositories/log_repository.dart';
import '../view/time_tracker_screen.dart';


class LogProvider with ChangeNotifier {
  final LogRepository repository;

  LogProvider(this.repository);

  List<Log> _logs = [];
  List<Log> _activeLogs = [];
  List<LogHistory> _logsHistory = [];
  bool _isLoading = false;

  List<Log> get logs => _logs;
  List<Log> get activeLogs => _activeLogs;
  List<LogHistory> get logsHistory => _logsHistory;
  bool get isLoading => _isLoading;

  @visibleForTesting
  void setLogsHistory(List<LogHistory> history) {
    _logsHistory = history;
  }


  Future<void> getActiveLogsForDate(DateTime? date) async {
    final weekday = date?.weekday ?? DateTime.now().weekday;
    _activeLogs = _logs.where((log) => log.isActive && log.days.contains(weekday)).toList();
    notifyListeners();
  }

  /// Total number of active logs for today.
  int get totalActiveLogs =>
      _logs.where((log) => log.isActive && log.days.contains(DateTime.now().weekday)).length;

  /// Returns true if there are any active logs with unsaved changes.
  bool get anyLogChanges => _logs.any((log) => log.isActive && log.changes);

  Future<void> updateAllLogChanges() async {
    _isLoading = true;
    notifyListeners();

    final changesLogItems = _logs.where((log) => log.isActive && log.changes).toList();

    for (var log in changesLogItems) {
      if (log.type == 'Text Input') {
        await updateTextLog(log.id, log.text ?? "");
      } else if (log.type == 'Number Input') {
        await updateNumberLog(log.id, log.number);
      } else if (log.type == 'Toggle Yes/No') {
        await updateLogToggle(log.id, log.toggle);
      } else {
        // In future: handle time logs if needed
      }
    }

    resetChanges();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateLogData(Log data) async {
    final index = _logs.indexWhere((log) => log.id == data.id);
    if (index == -1) return;

    // Update local state
    _logs[index] = _logs[index].copyWith(
      text: data.text,
      number: data.number,
      toggle: data.toggle,
      time: data.time,
      changes: data.changes,
    );

    notifyListeners();
  }

  Future<void> updateLogDataWithAi(String title, dynamic value) async {
    final index = _activeLogs.indexWhere((log) => log.title.toLowerCase() == title.toLowerCase());
    if (index == -1) return;

    final log = _activeLogs[index];
    if (log.type == 'Text Input') {
      await updateTextLog(log.id, value.toString());
    } else if (log.type == 'Number Input') {
      final numValue = int.tryParse(value.toString()) ?? 0;
      await updateNumberLog(log.id, numValue);
    } else if (log.type == 'Toggle Yes/No') {
      final bool toggleValue = value.toString().toLowerCase() != "no";
      await updateLogToggle(log.id, toggleValue);
    } else {
      // time or other custom type
      final i = _logs.indexWhere((l) => l.id == log.id);
      if (i != -1) {
        _logs[i].time = value;
        notifyListeners();
      }
    }
  }

// 🔹 Reset all local change flags
  void resetChanges() {
    for (var log in _logs) {
      log.changes = false;
    }
    notifyListeners();
  }

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();
    _logs = await repository.fetchLogs();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addLog(String title, String description, String type) async {
    _isLoading = true;
    notifyListeners();
    await repository.addLog(title: title, description: description, type: type);
    _logs = await repository.fetchLogs();
    _isLoading = false;
    notifyListeners();
  }

  // 🔵 update Log to Firebase
  Future<void> updateLog(Log updatedLog) async {
    _isLoading = true;
    notifyListeners();

    try {
      await repository.updateLog(updatedLog);

      // update in-memory state
      final index = _logs.indexWhere((log) => log.id == updatedLog.id);
      if (index != -1) {
        _logs[index] = updatedLog;
      }
    } catch (e) {
      debugPrint('Error updating log: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> updateLogToggle(String logId, bool toggle) async {
    await repository.updateLogToggle(logId, toggle);

    final index = _logs.indexWhere((log) => log.id == logId);
    if (index != -1) {
      _logs[index].toggle = toggle;
      notifyListeners();
    }
  }

  Future<void> updateLogStatus(String logId, bool isActive) async {
    await repository.updateLogStatus(logId, isActive);

    final index = _logs.indexWhere((log) => log.id == logId);
    if (index != -1) {
      _logs[index].isActive = isActive;
      notifyListeners();
    }
  }

  Future<void> deleteLog(String logId) async {
    _isLoading = true;
    notifyListeners();

    await repository.deleteLog(logId);
    _logs.removeWhere((log) => log.id == logId);

    _isLoading = false;
    notifyListeners();
  }


  // 🔹 Save history (delegate to repository)
  Future<void> saveLogHistory(String logId, String type, dynamic value) async {
    await repository.saveLogHistory(logId, type, value);
  }

  // 🔹 Fetch history (with loading state)
  Future<void> fetchLogHistory(Log log) async {
    _isLoading = true;
    notifyListeners();

    try {
      _logsHistory = await repository.fetchLogHistory(log);
    } catch (_) {
      _logsHistory = []; // fallback
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🔹 Update Log Days
  Future<void> updateLogDays(String logId, List<int> days) async {
    await repository.updateLogDays(logId, days);

    final index = _logs.indexWhere((log) => log.id == logId);
    if (index != -1) {
      _logs[index] = _logs[index].copyWith(days: days);
      notifyListeners();
    }
  }

// 🔹 Update Log Number
  Future<void> updateNumberLog(String logId, int newNumber) async {
    await repository.updateNumberLog(logId, newNumber);

    final index = _logs.indexWhere((log) => log.id == logId);
    if (index != -1) {
      _logs[index].number = newNumber;
      notifyListeners();
    }
  }

  // 🔹 Update History Log Number
  Future<void> updateHistoryNumberLog(Log parentLog, String historyId, int timestamp, int newNumber) async {
    await repository.updateHistoryNumberLog(parentLog, historyId, timestamp, newNumber);

    // Update local state optimistically
    if (historyId.isNotEmpty) {
      final index = _logsHistory.indexWhere((log) => log.historyId == historyId);
      if (index != -1) {
        _logsHistory[index].value = newNumber;
        notifyListeners();
      }
    } else {
      final index = _logsHistory.indexWhere((log) => log.timestamp == timestamp);
      if (index != -1) {
        _logsHistory[index] = _logsHistory[index].copyWith(value: newNumber);
        notifyListeners();
      }
    }
  }

  // Update Log Text
  Future<void> updateTextLog(String logId, String newText) async {
    await repository.updateTextLog(logId, newText);
    final logIndex = _logs.indexWhere((log) => log.id == logId);
    if (logIndex != -1) {
      _logs[logIndex].text = newText;
      notifyListeners();
    }
  }

// Update History Log Text
  Future<void> updateHistoryTextLog(Log parentLog, String historyId, int timestamp, String newText) async {
    await repository.updateHistoryTextLog(parentLog, historyId, timestamp, newText);

    if (historyId.isNotEmpty) {
      final logIndex = _logsHistory.indexWhere((log) => log.historyId == historyId);
      if (logIndex != -1) {
        _logsHistory[logIndex].value = newText;
        notifyListeners();
      }
    } else {
      final logIndex = _logsHistory.indexWhere((log) => log.timestamp == timestamp);
      if (logIndex != -1) {
        // Repository already created new history entry → update local copy
        _logsHistory[logIndex] =
            _logsHistory[logIndex].copyWith(value: newText, type: parentLog.type);
        notifyListeners();
      }
    }
  }

// Update Toggle Log
  Future<void> updateToggleLog(String logId, bool isActive) async {
    await repository.updateLogStatus(logId, isActive);
    final logIndex = _logs.indexWhere((log) => log.id == logId);
    if (logIndex != -1) {
      _logs[logIndex].isActive = isActive;
      notifyListeners();
    }
  }

// Update History Toggle Log
  Future<void> updateHistoryToggleLog(Log parentLog, String historyId, int timestamp, bool value) async {
    await repository.updateHistoryToggleLog(parentLog, historyId, timestamp, value);

    if (historyId.isNotEmpty) {
      final logIndex = _logsHistory.indexWhere((log) => log.historyId == historyId);
      if (logIndex != -1) {
        _logsHistory[logIndex].value = value;
        notifyListeners();
      }
    } else {
      final logIndex = _logsHistory.indexWhere((log) => log.timestamp == timestamp);
      if (logIndex != -1) {
        _logsHistory[logIndex] =
            _logsHistory[logIndex].copyWith(value: value, type: parentLog.type);
        notifyListeners();
      }
    }
  }

  // 🔹 Navigate (UI-only concern)
  void navigateToTimeTracker(BuildContext context, Log log) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TimeTrackerScreen(log: log)),
    );
  }

  // 🔹 Save time log (delegate to repository)
  Future<void> saveTimeLog({required DateTime startTime, required DateTime endTime, required int elapsedTime,}) async {
    // Call repository method (to be implemented in LogRepository + LogRepositoryImpl)
    // await repository.saveTimeLog(startTime, endTime, elapsedTime);
    notifyListeners();
  }

  // 🔹 Local-only helper
  bool isNewDay(DateTime lastReset, DateTime current) {
    return lastReset.year != current.year ||
        lastReset.month != current.month ||
        lastReset.day != current.day;
  }
}
