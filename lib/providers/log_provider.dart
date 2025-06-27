import 'package:bjj_dairy/model/log_history.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/log.dart';
import '../view/time_tracker_screen.dart';

class LogProvider with ChangeNotifier {
  final DatabaseReference _logRef = FirebaseDatabase.instance.ref().child('USERS/LOGS/');
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref().child('LOGS_HISTORY/');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Log> _logs = [];
  List<Log> _activeLogs = [];
  List<LogHistory> _logsHistory = [];
  bool _isLoading = false;
  List<Log> get logs => _logs;
  List<Log> get activeLogs => _activeLogs;
  List<LogHistory> get logsHistory => _logsHistory;
  bool get isLoading => _isLoading;

  // List<Log> get activeLogs {
  //   final int today = DateTime.now().weekday; // Monday = 1, Sunday = 7
  //   return _logs.where((log) {
  //     if (!log.isActive) return false;
  //     // Check if today is one of the active days (log.activeDays should be a List<int>)
  //     return log.days.contains(today);
  //   }).toList();
  // }

  Future<void> getActiveLogsForDate(DateTime? date) async {
    final int weekday = date == null ? DateTime.now().weekday : date.weekday; // Monday = 1, Sunday = 7
    _activeLogs = _logs.where((log) {
      if (!log.isActive) return false;
      return log.days.contains(weekday);
    }).toList();
    notifyListeners();
  }

  int get totalActiveLogs {
    final int today = DateTime.now().weekday; // Monday = 1, Sunday = 7
    int counter = 0;

    for (var log in _logs) {
      if (log.isActive && log.days.contains(today)) {
        counter++;
      }
    }
    return counter;
  }

  bool get anyLogChanges {
    return _logs.any((log) => log.isActive && log.changes);
  }

  // Future<void> fetchLogsOnDateChange(DateTime? dateTime) async {
  //   final int today = DateTime.now().weekday; // Monday = 1, Sunday = 7
  //   return _logs.where((log) {
  //     if (!log.isActive) return false;
  //     // Check if today is one of the active days (log.activeDays should be a List<int>)
  //     return log.days.contains(today);
  //   }).toList();
  // }

  Future<void> updateAllLogChanges() async {
    _isLoading = true;
    notifyListeners();

    List<Log> changesLogItems = _logs.where((log) => log.isActive && log.changes).toList();

    for (var log in changesLogItems) {
      if(log.type == 'Text Input'){
        updateTextLog(log.id,log.text as String);
        // saveLogHistory(log.id, log.type, log.text);
      }
      else if(log.type == 'Number Input'){
        updateNumberLog(log.id,log.number);
        // saveLogHistory(log.id, log.type, log.number);
      }
      else if(log.type == 'Toggle Yes/No'){
        updateLogToggle(log.id,log.toggle);
        // saveLogHistory(log.id, log.type, log.toggle);
      }
      else{
        // saveLogHistory(log.id, log.type, log.time);
      }
    }
    resetChanges();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateLogData(Log data) async {
    final logIndex = _logs.indexWhere((log) => log.id == data.id);
    if (logIndex != -1) {
       if(data.type == 'Text Input'){
         _logs[logIndex].text = data.text;
       }
       else if(data.type == 'Number Input'){
         _logs[logIndex].number = data.number;
       }
       else if(data.type == 'Toggle Yes/No'){
         _logs[logIndex].toggle = data.toggle;
       }
       else{
         _logs[logIndex].time = data.time;
       }
      _logs[logIndex].changes = data.changes;
      notifyListeners();
    }
  }

  Future<void> updateLogDataWithAi(String title,dynamic value) async {
    final logIndex = _activeLogs.indexWhere((log) => log.title.toLowerCase() == title.toLowerCase());
    if (logIndex != -1) {
      if(_logs[logIndex].type == 'Text Input'){
        _logs[logIndex].text = value;
        updateTextLog(_logs[logIndex].id, value);
      }
      else if(_logs[logIndex].type == 'Number Input'){
        _logs[logIndex].number = int.parse(value);
        updateNumberLog(_logs[logIndex].id, int.parse(value));
      }
      else if(_logs[logIndex].type == 'Toggle Yes/No'){
        _logs[logIndex].toggle = value.toString().toLowerCase() == "no" ? false : true;
        updateLogToggle(_logs[logIndex].id, value.toString().toLowerCase() == "no" ? false : true);
      }
      else{
        _logs[logIndex].time = value;
      }

      notifyListeners();
    }
  }

  // Helper to reset _isChanged
  void resetChanges() {
    for (var log in _logs) {
      log.changes = false;
    }
    notifyListeners();
  }

  // Fetch Logs from Firebase
  // Future<void> fetchLogs() async {
  //   final user = _auth.currentUser;
  //   if (user == null) return;
  //
  //   //final String userId = user.uid;
  //   final prefs = await SharedPreferences.getInstance();
  //   final String userId = prefs.getString("user_name") as String;
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final snapshot = await _logRef.child(userId).get();
  //
  //     if (snapshot.exists && snapshot.value is Map) {
  //       final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
  //
  //       // Convert data to a list of goals
  //       _logs = data.entries.map((entry) {
  //         final key = entry.key as String; // Firebase ID
  //         final value = Map<String, dynamic>.from(entry.value as Map); // Goal data
  //         return Log.fromMap(value, key); // Correct parameter order
  //       }).toList();
  //     } else {
  //       _logs = [];
  //     }
  //   } catch (e) {
  //     print("Error fetching goals: $e");
  //     _logs = [];
  //   }
  //
  //   _isLoading = false;
  //   notifyListeners();
  // }

  Future<void> fetchLogs() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _logRef.child(userId).get();

      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        final List<Log> fetchedLogs = [];

        for (final entry in data.entries) {
          final key = entry.key as String;
          final value = Map<String, dynamic>.from(entry.value as Map);

          Log log = Log.fromMap(value, key);

          // Check if the log needs to be reset (new day check)
          final lastResetDate = DateTime.fromMillisecondsSinceEpoch((log.resetTimestamp == null || log.resetTimestamp == 0) ? log.timestamp : log.resetTimestamp ?? 0);
          final currentDate = DateTime.now();

          if (_isNewDay(lastResetDate, currentDate)) {
            log = log.resetValues();

            // Update the log in Firebase with reset values
            await _logRef.child(userId).child(log.id).set(log.toMap());
          }

          fetchedLogs.add(log);
        }

        _logs = fetchedLogs;
      } else {
        _logs = [];
      }
    } catch (e) {
      print("Error fetching logs: $e");
      _logs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create a New Log
  Future<void> addLog({required String title, required String description,required String type}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    _isLoading = true;
    notifyListeners();
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    final String logId = _logRef.child(userId).push().key!;
    final List<int> allDays = [1, 2, 3, 4, 5, 6, 7]; // All days (Mon-Sun)


    Log newLog = Log(
      id: logId,
      title: title,
      description: description,
      type: type,
      isActive: true,
      timestamp: DateTime.now().millisecondsSinceEpoch,
        resetTimestamp: DateTime.now().millisecondsSinceEpoch,
      days: allDays
    );

    await _logRef.child("$userId/$logId").set(newLog.toMap());
    _logs.add(newLog);
    _isLoading = false;
    notifyListeners();
  }

  // 🔵 update Log to Firebase
  Future<void> updateLog(Log updatedLog) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    try {
      await _logRef.child('$userId/${updatedLog.id}').update({
        'title': updatedLog.title,
        'description': updatedLog.description,
        'type': updatedLog.type,
        'isActive':updatedLog.isActive
      });
      // Update the log locally
      final index = _logs.indexWhere((log) => log.id == updatedLog.id);
      if (index != -1) {
        _logs[index] = updatedLog;
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating log: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateLogToggle(String logId, bool toggle) async {
    final user = _auth.currentUser;
    if (user == null) return;
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    final logIndex = _logs.indexWhere((log) => log.id == logId);
    if (logIndex != -1) {
      _logs[logIndex].toggle = toggle;
      notifyListeners();

      // Update in database or backend
      _logRef.child('$userId/$logId').update({'toggle': toggle});
    }
  }

  Future<void> updateLogStatus(String logId, bool isActive) async {
    final user = _auth.currentUser;
    if (user == null) return;
    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    final logIndex = _logs.indexWhere((log) => log.id == logId);
    if (logIndex != -1) {
      _logs[logIndex].isActive = isActive;
      notifyListeners();

      // Update in database or backend
      _logRef.child('$userId/$logId').update({'isActive': isActive});
    }
  }

  // 🔴 Delete Goal
  Future<void> deleteLog(String logId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    await _logRef.child("$userId/$logId").remove();

    _logs.removeWhere((log) => log.id == logId);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveLogHistory(String logId, String type, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    final String historyId = _historyRef.child("$userId/$logId").push().key!;

    final historyData = {
      'historyId': historyId,
      'type': type,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await _historyRef.child("$userId/$logId/$historyId").set(historyData);
  }

  Future<void> fetchLogHistory(Log log) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    final creationDate = DateTime.fromMillisecondsSinceEpoch(log.timestamp);
    final currentDate = DateTime.now();
    final allDates = await getDatesBetween(creationDate, currentDate);

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _historyRef.child("$userId/${log.id}").get();

      Map<int, LogHistory> timestampHistoryMap = {}; // key is date as timestamp (start of day)

      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;

        for (var entry in data.entries) {
          final key = entry.key as String; // Firebase key (can be ignored or stored if needed)
          final value = Map<String, dynamic>.from(entry.value as Map);

          final logHistory = LogHistory.fromMap(value, key);
          final logDate = DateTime.fromMillisecondsSinceEpoch(logHistory.timestamp);

          // Normalize to start of the day to match
          final normalizedTimestamp = _getStartOfDay(logDate).millisecondsSinceEpoch;
          timestampHistoryMap[normalizedTimestamp] = logHistory;
        }
      }

      // Ensure all dates between creationDate and currentDate are present
      _logsHistory = allDates.map((date) {
        final normalizedTimestamp = _getStartOfDay(date).millisecondsSinceEpoch;
        return timestampHistoryMap[normalizedTimestamp] ?? LogHistory.empty(normalizedTimestamp);
      }).toList();
    } catch (e) {
      // On error, fill all dates with empty LogHistory
      _logsHistory = allDates.map((date) {
        final normalizedTimestamp = _getStartOfDay(date).millisecondsSinceEpoch;
        return LogHistory.empty(normalizedTimestamp);
      }).toList();
    }

    _isLoading = false;
    notifyListeners();
  }

  DateTime _getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<List<DateTime>> getDatesBetween(DateTime startDate, DateTime endDate) async {
    List<DateTime> dates = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      dates.add(currentDate);
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dates;
  }

  // Update Log Days Number
  Future<void> updateLogDays(String logId, List<int> days) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    final logIndex = logs.indexWhere((log) => log.id == logId);
    if (logIndex != -1) {
      logs[logIndex] = logs[logIndex].copyWith(days: days);
      notifyListeners();

      _logRef.child('$userId/$logId').update({'days': days});
    }
  }

  // Update Log Number
  Future<void> updateNumberLog(String logId, int newNumber) async {
    final user = _auth.currentUser;
    if (user == null) return;

    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    final logIndex = _logs.indexWhere((log) => log.id == logId);

    if (logIndex != -1) {
      _logs[logIndex].number = newNumber;
      notifyListeners();
      // Update in database or backend
      _logRef.child('$userId/$logId').update({'number': newNumber});
    }
  }

  // Update History Log Number
  Future<void> updateHistoryNumberLog(Log parentLog,String historyId,int timestamp, int newNumber) async {
    final user = _auth.currentUser;
    if (user == null) return;

    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    if(historyId.isNotEmpty) {
      final logIndex = _logsHistory.indexWhere((log) =>
      log.historyId == historyId);

      if (logIndex != -1) {
        _logsHistory[logIndex].value = newNumber;
        notifyListeners();
        // Update in database or backend
        _historyRef.child('$userId/${parentLog.id}/$historyId').update({'value': newNumber});
      }
    }
    else{
      final logIndex = _logsHistory.indexWhere((log) => log.timestamp == timestamp);
      final String newHistoryId = _historyRef.child("$userId/${parentLog.id}").push().key!;

      final historyData = {
        'historyId': newHistoryId,
        'type': parentLog.type,
        'value': newNumber,
        'timestamp': timestamp,
      };
      _logsHistory[logIndex] = LogHistory(historyId: newHistoryId, timestamp: timestamp, type: parentLog.type,value: newNumber);
      notifyListeners();
      await _historyRef.child("$userId/${parentLog.id}/$newHistoryId").set(historyData);
    }
  }

  // Update Log Text
  Future<void> updateTextLog(String logId, String newText) async {
    final user = _auth.currentUser;
    if (user == null) return;

    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    final logIndex = _logs.indexWhere((log) => log.id == logId);

    if (logIndex != -1) {
      _logs[logIndex].text = newText;
      notifyListeners();

      // Update in database or backend
      _logRef.child('$userId/$logId').update({'text': newText});
    }
  }

  // Update History Log Text
  Future<void> updateHistoryTextLog(Log parentLog,String historyId,int timestamp, String newText) async {
    final user = _auth.currentUser;
    if (user == null) return;

    //final String userId = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    if(historyId.isNotEmpty) {
      final logIndex = _logsHistory.indexWhere((log) =>
      log.historyId == historyId);

      if (logIndex != -1) {
        _logsHistory[logIndex].value = newText;
        notifyListeners();

        // Update in database or backend
        _logRef.child('$userId/${parentLog.id}/$historyId').update({'value': newText});
      }
    }
    else{
      final logIndex = _logsHistory.indexWhere((log) => log.timestamp == timestamp);
      final String newHistoryId = _historyRef.child("$userId/${parentLog.id}").push().key!;

      final historyData = {
        'historyId': newHistoryId,
        'type': parentLog.type,
        'value': newText,
        'timestamp': timestamp,
      };
      _logsHistory[logIndex] = LogHistory(historyId: newHistoryId, timestamp: timestamp, type: parentLog.type,value: newText);
      notifyListeners();
      await _historyRef.child("$userId/${parentLog.id}/$newHistoryId").set(historyData);
    }
  }

  // Update Toggle Log
  void updateToggleLog(String logId, bool isActive) {
    updateLogStatus(logId, isActive);
  }

  // Update History Toggle Log
  Future<void> updateHistoryToggleLog(Log parentLog,String historyId,int timestamp, bool value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    if(historyId.isNotEmpty){
      final logIndex = _logsHistory.indexWhere((log) => log.historyId == historyId);

      if (logIndex != -1) {
        _logsHistory[logIndex].value = value;
        notifyListeners();
        // Update in database or backend
        _historyRef.child('$userId/${parentLog.id}/$historyId').update({'value': value});
      }
    }
    else{
      final logIndex = _logsHistory.indexWhere((log) => log.timestamp == timestamp);
      final String newHistoryId = _historyRef.child("$userId/${parentLog.id}").push().key!;

      final historyData = {
        'historyId': newHistoryId,
        'type': parentLog.type,
        'value': value,
        'timestamp': timestamp,
      };
      _logsHistory[logIndex] = LogHistory(historyId: newHistoryId, timestamp: timestamp, type: parentLog.type,value: value);
      notifyListeners();
      await _historyRef.child("$userId/${parentLog.id}/$newHistoryId").set(historyData);
    }
  }

  // Time Tracker Navigation
  void navigateToTimeTracker(BuildContext context, Log log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeTrackerScreen(log: log),
      ),
    );
  }

  Future<void> saveTimeLog({
    required DateTime startTime,
    required DateTime endTime,
    required int elapsedTime,
  }) async {
    // try {
    //   await _firestore.collection('timeLogs').add({
    //     'startTime': startTime.toIso8601String(),
    //     'endTime': endTime.toIso8601String(),
    //     'elapsedTime': elapsedTime, // In seconds
    //     'createdAt': FieldValue.serverTimestamp(),
    //   });
    //   notifyListeners();
    // } catch (e) {
    //   debugPrint("Error saving time log: $e");
    // }
  }

  bool _isNewDay(DateTime lastReset, DateTime current) {
    return lastReset.year != current.year ||
        lastReset.month != current.month ||
        lastReset.day != current.day;
  }
}
