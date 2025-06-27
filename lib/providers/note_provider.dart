
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoteProvider with ChangeNotifier {
  final DatabaseReference _notesRef = FirebaseDatabase.instance.ref().child('NOTES/');
  String _todayNote = "";
  DateTime? _targetDateTime;

  String get todayNote => _todayNote;

  void updateTargetDateTime(DateTime dateTime){
    _targetDateTime = dateTime;
    notifyListeners();
  }

  Future<void> fetchTodayNote(DateTime? dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString("user_name");

    if (userId == null) return;

    final now = dateTime ?? DateTime.now() ;
    updateTargetDateTime(now);
    final todayKey = '${now.year}-${now.month}-${now.day}'; // Unique key for today

    final noteRef = _notesRef.child('$userId/$todayKey');

    noteRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null && data.containsKey('note')) {
        _todayNote = data['note'] as String;
      } else {
        _todayNote = ""; // No note found
      }
      notifyListeners();
    });
  }

  Future<void> addNote(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    final noteRef = _notesRef.child('$userId/');
    final now = _targetDateTime ?? DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}'; // Use date as a unique key

    final snapshot = await noteRef.child(todayKey).get();

    if (snapshot.exists) {
      await noteRef.child(todayKey).update({
        'note': text,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    } else {
      await noteRef.child(todayKey).set({
        'note': text,
        'updatedAt': now.millisecondsSinceEpoch,
      });
    }
    notifyListeners();
    await fetchTodayNote(now);
  }
}