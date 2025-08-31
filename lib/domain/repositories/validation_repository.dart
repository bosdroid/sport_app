import 'package:image_picker/image_picker.dart';
import '../entities/folder.dart';
import '../entities/selected_image.dart';

/// Contract for validation logic.
/// Keeps the provider independent of concrete validation rules.
abstract class ValidationRepository {
  String? validateTitle(String value);
  String? validateDescription(String value);
  String? validateTags(List<String> tags, String tag);
  String? validateUrl(String url);
  String? validateVideoTitle(String title);
  String? validateVideoType(String url, String type);
  String? validateCollectionTitle(String title, List<Folder> existingTitles);
  String? validateFeedback(String value);
  String? validateEmail(String email);
  String? validatePassword(String password, bool isValidate);
  String? validateConfirmPassword(String password, String confirmPassword);
  Future<String?> validateUsername(String username);
  String? validateAgreeTerms(bool agreed);
  String? validateImages(List<SelectedImage> list);
  Future<String?> validateImage(XFile image);
}
