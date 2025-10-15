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

  test('validateVideoTitle sets and clears error correctly', () {
    when(() => mockRepo.validateVideoTitle('bad')).thenReturn('too short');
    when(() => mockRepo.validateVideoTitle('good')).thenReturn(null);

    provider.validateVideoTitle('bad');
    expect(provider.videoTitleError, 'too short');

    provider.validateVideoTitle('good');
    expect(provider.videoTitleError, isNull);
  });

  test('validateFeedback sets feedbackError properly', () {
    when(() => mockRepo.validateFeedback('')).thenReturn('empty');
    when(() => mockRepo.validateFeedback('great')).thenReturn(null);

    provider.validateFeedback('');
    expect(provider.feedbackError, 'empty');

    provider.validateFeedback('great');
    expect(provider.feedbackError, isNull);
  });

  test('validateEmail updates emailError for invalid and valid cases', () {
    when(() => mockRepo.validateEmail('bad@')).thenReturn('invalid');
    when(() => mockRepo.validateEmail('ok@mail.com')).thenReturn(null);

    provider.validateEmail('bad@');
    expect(provider.emailError, 'invalid');

    provider.validateEmail('ok@mail.com');
    expect(provider.emailError, isNull);
  });

  test('validatePassword handles both validation modes', () {
    when(() => mockRepo.validatePassword('123', true)).thenReturn('weak');
    when(() => mockRepo.validatePassword('Strong123', false)).thenReturn(null);

    provider.validatePassword('123', true);
    expect(provider.passwordError, 'weak');

    provider.validatePassword('Strong123', false);
    expect(provider.passwordError, isNull);
  });

  test('validateConfirmPassword sets confirmPasswordError for mismatch and clears when matched', () {
    when(() => mockRepo.validateConfirmPassword('abc', 'xyz'))
        .thenReturn('mismatch');
    when(() => mockRepo.validateConfirmPassword('abc', 'abc'))
        .thenReturn(null);

    provider.validateConfirmPassword('abc', 'xyz');
    expect(provider.confirmPasswordError, 'mismatch');

    provider.validateConfirmPassword('abc', 'abc');
    expect(provider.confirmPasswordError, isNull);
  });

  test('validateAgreeTerms sets and clears error properly', () {
    when(() => mockRepo.validateAgreeTerms(false)).thenReturn('must agree');
    when(() => mockRepo.validateAgreeTerms(true)).thenReturn(null);

    provider.validateAgreeTerms(false);
    expect(provider.agreeTermsError, 'must agree');

    provider.validateAgreeTerms(true);
    expect(provider.agreeTermsError, isNull);
  });

  test('validateForm sets isFormValid false when any validator returns error', () {
    when(() => mockRepo.validateTitle(any())).thenReturn('bad');
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

    expect(provider.isFormValid, isFalse);
  });

  test('validUrl sets error when repository returns message', () {
    when(() => mockRepo.validateUrl('bad')).thenReturn('invalid url');

    provider.validUrl('bad');

    expect(provider.urlError, 'invalid url');
  });

  test('validateImage clears imagesError when repository returns null', () async {
    final xfile = FakeXFile();
    when(() => mockRepo.validateImage(any())).thenAnswer((_) async => null);

    await provider.validateImage(xfile);

    expect(provider.imagesError, isNull);
  });

  test('validateTags clears tagsError when repository returns null', () async {
    when(() => mockRepo.validateTags(any(), any())).thenReturn(null);

    await provider.validateTags(['tag1'], 'tag2');

    expect(provider.tagsError, isNull);
  });


}
