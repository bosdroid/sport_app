import 'package:bjj_dairy/data/repositories/note_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockDatabaseReference mockRef;
  late NoteRepositoryImpl repository;

  setUp(() {
    mockRef = MockDatabaseReference();
    repository = NoteRepositoryImpl(notesRef: mockRef);
    SharedPreferences.setMockInitialValues({"user_name": "user123"});
  });

  group('NoteRepositoryImpl', () {
    test('fetchNote returns empty string if snapshot does not exist', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);

      final note = await repository.fetchNote(DateTime(2025, 9, 8));

      expect(note, "");
    });

    test('fetchNote returns note when snapshot exists', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn({"note": "Hello"});

      final note = await repository.fetchNote(DateTime(2025, 9, 8));

      expect(note, "Hello");
    });

    test('addNote sets new note if snapshot does not exist', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => mockChildRef.set(any())).thenAnswer((_) async {});

      await repository.addNote("Test Note", targetDate: DateTime(2025, 9, 8));

      verify(() => mockChildRef.set(any())).called(1);
    });

    test('addNote updates existing note if snapshot exists', () async {
      final mockChildRef = MockDatabaseReference();
      final mockSnapshot = MockDataSnapshot();

      when(() => mockRef.child(any())).thenReturn(mockChildRef);
      when(() => mockChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockChildRef.update(any())).thenAnswer((_) async {});

      await repository.addNote("Updated Note", targetDate: DateTime(2025, 9, 8));

      verify(() => mockChildRef.update(any())).called(1);
    });
  });
}
