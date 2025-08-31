import 'dart:io';

class SelectedImage {
  final File? localFile; // when newly picked
  final String? url;     // when loaded from Firebase

  SelectedImage({this.localFile, this.url});

  bool get isLocal => localFile != null;
}
