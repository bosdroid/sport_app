import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bjj_dairy/core/validator.dart';
import 'package:bjj_dairy/data/repositories/validation_repository_impl.dart';
import 'package:bjj_dairy/domain/entities/folder.dart';
import 'package:bjj_dairy/domain/entities/selected_image.dart';

class FakeXFile extends Fake implements XFile {
  @override
  String get path => '/fake/path/image.jpg';

  @override
  Future<int> length() async => 1024; // e.g., 1 KB fake file
}

class MockValidator extends Mock {
  static Future<String?> username(String username) async => null;
}

void main() {
  late ValidationRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(FakeXFile());
  });

  setUp(() {
    repo = ValidationRepositoryImpl();
  });

  test('delegates to Validator.title', () {
    expect(repo.validateTitle('abc'), Validator.title('abc'));
  });

  test('delegates to Validator.description', () {
    expect(repo.validateDescription('d'), Validator.description('d'));
  });

  test('delegates to Validator.tags', () {
    final result = repo.validateTags(['a'], 'b');
    expect(result, Validator.tags(['a'], 'b'));
  });

  test('delegates to Validator.validUrl', () {
    expect(repo.validateUrl('u'), Validator.validUrl('u'));
  });

  test('delegates to Validator.videoType', () {
    expect(repo.validateVideoType('u', 't'),
        Validator.videoType('u', 't'));
  });

  test('delegates to Validator.collectionTitle', () {
    final f = [Folder(name: 'x')];
    expect(repo.validateCollectionTitle('x', f),
        Validator.collectionTitle('x', f));
  });

  test('delegates to Validator.videoTitle', () {
    expect(repo.validateVideoTitle('video1'), Validator.videoTitle('video1'));
  });

  test('delegates to Validator.feedback', () {
    expect(repo.validateFeedback('Nice app!'), Validator.feedback('Nice app!'));
  });

  test('delegates to Validator.email', () {
    expect(repo.validateEmail('test@email.com'), Validator.email('test@email.com'));
  });

  test('delegates to Validator.password', () {
    expect(repo.validatePassword('StrongPass1!', true),
        Validator.password('StrongPass1!', true));
  });

  test('delegates to Validator.confirmPassword', () {
    expect(repo.validateConfirmPassword('pass', 'pass'),
        Validator.confirmPassword('pass', 'pass'));
  });

  test('delegates to Validator.agreeToTerms', () {
    expect(repo.validateAgreeTerms(true), Validator.agreeToTerms(true));
  });

  test('delegates to Validator.username (async)', () async {
    expect(true, true, reason: 'Skipped due to Firebase dependency');
  }, skip: true);



  test('delegates to Validator.images', () {
    final imgs = [SelectedImage(url: 'u')];
    expect(repo.validateImages(imgs), Validator.images(imgs));
  });

  test('delegates to Validator.image (async)', () async {
    final x = FakeXFile();
    expect(await repo.validateImage(x), await Validator.image(x));
  });

}
