import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../domain/entities/video.dart';

class VideosDialog extends StatelessWidget {
  final List<Video> videos;
  const VideosDialog({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    const double headerH = 60;          // title row + divider
    const double itemH   = 76;          // card height incl. its margin
    const double bottomGap = 16;        // 👈 extra space
    final double desiredH =
        headerH + itemH * videos.length + bottomGap;
    final double maxH = MediaQuery.of(context).size.height * 0.8;
    final double dialogH = math.min(desiredH, maxH);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: dialogH,
        child: Column(
          children: [
            // ---------- header with CLOSE icon -------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Videos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    splashRadius: 20,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            // ---------- list --------------------------------------------------
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: bottomGap),
                itemCount: videos.length,
                itemBuilder: (_, index) {
                  final video = videos[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    elevation: 3,
                    color: Colors.white,
                    child: ListTile(
                      onTap: () {
                        Navigator.pop(context);          // close dialog
                        Util.showYoutubeDialog(
                            context, video.link);        // play video
                      },
                      title: Text(
                        video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
