/// Contract for managing daily notes.
/// Keeps business logic independent of Firebase.
abstract class NoteRepository {
  /// Fetch the note for today (or given date).
  Future<String> fetchNote(DateTime? dateTime);

  /// Add/update today’s note.
  Future<void> addNote(String text, {DateTime? targetDate});
}
