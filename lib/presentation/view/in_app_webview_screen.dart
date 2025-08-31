import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppWebViewScreen extends StatefulWidget {
  final String url;

  const InAppWebViewScreen({super.key, required this.url});

  @override
  _InAppWebViewScreenState createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  InAppWebViewController? webViewController;
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Watch Video"),
        actions: [
          if (progress < 1.0)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircularProgressIndicator(value: progress),
            )
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onProgressChanged: (controller, progress) {
          setState(() {
            this.progress = progress / 100;
          });
        },
      ),
    );
  }
}