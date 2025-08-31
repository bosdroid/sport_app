import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/folder.dart';
import '../../domain/entities/selected_image.dart';
import '../../domain/repositories/validation_repository.dart';

class ValidationProvider extends ChangeNotifier {
  final ValidationRepository repository;

  ValidationProvider(this.repository);

  // ---------------- Error States ----------------
  String? titleError;
  String? descriptionError;
  String? tagsError;
  String? urlError;
  String? videoTitleError;
  String? videoTypeError;
  String? collectionTitleError;
  String? feedbackError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? usernameError;
  String? agreeTermsError;
  String? imagesError;

  bool isFormValid = false;

  // ---------------- Delegation to Repository ----------------

  void validateTitle(String value) {
    titleError = repository.validateTitle(value);
    notifyListeners();
  }

  void validateDescription(String value) {
    descriptionError = repository.validateDescription(value);
    notifyListeners();
  }

  Future<void> validateTags(List<String> tags, String tag) async {
    tagsError = repository.validateTags(tags, tag);
    notifyListeners();
  }

  Future<void> validateImages(List<SelectedImage> list) async {
    imagesError = repository.validateImages(list);
    notifyListeners();
  }

  Future<void> validateImage(XFile image) async {
    imagesError = await repository.validateImage(image);
    notifyListeners();
  }

  Future<void> updateImageError() async {
    imagesError = 'Maximum 5 images allowed';
    notifyListeners();
  }

  void validUrl(String url) {
    urlError = repository.validateUrl(url);
    notifyListeners();
  }

  void validateVideoTitle(String title) {
    videoTitleError = repository.validateVideoTitle(title);
    notifyListeners();
  }

  void validateVideoType(String url, String type) {
    videoTypeError = repository.validateVideoType(url, type);
    notifyListeners();
  }

  void validateCollectionTitle(String title, List<Folder> existingTitles) {
    collectionTitleError = repository.validateCollectionTitle(title, existingTitles);
    notifyListeners();
  }

  void validateFeedback(String value) {
    feedbackError = repository.validateFeedback(value);
    notifyListeners();
  }

  void validateEmail(String email) {
    emailError = repository.validateEmail(email);
    notifyListeners();
  }

  void validatePassword(String password, bool isValidate) {
    passwordError = repository.validatePassword(password, isValidate);
    notifyListeners();
  }

  void validateConfirmPassword(String password, String confirmPassword) {
    confirmPasswordError = repository.validateConfirmPassword(password, confirmPassword);
    notifyListeners();
  }

  Future<void> validateUsername(String username) async {
    usernameError = await repository.validateUsername(username);
    notifyListeners();
  }

  void validateAgreeTerms(bool agreed) {
    agreeTermsError = repository.validateAgreeTerms(agreed);
    notifyListeners();
  }

  // ---------------- Combined Form Validation ----------------

  void validateForm({
    required String title,
    required String description,
    required String url,
    required String videoTitle,
    required String videoType,
  }) {
    validateTitle(title);
    validateDescription(description);
    validUrl(url);
    validateVideoTitle(videoTitle);
    validateVideoType(url, videoType);

    isFormValid = titleError == null &&
        descriptionError == null &&
        urlError == null &&
        videoTitleError == null &&
        videoTypeError == null;

    notifyListeners();
  }

  void resetAll() {
    titleError = null;
    descriptionError = null;
    urlError = null;
    videoTitleError = null;
    videoTypeError = null;
    emailError = null;
    passwordError = null;
    collectionTitleError = null;
    confirmPasswordError = null;
    usernameError = null;
    agreeTermsError = null;
    imagesError = null;
    isFormValid = false;
    notifyListeners();
  }
}
