import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewScreen extends StatelessWidget {
  final String pdfUrl;
  const PdfViewScreen({super.key, required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme:IconThemeData(color: Colors.white),title: const Text("PDF Viewer",style: TextStyle(color: Colors.white),),backgroundColor: Theme.of(context).primaryColor,),
      body: SfPdfViewer.file(File(pdfUrl)),
    );
  }
}