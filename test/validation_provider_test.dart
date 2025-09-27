import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bjj_dairy/domain/entities/folder.dart';
import 'package:bjj_dairy/domain/entities/selected_image.dart';
import 'package:bjj_dairy/domain/repositories/validation_repository.dart';
import 'package:bjj_dairy/presentation/providers/validation_provider.dart';

// ---------------------- Mocks ----------------------
class MockValidationRepository extends Mock implements ValidationRepository {}
class FakeXFile extends Fake implements XFile {}

void main() {
  late MockValidationRepository mockRepo;
  late ValidationProvider provider;

  setUpAll(() {
    registerFallbackValue(FakeXFile());
  });

  setUp(() {
    mockRepo = MockValidationRepository();
    provider = ValidationProvider(mockRepo);
  });

  test('validateTitle updates titleError', () {
    when(() => mockRepo.validateTitle('ok')).thenReturn(null);

    provider.validateTitle('ok');

    expect(provider.titleError, isNull);
    verify(() => mockRepo.validateTitle('ok')).called(1);
  });

  test('validateDescription updates descriptionError', () {
    when(() => mockRepo.validateDescription('desc')).thenReturn('bad');

    provider.validateDescription('desc');

    expect(provider.descriptionError, 'bad');
    verify(() => mockRepo.validateDescription('desc')).called(1);
  });

  test('validateTags sets tagsError', () async {
    when(() => mockRepo.validateTags(any(), any())).thenReturn('error');

    await provider.validateTags(['tag1'], 'tag2');

    expect(provider.tagsError, 'error');
    verify(() => mockRepo.validateTags(['tag1'], 'tag2')).called(1);
  });

  test('validateImages sets imagesError', () async {
    final imgs = [SelectedImage(url: 'url')];
    when(() => mockRepo.validateImages(imgs)).thenReturn(null);

    await provider.validateImages(imgs);

    expect(provider.imagesError, isNull);
    verify(() => mockRepo.validateImages(imgs)).called(1);
  });

  test('validateImage sets imagesError', () async {
    final xfile = FakeXFile();
    when(() => mockRepo.validateImage(any())).thenAnswer((_) async => 'bad');

    await provider.validateImage(xfile);

    expect(provider.imagesError, 'bad');
    verify(() => mockRepo.validateImage(xfile)).called(1);
  });

  test('updateImageError sets a static message', () async {
    await provider.updateImageError();
    expect(provider.imagesError, 'Maximum 5 images allowed');
  });

  test('validUrl updates urlError', () {
    when(() => mockRepo.validateUrl('u')).thenReturn(null);
    provider.validUrl('u');
    expect(provider.urlError, isNull);
  });

  test('validateVideoType updates videoTypeError', () {
    when(() => mockRepo.validateVideoType('url', 'type')).thenReturn('oops');
    provider.validateVideoType('url', 'type');
    expect(provider.videoTypeError, 'oops');
  });

  test('validateCollectionTitle uses repo', () {
    final folders = [Folder(name: 'A')];
    when(() => mockRepo.validateCollectionTitle('title', folders))
        .thenReturn('duplicate');

    provider.validateCollectionTitle('title', folders);

    expect(provider.collectionTitleError, 'duplicate');
  });

  test('validateUsername updates usernameError', () async {
    when(() => mockRepo.validateUsername('bob'))
        .thenAnswer((_) async => 'taken');

    await provider.validateUsername('bob');

    expect(provider.usernameError, 'taken');
  });

  test('validateForm sets isFormValid true when all null', () {
    when(() => mockRepo.validateTitle(any())).thenReturn(null);
    when(() => mockRepo.validateDescription(any())).thenReturn(null);
    when(() => mockRepo.validateUrl(any())).thenReturn(null);
    when(() => mockRepo.validateVideoTitle(any())).thenReturn(null);
    when(() => mockRepo.validateVideoType(any(), any())).thenReturn(null);

    provider.validateForm(
      title: 't',
      description: 'd',
      url: 'u',
      videoTitle: 'vt',
      videoType: 'yt',
    );

    expect(provider.isFormValid, isTrue);
  });

  test('resetAll clears all errors', () {
    provider.titleError = 'x';
    provider.resetAll();
    expect(provider.titleError, isNull);
    expect(provider.isFormValid, isFalse);
  });
}
