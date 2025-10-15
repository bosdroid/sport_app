import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/note_repository.dart';

/// Concrete NoteRepository implementation using Firebase Realtime Database.
class NoteRepositoryImpl implements NoteRepository {
  final DatabaseReference notesRef;

  NoteRepositoryImpl({required this.notesRef});

  Future<String?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("user_name");
  }

  @override
  Future<String> fetchNote([DateTime? dateTime]) async {
    final userId = await _getUserId();
    if (userId == null) return "";

    final now = dateTime ?? DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final snapshot = await notesRef.child('$userId/$todayKey').get();
    if (!snapshot.exists || snapshot.value == null) {
      return "";
    }

    final value = snapshot.value;
    if (value is! Map) {
      return "";
    }

    final data = value as Map<dynamic, dynamic>;
    final note = data['note'];
    if (note is! String || note.isEmpty) {
      return "";
    }

    return note;
  }


  @override
  Future<void> addNote(String text, {DateTime? targetDate}) async {
    final userId = await _getUserId();
    if (userId == null) return;

    final now = targetDate ?? DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    final noteRef = notesRef.child('$userId/$todayKey');
    final snapshot = await noteRef.get();

    final noteData = {
      'note': text,
      'updatedAt': now.millisecondsSinceEpoch,
    };

    if (snapshot.exists) {
      await noteRef.update(noteData);
    } else {
      await noteRef.set(noteData);
    }
  }
}
