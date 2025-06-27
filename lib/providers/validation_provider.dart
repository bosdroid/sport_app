import 'dart:io';

import 'package:bjj_dairy/model/folder.dart';
import 'package:bjj_dairy/model/selected_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/validator.dart';

class ValidationProvider extends ChangeNotifier {
  // ---------------- Technique Card Fields ----------------
  String? titleError;
  String? descriptionError;
  String? tagsError;
  String? urlError;
  String? videoTitleError;
  String? videoTypeError;
  String? collectionTitleError;
  String? feedbackError;

  // ---------------- Registration Fields ----------------
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? usernameError;
  String? agreeTermsError;
  String? imagesError;

  // Realtime field states
  bool isFormValid = false;

  // --------------- Real-time Field Validators ---------------

  void validateTitle(String value) {
    titleError = Validator.title(value);
    notifyListeners();
  }

  void validateDescription(String value) {
    descriptionError = Validator.description(value);
    notifyListeners();
  }

  Future<void> validateTags(List<String> tags,String tag) async {
    tagsError = Validator.tags(tags,tag);
    notifyListeners();
  }

  Future<void> validateImages(List<SelectedImage> list) async {
    imagesError = Validator.images(list);
    notifyListeners();
  }

  Future<void> validateImage(XFile image) async {
    imagesError = await Validator.image(image);
    notifyListeners();
  }

  Future<void> updateImageError() async {
    imagesError = 'Maximum 5 images allowed';
    notifyListeners();
  }

  void validUrl(String url) {
    urlError = Validator.validUrl(url);
    notifyListeners();
  }

  void validateVideoTitle(String title) {
    videoTitleError = Validator.videoTitle(title);
    notifyListeners();
  }

  void validateVideoType(String url, String type) {
    videoTypeError = Validator.videoType(url, type);
    notifyListeners();
  }

  void validateCollectionTitle(String title, List<Folder> existingTitles) {
    collectionTitleError = Validator.collectionTitle(title, existingTitles);
    notifyListeners();
  }

  void validateFeedback(String value) {
   feedbackError = Validator.feedback(value);
    notifyListeners();
  }

  void validateEmail(String email) {
    emailError = Validator.email(email);
    notifyListeners();
  }

  void validatePassword(String password,bool isValidate) {
    passwordError = Validator.password(password,isValidate);
    notifyListeners();
  }

  void validateConfirmPassword(String password, String confirmPassword) {
    confirmPasswordError = Validator.confirmPassword(password, confirmPassword);
    notifyListeners();
  }

  Future<void> validateUsername(String username) async {
    usernameError = await Validator.username(username);
    notifyListeners();
  }

  void validateAgreeTerms(bool agreed) {
    agreeTermsError = Validator.agreeToTerms(agreed);
    notifyListeners();
  }

  // --------------- Combined Form Validation ---------------

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
    isFormValid = false;
    notifyListeners();
  }
}
