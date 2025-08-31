import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/selected_image.dart';


class ImageService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages() async {
    final List<XFile> images = await _picker.pickMultiImage(
      imageQuality: 80, // compress a little
      limit: 5
    );
    return images;
  }

  // Upload a single image file to Firebase Storage
  Future<String> uploadImage(File file) async {
    String fileId = const Uuid().v4();
    Reference ref = _storage.ref().child('plans_images/$fileId.jpg');

    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;

    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  // Upload multiple images
  // Upload multiple images
  Future<List<String>> uploadImages(List<SelectedImage> images) async {
    List<String> downloadUrls = [];

    for (SelectedImage image in images) {
      if (image.localFile != null) {
        String url = await uploadImage(image.localFile!);
        downloadUrls.add(url);
      }
    }

    return downloadUrls;
  }
}
