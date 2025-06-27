import 'package:bjj_dairy/model/video_entry.dart';
import 'package:flutter/material.dart';

class VideoListView extends StatelessWidget {
  final List<VideoEntry> videos;
  final VoidCallback onAddVideo;
  final void Function(VideoEntry video) onPlayVideo;

  const VideoListView({super.key, required this.videos,required this.onAddVideo,
    required this.onPlayVideo,});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // padding: const EdgeInsets.all(16),
      itemCount: videos.length, // Extra for Add Video
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        // if (index == videos.length) {
        //   return Column(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       const SizedBox(height: 20,),
        //       GestureDetector(
        //         onTap: onAddVideo,
        //         child: DottedBorder(
        //           color: Colors.grey,
        //           borderType: BorderType.RRect,
        //           radius: const Radius.circular(12),
        //           dashPattern: [6, 3],
        //           child: Container(
        //             padding: const EdgeInsets.symmetric(vertical: 10),
        //             alignment: Alignment.center,
        //             child: const Row(
        //               mainAxisAlignment: MainAxisAlignment.center,
        //               children: [
        //                 Icon(Icons.add, color: Colors.grey),
        //                 SizedBox(width: 8),
        //                 Text(
        //                   'Add Video',
        //                   style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        //                 ),
        //               ],
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   );
        // }
        final video = videos[index];
        return GestureDetector(
          onTap: () => onPlayVideo(video),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0,horizontal: 8.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFF9FAFB)
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      // if (video.type != null)
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      //     decoration: BoxDecoration(
                      //       color: Theme.of(context).primaryColor,//_getTagColor(video.type),
                      //       borderRadius: BorderRadius.circular(50),
                      //     ),
                      //     child: Text(
                      //       video.type ?? 'Explanation',
                      //       style: TextStyle(
                      //         fontSize: 12,
                      //         color: Colors.white,//_getTextColor(video.type),
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
                // Play button on the right
                GestureDetector(
                  onTap: () => onPlayVideo(video),
                  child: const Icon(Icons.play_arrow, color: Colors.red),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helpers
  Color _getTagColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'explanation':
        return Colors.blue.shade100;
      case 'fight example':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getTextColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'explanation':
        return Colors.blue;
      case 'fight example':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

