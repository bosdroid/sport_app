
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../presentation/providers/validation_provider.dart';


class Util {

  static String generateRandomShareId({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  static Future<bool> showDeleteConfirmationDialog(BuildContext context,String text) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion',style: TextStyle(fontSize: 16)),
        content: Text('Are you sure you want to remove ${text}?',style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false; // Return false if dialog is dismissed
  }

  static Future<bool> showMessageDialog(BuildContext context,String text) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Warning!',style: TextStyle(fontSize: 16)),
        content: Text(text,style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Ok', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    ) ??
        false; // Return false if dialog is dismissed
  }

  static String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}";
  }

  static String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static Future<void> launchUrl(String url) async {
    print(url);
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('Could not launch $url');
    }
  }

  static bool isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  static void showYoutubeDialog(BuildContext context, String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl)!;
    YoutubePlayerController controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: YoutubePlayerBuilder(
              player: YoutubePlayer(
                controller: controller,
                showVideoProgressIndicator: true,
              ),
              builder: (context, player) {
                return AspectRatio(
                  aspectRatio: 16 / 9,
                  child: player,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // static bool isValidVideoUrl(String url) {
  //   final videoUrlRegex = RegExp(
  //     r'^(https?:\/\/)?' // http or https
  //     r'((www\.)?)' // optional www
  //     r'(youtube\.com|youtu\.be|vimeo\.com|facebook\.com|fb\.watch|dailymotion\.com|tiktok\.com|instagram\.com|drive\.google\.com)' // platforms
  //     r'\/[^\s]+$', // path after domain
  //     caseSensitive: false,
  //   );
  //   return videoUrlRegex.hasMatch(url.trim());
  // }

  // static bool isValidVideoUrl(String url) {
  //   final videoUrlRegex = RegExp(
  //     r'^(https?:\/\/)?' // http or https
  //     r'(www\.)?' // optional www
  //     r'(youtube\.com|youtu\.be|vimeo\.com|facebook\.com|fb\.watch|dailymotion\.com|tiktok\.com|instagram\.com|drive\.google\.com)' // platforms
  //     r'(\/[^\s]*)?$', // optional path and query
  //     caseSensitive: false,
  //   );
  //   return videoUrlRegex.hasMatch(url.trim());
  // }
  static bool isValidVideoUrl(String url) {
    final videoUrlRegex = RegExp(
      r'^(https?:\/\/)'                          // Must start with http:// or https://
      r'(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})'         // Domain
      r'(\/[^\s]*)?'                              // Optional path
      r'(\.(mp4|mov|webm|ogg|mkv|flv|avi|wmv))?'  // Optional video extension
      r'(\?[^\s]*)?$',                            // Optional query params
      caseSensitive: false,
    );

    return videoUrlRegex.hasMatch(url.trim());
  }



  static Future<void> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirmed,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismiss on tap outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title,style: TextStyle(fontSize: 16),),
          content: Text(content,style: TextStyle(fontSize: 14)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel',style: TextStyle(color: Colors.red),),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                onConfirmed(); // Execute callback
              },
            ),
          ],
        );
      },
    );
  }

  static void showFeedbackDialog(
      BuildContext context, {
        required Function(int rating, String feedback) onSubmit,
        required VoidCallback onClose,
        required VoidCallback onNotNow,
      }) {
    int selectedRating = 0;
    String feedbackText = "";
    final TextEditingController _feedbackController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            onClose();
                          },
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Do you enjoy using this app?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap a star to rate',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.grey[700],
                            size: 36,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedRating = index + 1;

                            });
                          },
                        );
                      }),
                    ),
                    if (selectedRating > 0) ...[
                      const SizedBox(height: 10),
                      Consumer<ValidationProvider>(
                        builder: (context, validator, child) {
                          return TextFormField(
                            controller: _feedbackController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Tell us more about your experience (optional)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              errorText: validator.feedbackError,

                            ),
                            onChanged: (value) {
                              validator.validateFeedback(value);
                              setState(() {
                                feedbackText = value;
                              });
                            },
                          );
                        },
                      ),
                      // TextField(
                      //   maxLines: 3,
                      //   decoration: InputDecoration(
                      //     hintText: 'Tell us more about your experience (optional)',
                      //     border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      //   ),
                      //   onChanged: (value) {
                      //     setState(() {
                      //       feedbackText = value;
                      //     });
                      //   },
                      // ),
                      const SizedBox(height: 10,),
                      const Text(
                        'Your feedback helps us to improve.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                    ],
                    ...[
                      const SizedBox(height: 30,),
                      Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onNotNow();
                          },
                          child: const Text('Not now', style: TextStyle(color: Colors.green)),
                        ),
                        const Spacer(),
                        // ElevatedButton(
                        //   onPressed: selectedRating > 0 || (_feedbackController.text.isNotEmpty && Provider.of<ValidationProvider>(context).feedbackError == null)
                        //       ? (){
                        //     Navigator.of(context).pop();
                        //     if(Provider.of<ValidationProvider>(context).feedbackError == null) {
                        //       onSubmit(selectedRating, feedbackText.trim());
                        //     }
                        //   }
                        //       : null,
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: selectedRating > 0
                        //         ? Colors.green
                        //         : Colors.grey.shade300,
                        //   ),
                        //   child: Text(
                        //     'Submit',
                        //     style: TextStyle(
                        //       color: selectedRating > 0 ? Colors.white : Colors.grey,
                        //     ),
                        //   ),
                        // ),
                        Consumer<ValidationProvider>(
                          builder: (context, validator, _) {
                            final isFeedbackValid = _feedbackController.text.isNotEmpty && validator.feedbackError == null;
                            final isButtonEnabled = selectedRating > 0 && isFeedbackValid;

                            return ElevatedButton(
                              onPressed: isButtonEnabled
                                  ? () {
                                Navigator.of(context).pop();
                                onSubmit(selectedRating, _feedbackController.text.trim());
                              }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isButtonEnabled ? Colors.green : Colors.grey.shade300,
                              ),
                              child: Text(
                                'Submit',
                                style: TextStyle(color: isButtonEnabled ? Colors.white : Colors.grey),
                              ),
                            );
                          },
                        )
                      ],
                    )
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String timeAgo(int timestamp) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

}