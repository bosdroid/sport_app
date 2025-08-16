import 'dart:io';
import 'package:bjj_dairy/utils/utils.dart';
import 'package:bjj_dairy/view/pdf_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/plan.dart';

class PdfExportScreen extends StatefulWidget {
  final List<Plan> plans;
  final String collectionName;

  const PdfExportScreen({
    super.key,
    required this.plans,
    required this.collectionName,
  });

  @override
  State<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends State<PdfExportScreen> {
  File? pdfFile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    // Load fonts
    final notoSansRegular = await rootBundle.load("assets/fonts/NotoSans-Regular.ttf");
    final notoFont = pw.Font.ttf(notoSansRegular);

    final dejavuFontData = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
    final dejavuFont = pw.Font.ttf(dejavuFontData);

    // Build PDF content
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Text(
              "Collection: ${widget.collectionName}",
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                font: notoFont,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 20));

          // Loop through each technique
          for (var plan in widget.plans) {
            // Technique title
            widgets.add(
              pw.Text(
                "- ${plan.title}",
                style: pw.TextStyle(
                  font: notoFont,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex(Util.colorToHex(Colors.black)),
                ),
              ),
            );

            // Optional note
            if (plan.note.isNotEmpty) {
              widgets.add(
                pw.Text(
                  "   Note: ${plan.note}",
                  style: pw.TextStyle(
                    font: notoFont,
                    fontSize: 16,
                    color: PdfColor.fromHex(Util.colorToHex(Colors.grey)),
                  ),
                ),
              );
            }

            widgets.add(pw.SizedBox(height: 5));

            // "Transition to" heading
            widgets.add(
              pw.Text(
                "Transition to:",
                style: pw.TextStyle(
                  font: notoFont,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
            );

            // Linked positions
            final linkedPositions = plan.to;
            if (linkedPositions.isNotEmpty) {
              for (var childId in linkedPositions) {
                final target = widget.plans.firstWhere(
                      (p) => p.id == childId,
                  orElse: () => plan,
                );

                widgets.add(
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '-- ',
                          style: pw.TextStyle(font: notoFont, fontSize: 18),
                        ),
                        pw.TextSpan(
                          text: plan.title,
                          style: pw.TextStyle(
                            font: notoFont,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex(Util.colorToHex(Colors.black)),
                          ),
                        ),
                        pw.TextSpan(
                          text: ' ',
                          style: pw.TextStyle(font: notoFont),
                        ),
                        pw.TextSpan(
                          text: '→', // arrow
                          style: pw.TextStyle(
                            font: dejavuFont,
                            fontSize: 18,
                            color: PdfColor.fromHex(Util.colorToHex(Colors.green)),
                          ),
                        ),
                        pw.TextSpan(
                          text: ' ',
                          style: pw.TextStyle(font: notoFont),
                        ),
                        pw.TextSpan(
                          text: target.title,
                          style: pw.TextStyle(
                            font: notoFont,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex(Util.colorToHex(Colors.black)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            } else {
              widgets.add(
                pw.Text(
                  "-- (no linked positions)",
                  style: pw.TextStyle(
                    font: notoFont,
                    fontSize: 16,
                    color: PdfColor.fromHex(Util.colorToHex(Colors.grey)),
                  ),
                ),
              );
            }

            widgets.add(pw.SizedBox(height: 15));
          }

          return widgets;
        },
      ),
    );

    // Save PDF
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/technique_map.pdf');
    await file.writeAsBytes(await pdf.save());

    setState(() {
      pdfFile = file;
      isLoading = false;
    });
  }

  // Future<void> _generatePdf() async {
  //   final pdf = pw.Document();
  //
  //   final fontData = await rootBundle.load("assets/fonts/NotoSansSymbols2.ttf");
  //   final ttf = pw.Font.ttf(fontData);
  //
  //   final techniques = widget.plans.map((plan) {
  //     return "${plan.id}: ${plan.title}${plan.note.isNotEmpty ? '\nNote: ${plan.note}' : ''}";
  //   }).toList();
  //
  //   final links = <String>[];
  //   for (var plan in widget.plans) {
  //     for (var childId in plan.to) {
  //       final target = widget.plans.firstWhere((p) => p.id == childId, orElse: () => plan);
  //       links.add("${plan.title} → ${target.title}");
  //     }
  //   }
  //
  //   pdf.addPage(pw.MultiPage(
  //     theme: pw.ThemeData.withFont(base: ttf),
  //     build: (context) => [
  //       pw.Text("Collection: ${widget.collectionName}", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
  //       pw.SizedBox(height: 20),
  //       pw.Text("List of Techniques", style: pw.TextStyle(fontSize: 20, decoration: pw.TextDecoration.underline)),
  //       ...techniques.map((t) => pw.Text(t)),
  //       pw.SizedBox(height: 20),
  //       pw.Text("Technique Links", style: pw.TextStyle(fontSize: 20, decoration: pw.TextDecoration.underline)),
  //       ...links.map((l) => pw.Text(l)),
  //     ],
  //   ));
  //
  //   final dir = await getApplicationDocumentsDirectory();
  //   final file = File('${dir.path}/technique_map.pdf');
  //   await file.writeAsBytes(await pdf.save());
  //
  //   setState(() {
  //     pdfFile = file;
  //     isLoading = false;
  //   });
  // }

  Future<void> _openPdf(BuildContext context) async {
    if (pdfFile != null) {
      //await OpenFile.open(pdfFile!.path);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewScreen(
            pdfUrl: pdfFile!.path,
          ),
        ),
      );
    }
  }

  Future<void> _downloadPdf() async {
    if (pdfFile == null) return;

    // Request permission first
    // final status = await Permission.storage.request();
    //
    // if (status.isGranted) {
      final extDir = await getExternalStorageDirectory(); // App-specific external dir
      final path = '${extDir!.path}/technique_map_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final savedFile = await pdfFile!.copy(path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved to: ${savedFile.path}")),
      );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Storage permission denied")),
    //   );
    // }
  }

  // Future<void> _downloadPdf() async {
  //   if (pdfFile == null) return;
  //   if (await Permission.storage.request().isGranted) {
  //     final downloadsDir = Directory('/storage/emulated/0/Download');
  //     final newPath = '${downloadsDir.path}/technique_map_${DateTime.now().millisecondsSinceEpoch}.pdf';
  //     await pdfFile!.copy(newPath);
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to Downloads")));
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Storage permission denied")));
  //   }
  // }

  Future<void> _sharePdf() async {
    if (pdfFile != null) {
      await Share.shareFiles([pdfFile!.path], text: 'Here is the technique map.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme:IconThemeData(color: Colors.white),title: const Text("Technique Map PDF",style: TextStyle(color: Colors.white),),backgroundColor: Theme.of(context).primaryColor,),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
            child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      spacing: 32,
                      mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Open PDF"),
                  onPressed: ()=> _openPdf(context),
                ),
              ),
              // const SizedBox(height: 16),
              SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text("Download PDF"),
                  onPressed: _downloadPdf,
                ),
              ),
              // const SizedBox(height: 16),
              SizedBox(
                width: 250,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text("Share PDF"),
                  onPressed: _sharePdf,
                ),
              ),
            ],
                    ),
                  ),
          ),
    );
  }
}
