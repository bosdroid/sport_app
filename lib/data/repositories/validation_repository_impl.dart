import 'package:image_picker/image_picker.dart';

import '../../core/validator.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/selected_image.dart';
import '../../domain/repositories/validation_repository.dart';

/// Concrete implementation of ValidationRepository
/// Delegates actual validation to the Validator utility class.
class ValidationRepositoryImpl implements ValidationRepository {
  @override
  String? validateTitle(String value) => Validator.title(value);

  @override
  String? validateDescription(String value) => Validator.description(value);

  @override
  String? validateTags(List<String> tags, String tag) => Validator.tags(tags, tag);

  @override
  String? validateUrl(String url) => Validator.validUrl(url);

  @override
  String? validateVideoTitle(String title) => Validator.videoTitle(title);

  @override
  String? validateVideoType(String url, String type) => Validator.videoType(url, type);

  @override
  String? validateCollectionTitle(String title, List<Folder> existingTitles) =>
      Validator.collectionTitle(title, existingTitles);

  @override
  String? validateFeedback(String value) => Validator.feedback(value);

  @override
  String? validateEmail(String email) => Validator.email(email);

  @override
  String? validatePassword(String password, bool isValidate) =>
      Validator.password(password, isValidate);

  @override
  String? validateConfirmPassword(String password, String confirmPassword) =>
      Validator.confirmPassword(password, confirmPassword);

  @override
  Future<String?> validateUsername(String username) =>
      Validator.username(username);

  @override
  String? validateAgreeTerms(bool agreed) => Validator.agreeToTerms(agreed);

  @override
  String? validateImages(List<SelectedImage> list) => Validator.images(list);

  @override
  Future<String?> validateImage(XFile image) => Validator.image(image);
}
