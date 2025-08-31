import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_analytics.dart';
import '../../core/utils.dart';
import '../../domain/entities/plan.dart';
import '../providers/plan_provider.dart';
import '../view/in_app_webview_screen.dart';
import '../view/plan_detail_screen.dart';

class PlanTile extends StatefulWidget {
  final Plan plan;
  final PlanProvider planProvider;
  final bool isExpanded;
  final bool isParent;
  final bool isCardView;

  const PlanTile({
    super.key,
    required this.plan,
    required this.planProvider,
    this.isExpanded = false,
    this.isParent = false,
    this.isCardView = false
  });

  @override
  State<PlanTile> createState() => _PlanTileState();
}

class _PlanTileState extends State<PlanTile> {
  @override
  void initState() {
    super.initState();
  }

  String _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      } else if (uri.host.contains('youtube.com') &&
          uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'] ?? '';
      }
    } catch (e) {
      debugPrint("Invalid URL: $e");
    }
    return '';
  }

  String getVideoUrlWithTimestamp(Plan plan) {
    if (plan.videos![0].url.isEmpty) return "";

    Uri uri = Uri.parse(plan.videos![0].url);
    String videoId = _extractYouTubeVideoId(plan.videos![0].url);

    if (videoId.isEmpty) {
      return plan.videos![0].url; // Return as-is if not a valid YouTube URL
    }

    // Append timestamp for different URL formats
    if (uri.host.contains('youtu.be')) {
      return 'https://youtu.be/$videoId?t=${plan.videos![0].timeInSeconds}';
    } else if (uri.host.contains('youtube.com')) {
      if (uri.path.contains('/embed/')) {
        return 'https://www.youtube.com/embed/$videoId?start=${plan.videos![0].timeInSeconds}';
      }
      return 'https://www.youtube.com/watch?v=$videoId&t=${plan.videos![0].timeInSeconds}';
    }

    return plan.videos![0].url; // Default fallback
  }

  Future<void> _openVideoInWebView(Plan plan, BuildContext context) async {
    if (Util.isYouTubeUrl(plan.videos![0].url)) {
      String url = getVideoUrlWithTimestamp(plan);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InAppWebViewScreen(url: url),
        ),
      );
    }
    else{
      final Uri uri = Uri.parse(plan.videos![0].url);
      if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not launch the URL')),
    );
    }
    }

  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Status'),
        children: [
          SimpleDialogOption(
            child: const Text('Neutral'),
            onPressed: () {
              widget.planProvider.updatePlanStatus(widget.plan, 'neutral');
              Navigator.pop(context);
            },
          ),
          SimpleDialogOption(
            child: const Text('Success'),
            onPressed: () {
              widget.planProvider.updatePlanStatus(widget.plan, 'success');
              Navigator.pop(context);
            },
          ),
          SimpleDialogOption(
            child: const Text('Failure'),
            onPressed: () {
              widget.planProvider.updatePlanStatus(widget.plan, 'failure');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void showUpdateNoteDialog(BuildContext context, String planId, String currentNote) {
    final TextEditingController _noteController = TextEditingController(text: currentNote);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Note'),
          content: TextFormField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter your updated note',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String newNote = _noteController.text.trim();
                if (newNote.isNotEmpty) {
                  await widget.planProvider.updatePlanNote(planId, newNote);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Note cannot be empty')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = widget.planProvider;
    return widget.isCardView ?
     Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      color: Colors.white,
      child:
      Column(
        children: [
          ListTile(
            tileColor: widget.isParent ? Colors.blue[50] : Colors.white,
            title: Row(
              children: [
                if(widget.isParent == false && widget.isCardView == false) ...[
                GestureDetector(
                  onTap: _showStatusDialog,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: widget.plan.status == 'neutral' ? Colors.yellow : widget.plan.status == 'success' ? Colors.green: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 4,),
                ],
                Expanded(
                  child: GestureDetector(
                    onLongPress: (){
                      widget.planProvider.enterSelectionMode(widget.plan.id);
                    },
                    onTap: (){
                      if (widget.planProvider.isSelectionMode) {
                        widget.planProvider.toggleSelection(widget.plan.id);
                      } else {
                        // normal tap behavior
                        AppAnalytics.logCardLinkClicked(widget.isParent ? 'child':'parent', widget.plan.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: widget.plan)),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        if (widget.planProvider.isSelectionMode)
                          Checkbox(
                            value: widget.planProvider.selectedPlanIds.contains(widget.plan.id),
                            onChanged: (bool? selected) {
                              widget.planProvider.toggleSelection(widget.plan.id);
                            },
                          ),
                        Expanded(
                          child: Text(
                            widget.plan.title,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: widget.isParent ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: widget.isParent ? Colors.black : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            trailing:
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.plan.videos!.isNotEmpty && widget.plan.videos![0].url.isNotEmpty
                    ? GestureDetector(
                    onTap: ()=> _openVideoInWebView(widget.plan,context),
                    child: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 28))
                    : widget.isParent
                    ? const Icon(Icons.account_tree, color: Colors.blue, size: 20)
                    : const Icon(Icons.subdirectory_arrow_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ],
      ),
    ):
    Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          ListTile(
            tileColor: widget.isParent ? Colors.blue[50] : Colors.white,
            title: Row(
              children: [
                if(widget.isParent == false) ...[
                  GestureDetector(
                    onTap: _showStatusDialog,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: widget.plan.status == 'neutral' ? Colors.yellow : widget.plan.status == 'success' ? Colors.green: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4,),
                ],
                Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.isParent ? const SizedBox.shrink():
                    Visibility(
                      visible: widget.plan.note.isNotEmpty,
                      child: Text(
                        widget.plan.note,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: (){

                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: widget.plan)),
                          );

                      },
                      child: Text(
                        widget.plan.title,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: widget.isParent ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: widget.isParent ? Colors.black : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),)
              ],
            ),
            trailing:
           widget.isParent ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.plan.videos!.isNotEmpty && widget.plan.videos![0].url.isNotEmpty
                    ? GestureDetector(
                    onTap: ()=> _openVideoInWebView(widget.plan,context),
                    child: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 28))
                    : widget.isParent
                    ? const Icon(Icons.account_tree, color: Colors.blue, size: 20)
                    : const Icon(Icons.subdirectory_arrow_right, color: Colors.grey, size: 20),
              ],
            ):GestureDetector(
               onTap: ()=>showUpdateNoteDialog(context, widget.plan.id, widget.plan.note),
               child: const Icon(Icons.edit, color: Colors.blue, size: 20)),
          ),
        ],
      ),
    );
  }
}
