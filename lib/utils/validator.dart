import 'dart:io';

import 'package:bjj_dairy/model/folder.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import '../model/selected_image.dart';

class Validator {
  // -------------------- Technique Card --------------------
  static final DatabaseReference _usernamesRef = FirebaseDatabase.instance.ref().child('USERNAMES/');
  static String? title(String? value) {
    if (value == null || value.trim().isEmpty) return 'Title is required';
    if (value.trim().length < 3) return 'Title must be at least 3 characters';
    return null;
  }

  static String? tags(List<String> tags,String tag) {
    for (var existingTag in tags) {
      if (existingTag.trim().toLowerCase() == tag.trim().toLowerCase()) {
        return 'Duplicate tags not allowed';
      }
    }
    if (tags.length >= 5) {
      return 'Maximum 5 tags allowed';
    }
    return null;
  }

  static String? description(String? value) {
    if (value != null && value.length > 500) return 'Max 500 characters allowed';
    return null;
  }

  static String? validUrl(String? url) {
    if (url == null || url.isEmpty) return 'Url field is required';
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Invalid URL';
    }
    return null; // Valid URL
  }

  static String? videoTitle(String? title) {
    // if (url != null && url.isNotEmpty) {
    //   if (title == null || title.trim().isEmpty) return 'Video title is required';
      if (title!.trim().length < 3) return 'At least 3 characters';
    // }
    return null;
  }

  static String? videoType(String? url, String? type) {
    const validTypes = ['Explanation', 'Fight', 'Drill'];
    if (url != null && url.isNotEmpty) {
      if (type == null || type.isEmpty) return 'Video type is required';
      if (!validTypes.contains(type)) return 'Invalid video type';
    }
    return null;
  }

  static String? images(List<SelectedImage> images) {
    if (images.length > 5) return 'Maximum 5 images allowed';

    // for (var image in images) {
    //   if (image.isLocal && image.localFile != null) {
    //     final path = image.localFile!.path;
    //     final ext = path.split('.').last.toLowerCase();
    //
    //     if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
    //       return 'Only JPG or PNG images are allowed';
    //     }
    //
    //     final fileSize = image.localFile!.lengthSync();
    //     if (fileSize > 5 * 1024 * 1024) {
    //       return 'Image exceeds 5MB limit';
    //     }
    //   }
    // }
    return null;
  }

  static Future<String?> image(XFile image) async {
    final path = image.path;
    final ext = path.split('.').last.toLowerCase();

    if (ext != 'jpg' && ext != 'jpeg' && ext != 'png') {
      return 'Only JPG or PNG images are allowed';
    }

    return image.length().then((fileSize) {
      if (fileSize > 5 * 1024 * 1024) {
        return 'Image exceeds 5MB limit';
      }
      return null;
    });
  }

  // -------------------- Collection --------------------

  static String? collectionTitle(String? value, List<Folder> existingTitles) {
    if (value == null || value.trim().isEmpty) return 'Collection title required';
    if (value.trim().length < 3) return 'At least 3 characters';
    if (value.trim().length > 30) return 'Max 30 characters';

    final trimmed = value.trim();
    final isDuplicate = existingTitles.any((folder) => folder.name?.toLowerCase() == trimmed.toLowerCase());
    if (isDuplicate) return 'Title already exists';
    return null;
  }

  // -------------------- Feedback --------------------

  static String? feedback(String? value) {
    if (value != null && value.trim().isEmpty) return 'Cannot be empty if submitted';
    return null;
  }

  // -------------------- Registration --------------------

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Invalid email format';
    return null;
  }

  static String? password(String? value,bool isValidate) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8 && isValidate) return 'Minimum 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value) && isValidate) return 'Must contain uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value) && isValidate) return 'Must contain lowercase letter';
    if (!RegExp(r'\d').hasMatch(value) && isValidate) return 'Must contain number';
    if (value.contains(' ') && isValidate) return 'No spaces allowed';
    return null;
  }

  static String? confirmPassword(String password, String confirm) {
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  static Future<String?> username(String? value) async {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (value.length < 3) return 'Minimum 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) return 'Only alphanumeric characters';
    final snapshot = await _usernamesRef.orderByChild('username').equalTo(value).get();
    if (snapshot.exists) {
      return 'Username is already taken.';
    }
    return null;
  }

  static String? agreeToTerms(bool agreed) {
    if (!agreed) return 'You must agree to the terms';
    return null;
  }

  // -------------------- Search --------------------

  static bool isSearchValid(String query) => query.trim().length >= 2;
}
