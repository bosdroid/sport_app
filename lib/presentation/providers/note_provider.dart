import 'package:flutter/material.dart';
import '../../domain/repositories/note_repository.dart';

/// State manager for daily notes.
/// Uses NoteRepository for data access.
class NoteProvider with ChangeNotifier {
  final NoteRepository repository;

  NoteProvider(this.repository);

  String _todayNote = "";
  DateTime? _targetDateTime;

  String get todayNote => _todayNote;
  DateTime? get targetDateTime => _targetDateTime;

  void updateTargetDateTime(DateTime dateTime) {
    _targetDateTime = dateTime;
    notifyListeners();
  }

  Future<void> fetchTodayNote([DateTime? dateTime]) async {
    final now = dateTime ?? DateTime.now();
    updateTargetDateTime(now);

    _todayNote = await repository.fetchNote(now);
    notifyListeners();
  }

  Future<void> addNote(String text) async {
    final now = _targetDateTime ?? DateTime.now();
    await repository.addNote(text, targetDate: now);
    _todayNote = await repository.fetchNote(now);
    notifyListeners();
  }
}
