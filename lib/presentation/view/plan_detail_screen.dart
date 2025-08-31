
import 'package:bjj_dairy/presentation/view/selected_plan_screen.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../core/app_analytics.dart';
import '../../core/app_strings.dart';
import '../../core/routes/routes_names.dart';
import '../../core/utils.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/video_entry.dart';
import '../providers/plan_provider.dart';
import '../providers/validation_provider.dart';
import '../widgets/add_image_card.dart';
import '../widgets/description_field.dart';
import '../widgets/expandable_description.dart';
import '../widgets/full_image_viewer_dialog.dart';
import '../widgets/title_input_field.dart';
import '../widgets/video_list_view.dart';
import 'in_app_webview_screen.dart';

class PlanDetailScreen extends StatefulWidget {
  final Plan plan;
  final bool isShared;

  const PlanDetailScreen(
      {super.key, required this.plan, this.isShared = false});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late YoutubePlayerController _youtubeController;
  bool _isValidYouTubeUrl = false;
  bool _isExpanded = false;
  Plan? plan;
  String? selectedImage;
  bool isEditing = false;
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];
  late List<String> _suggestedTags =
      []; //['submissions','escapes','pressure','defense];

  @override
  void initState() {
    super.initState();
    plan = widget.plan;
    print(widget.isShared);
    titleController = TextEditingController(text: plan!.title);
    descriptionController = TextEditingController(text: plan!.description);
    // _tags = plan!.tags;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<ValidationProvider>(context, listen: false).resetAll();
    });
    AppAnalytics.logCardViewed(plan!.id, plan!.title);
    _initYoutubeController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _toggleEdit(PlanProvider planProvider) async {
    if (isEditing) {
      // Handle save/submit
      final updatedTitle = titleController.text.trim();
      final updatedDescription = descriptionController.text.trim();
      plan!.title = updatedTitle;
      plan!.description = updatedDescription;
      plan!.images = planProvider.finalUploadImages;
      plan!.videos = planProvider.videoEntries;
      plan!.tags = _tags;
      final updatedPlan = await planProvider.updatedPlan(plan!);
      planProvider.resetUploadImages();
      setState(() {
        isEditing = false;
        plan = updatedPlan;
      });
    } else {
      _tags = plan!.tags;
      planProvider.setVideoEntries(plan!.videos ?? []);
      planProvider.setSelectedImages(plan!.images);
      setState(() {
        isEditing = true;
      });
    }
  }

  Future<void> _cancelEdit() async {
    setState(() {
      isEditing = false;
    });
  }

  void _initYoutubeController() {
    if (plan!.videos!.isEmpty) {
      return;
    }
    String videoId = YoutubePlayer.convertUrlToId(plan!.videos![0].url) ??
        ''; //_extractYouTubeVideoId(plan!.videoUrl);

    if (videoId.isNotEmpty) {
      _isValidYouTubeUrl = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          startAt: plan!.videos![0].timeInSeconds != null &&
                  plan!.videos![0].timeInSeconds! > 0
              ? plan!.videos![0].timeInSeconds!
              : 0,
        ),
      );
    }
  }

  String getVideoThumbnailUrl(String videoUrl) {
    final uri = Uri.parse(videoUrl);
    if (uri.host.contains('youtu.be')) {
      final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return videoId.isNotEmpty
          ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
          : '';
    } else if (uri.host.contains('youtube.com') &&
        uri.queryParameters.containsKey('v')) {
      final videoId = uri.queryParameters['v'];
      return videoId != null
          ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
          : '';
    }

    return ''; // fallback (invalid URL case)
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
      return 'https://youtu.be/$videoId?t=${plan..videos![0].timeInSeconds}';
    } else if (uri.host.contains('youtube.com')) {
      if (uri.path.contains('/embed/')) {
        return 'https://www.youtube.com/embed/$videoId?start=${plan.videos![0].timeInSeconds}';
      }
      return 'https://www.youtube.com/watch?v=$videoId&t=${plan.videos![0].timeInSeconds}';
    }

    return plan.videos![0].url; // Default fallback
  }

  String getVideoUrlWithTimestamp1(VideoEntry videoEntry) {
    if (videoEntry.url.isEmpty) return "";

    Uri uri = Uri.parse(videoEntry.url);
    String videoId = _extractYouTubeVideoId(videoEntry.url);

    if (videoId.isEmpty) {
      return videoEntry.url; // Return as-is if not a valid YouTube URL
    }

    // Append timestamp for different URL formats
    if (uri.host.contains('youtu.be')) {
      return 'https://youtu.be/$videoId?t=${videoEntry.timeInSeconds}';
    } else if (uri.host.contains('youtube.com')) {
      if (uri.path.contains('/embed/')) {
        return 'https://www.youtube.com/embed/$videoId?start=${videoEntry.timeInSeconds}';
      }
      return 'https://www.youtube.com/watch?v=$videoId&t=${videoEntry.timeInSeconds}';
    }

    return videoEntry.url; // Default fallback
  }

  void _openVideoInWebView(Plan plan, BuildContext context) {
    String url = getVideoUrlWithTimestamp(plan);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InAppWebViewScreen(url: url),
      ),
    );
  }

  Future<void> _openVideo(VideoEntry videoEntry, BuildContext context) async {
    if (Util.isYouTubeUrl(videoEntry.url)) {
      String url = getVideoUrlWithTimestamp1(videoEntry);
      AppAnalytics.logCardVideoPlayed(videoEntry.title, videoEntry.url);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InAppWebViewScreen(url: url),
        ),
      );
    } else {
      final Uri uri = Uri.parse(videoEntry.url);
      if (await canLaunchUrl(uri)) {
        AppAnalytics.logCardVideoPlayed(videoEntry.title, videoEntry.url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.couldNotLaunch)),
        );
      }
    }
  }

  Widget _buildLinksItemCard(
      Plan plan, BuildContext context, PlanProvider planProvider,String parentId,bool isParent) {
    return GestureDetector(
      onTap: (widget.isShared || widget.plan.isShared) &&
              widget.plan.folderId.isNotEmpty &&
              widget.plan.folderId != plan.folderId
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanDetailScreen(plan: plan),
                ),
              );
            },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => showStatusOptions(context, plan, planProvider),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: plan.status == 'neutral'
                        ? Colors.yellow
                        : plan.status == 'success'
                            ? Colors.green
                            : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    if (plan.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        plan.note,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.black),
                      )
                    ],
                    if ((widget.isShared || widget.plan.isShared) &&
                        widget.plan.folderId.isNotEmpty &&
                        widget.plan.folderId != plan.folderId) ...[
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        AppStrings.techniqueNotAvailable,
                        style: TextStyle(
                            color: Colors.red, fontStyle: FontStyle.italic),
                      )
                    ]
                  ],
                ),
              ),
              // const Icon(Icons.chevron_right, color: Colors.grey),
              Row(
                children: [
                  GestureDetector(
                      onTap: (widget.isShared || widget.plan.isShared) &&
                              widget.plan.folderId.isNotEmpty &&
                              widget.plan.folderId != plan.folderId
                          ? null
                          : () => showUpdateNoteBottomSheet(
                              context, plan.id, plan.note, planProvider),
                      child: widget.isShared ? const SizedBox.shrink(): Icon(Icons.edit,
                          color: Theme.of(context).primaryColor, size: 20)),
                  const SizedBox(width: 12,),
                  GestureDetector(
                      onTap: (){
                        print('remove link called');
                        if(isParent){
                          planProvider.removeLink(parentId: plan.id, childId: parentId);
                        }
                        else{
                          planProvider.removeLink(parentId: parentId, childId: plan.id);
                        }

                      },
                      child: widget.isShared ? const SizedBox.shrink(): Icon(Icons.remove_circle_outline,
                          color: Colors.red, size: 20)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showUpdateNoteBottomSheet(
    BuildContext context,
    String planId,
    String currentNote,
    PlanProvider planProvider,
  ) {
    final TextEditingController _noteController =
        TextEditingController(text: currentNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // for keyboard push-up
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // for keyboard
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.updateNoteTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: AppStrings.updateNoteLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppStrings.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        String newNote = _noteController.text.trim();
                        if (newNote.isNotEmpty) {
                          await planProvider.updatePlanNote(planId, newNote);
                          Navigator.of(context).pop();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppStrings.updateNoteEmptyError)),
                          );
                        }
                      },
                      child: Text(AppStrings.save),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void showAddVideosBottomSheet(
      BuildContext context, PlanProvider provider, Plan plan) {
    String errorMessage = '';
    // if (provider.videoEntries.isEmpty) {
    provider.addVideoEntry(VideoEntry(
        title: '',
        url: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isYoutubeUrl: false));
    // }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: const Text(
                        AppStrings.addVideosTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: List.generate(
                            provider.videoEntries.length,
                            (index) {
                              final entry = provider.videoEntries[index];

                              final minutesController = TextEditingController(
                                  text: entry.timeInSeconds != null
                                      ? (entry.timeInSeconds! ~/ 60).toString()
                                      : '');
                              final secondsController = TextEditingController(
                                  text: entry.timeInSeconds != null
                                      ? (entry.timeInSeconds! % 60).toString()
                                      : '');
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade300,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10.0, horizontal: 8.0),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade200,
                                        border: Border.all(
                                            color: Colors.grey.shade100),
                                      ),
                                      child: TextFormField(
                                        initialValue: entry.url,
                                        decoration:
                                            _bottomSheetInputDecoration(AppStrings.url),
                                        onChanged: (value) {
                                          final currentEntry = provider
                                                  .videoEntries[
                                              index]; // get the latest entry
                                          final isYoutube =
                                              Util.isYouTubeUrl(value);
                                          provider.updateVideoEntry(
                                            index,
                                            currentEntry.copyWith(
                                                url: value,
                                                isYoutubeUrl: isYoutube),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade200,
                                        border: Border.all(
                                            color: Colors.grey.shade100),
                                      ),
                                      child: TextFormField(
                                        initialValue: entry.title,
                                        decoration: _bottomSheetInputDecoration(
                                            AppStrings.videoTitle),
                                        onChanged: (value) {
                                          // provider.updateVideoEntry(index, entry.copyWith(title: value));
                                          final currentEntry = provider
                                                  .videoEntries[
                                              index]; // get the latest entry
                                          provider.updateVideoEntry(
                                              index,
                                              currentEntry.copyWith(
                                                  title: value));
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    entry.isYoutubeUrl
                                        ? Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    color: Colors.grey.shade200,
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade100),
                                                  ),
                                                  child: TextFormField(
                                                    initialValue: entry
                                                                .timeInSeconds !=
                                                            null
                                                        ? (entry.timeInSeconds! ~/
                                                                60)
                                                            .toString()
                                                        : '',
                                                    decoration: InputDecoration(
                                                        hintText: AppStrings.minutes,
                                                        border: InputBorder.none
                                                        ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged: (value) {
                                                      final currentEntry =
                                                          provider.videoEntries[
                                                              index];
                                                      final minutes =
                                                          int.tryParse(value) ??
                                                              0;
                                                      final seconds = int.tryParse(
                                                              secondsController
                                                                  .text) ??
                                                          0;
                                                      provider.updateVideoEntry(
                                                        index,
                                                        currentEntry.copyWith(
                                                            timeInSeconds:
                                                                (minutes * 60) +
                                                                    seconds),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    color: Colors.grey.shade200,
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade100),
                                                  ),
                                                  child: TextFormField(
                                                    initialValue: entry
                                                                .timeInSeconds !=
                                                            null
                                                        ? (entry.timeInSeconds! %
                                                                60)
                                                            .toString()
                                                        : '',
                                                    decoration: InputDecoration(
                                                        hintText: AppStrings.seconds,
                                                        border: InputBorder.none
                                                        ),
                                                    keyboardType:
                                                        TextInputType.number,
                                                    onChanged: (value) {
                                                      final currentEntry =
                                                          provider.videoEntries[
                                                              index];
                                                      final minutes = int.tryParse(
                                                              minutesController
                                                                  .text) ??
                                                          0;
                                                      final seconds =
                                                          int.tryParse(value) ??
                                                              0;
                                                      provider.updateVideoEntry(
                                                        index,
                                                        currentEntry.copyWith(
                                                            timeInSeconds:
                                                                (minutes * 60) +
                                                                    seconds),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () {
                                          provider.removeVideoEntry(index);
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        label: const Text(
                                          AppStrings.remove,
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          provider.addVideoEntry(
                            VideoEntry(
                              title: '',
                              url: '',
                              timestamp: DateTime.now().millisecondsSinceEpoch,
                              type: '',
                              isYoutubeUrl: false,
                            ),
                          );
                        });
                      },
                      icon: Icon(Icons.add,
                          color: Theme.of(context).primaryColor),
                      label: Text(
                        AppStrings.addAnotherVideoLabel,
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      style: TextButton.styleFrom(
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (errorMessage.isNotEmpty) ...[
                      Divider(height: 1, color: Colors.grey.shade300),
                      Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Divider(height: 1, color: Colors.grey.shade300),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              provider.resetVideoEntries();
                              setState(() {
                                errorMessage = '';
                              });
                            },
                            child: const Text(AppStrings.cancel,
                                style: TextStyle(color: Colors.red)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (provider.videoEntries
                                  .any((video) => video.url.isEmpty)) {

                                setState(() {
                                  errorMessage =
                                      AppStrings.videoUrlEmptyError;
                                });
                                return;
                              }
                              if (provider.videoEntries.any((video) =>
                                  !Util.isValidVideoUrl(video.url))) {

                                setState(() {
                                  errorMessage =
                                      AppStrings.videoUrlInvalidError;
                                });
                                return;
                              }
                              Navigator.pop(context);
                              plan.videos = [
                                ...plan.videos!,
                                ...provider.videoEntries
                              ];
                              provider.updatePlan(plan);
                            },
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                            child: const Text(AppStrings.submit),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _bottomSheetInputDecoration(String hintText) {
    return InputDecoration(hintText: hintText, border: InputBorder.none
        );
  }

  Future<void> _addTag(String value, BuildContext context) async {
    final tag = value.trim();
    if (tag.isNotEmpty) {
      await Provider.of<ValidationProvider>(context, listen: false)
          .validateTags(_tags, tag);
      if (Provider.of<ValidationProvider>(context, listen: false).tagsError ==
          null) {
        setState(() {
          _tags.add(tag);
          _suggestedTags.remove(tag);
          _tagController.clear();
        });
      }
    }
  }

  Widget _buildTagsInput(BuildContext context) {
    final allTags = Provider.of<PlanProvider>(context, listen: false).allTags;
    _suggestedTags =
        allTags.where((tag) => !_tags.contains(tag)).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row with icon and text
        Row(
          children: [
            Icon(Icons.local_offer_outlined,
                size: 16, color: Theme.of(context).primaryColor),
            SizedBox(width: 4),
            Text(
              AppStrings.tags,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Suggested tags
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedTags
                .where((suggestion) => suggestion.toLowerCase() != 'all')
                .map((suggestion) {
              return ActionChip(
                label: Text(
                  suggestion,
                  style: const TextStyle(fontSize: 13),
                ),
                backgroundColor: Colors.white,
                shape: StadiumBorder(
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
                onPressed: () async {
                  if (!_tags.contains(suggestion)) {
                    await Provider.of<ValidationProvider>(context,
                            listen: false)
                        .validateTags(_tags, suggestion);
                    if (Provider.of<ValidationProvider>(context, listen: false)
                            .tagsError ==
                        null) {
                      setState(() {
                        _tags.add(suggestion);
                        _suggestedTags.remove(suggestion);
                      });
                    }
                  }
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        // Input + Add button
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade300,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<ValidationProvider>(
                  builder: (context, validator, child) {
                    return TextFormField(
                      controller: _tagController,
                      // onChanged: (value) {
                      //   validator.validateTag(value); // validate on change
                      // },
                      decoration: InputDecoration(
                        hintText: AppStrings.addCustomTagsLabel,
                        border: InputBorder.none,
                        errorText: validator.tagsError,
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _addTag(_tagController.text, context),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(14),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Selected tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tags.map((tag) {
            return Chip(
              label: Text(
                tag,
                style: const TextStyle(fontSize: 13),
              ),
              shape: StadiumBorder(
                side: BorderSide(color: Theme.of(context).primaryColor),
              ),
              backgroundColor: Colors.white,
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () async {
                setState(() {
                  _tags.remove(tag);
                  if (!_suggestedTags.contains(tag)) {
                    _suggestedTags.add(tag);
                  }
                });
                await Provider.of<ValidationProvider>(context, listen: false)
                    .validateTags(_tags, tag);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void showAddLinksOptions(
      BuildContext context, Plan plan, PlanProvider planProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.only(top: 12.0, left: 16, right: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar with close icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24), // Placeholder to center title
                  const Text(
                    AppStrings.optionsTitle,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.checklist_outlined,
                ),
                title: const Text(AppStrings.chooseExistingLabel),
                onTap: () async {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectPlanScreen(
                        planId: plan.id,
                        isParent: false,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.new_label_outlined,
                ),
                title: const Text(AppStrings.createNewLabel),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, RoutesNames.addPlanScreen,
                      arguments: {
                        "parentId": plan.id,
                        "isConnection": true,
                        "folderId": ""
                      });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void showStatusOptions(
      BuildContext context, Plan plan, PlanProvider planProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding:
              const EdgeInsets.only(top: 12.0, left: 16, right: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top bar with close icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24), // Placeholder to center title
                  const Text(
                    AppStrings.selectStatusLabel,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                ),
                title: const Text(AppStrings.neutralStatusLabel),
                onTap: () async {
                  planProvider.updatePlanStatus(plan, 'neutral');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                title: const Text(AppStrings.successStatusLabel),
                onTap: () async {
                  planProvider.updatePlanStatus(plan, 'success');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                title: const Text(AppStrings.failureStatusLabel),
                onTap: () async {
                  planProvider.updatePlanStatus(plan, 'failure');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoEntry(
      BuildContext context, PlanProvider provider, int index) {
    final entry = provider.videoEntries[index];

    final minutesController = TextEditingController(
        text: entry.timeInSeconds != null
            ? (entry.timeInSeconds! ~/ 60).toString()
            : '');
    final secondsController = TextEditingController(
        text: entry.timeInSeconds != null
            ? (entry.timeInSeconds! % 60).toString()
            : '');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Consumer<ValidationProvider>(
              builder: (context, validator, _) {
                return TextFormField(
                  initialValue: entry.url,
                  decoration: InputDecoration(
                    hintText: AppStrings.url,
                    border: InputBorder.none,
                    errorText: validator.urlError,
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    validator.validUrl(value);
                    if (validator.urlError == null) {
                      final isYoutube = Util.isYouTubeUrl(value);
                      provider.updateVideoEntry(
                        index,
                        entry.copyWith(url: value, isYoutubeUrl: isYoutube),
                      );
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade200,
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Consumer<ValidationProvider>(
              builder: (context, validator, _) {
                return TextFormField(
                  initialValue: entry.title,
                  decoration: InputDecoration(
                    hintText: AppStrings.videoTitle,
                    border: InputBorder.none,
                    errorText: validator.videoTitleError,
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    validator.validateVideoTitle(value);
                    if (validator.videoTitleError == null) {
                      provider.updateVideoEntry(
                          index, entry.copyWith(title: value));
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          entry.isYoutubeUrl || Util.isYouTubeUrl(entry.url)
              ? Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: TextFormField(
                          initialValue: entry.timeInSeconds != null
                              ? (entry.timeInSeconds! ~/ 60).toString()
                              : '',
                          decoration: InputDecoration(
                            hintText: AppStrings.minutes,
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final minutes = int.tryParse(value) ?? 0;
                            final seconds =
                                int.tryParse(secondsController.text) ?? 0;
                            provider.updateVideoEntry(
                              index,
                              entry.copyWith(
                                  timeInSeconds: (minutes * 60) + seconds),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: TextFormField(
                          initialValue: entry.timeInSeconds != null
                              ? (entry.timeInSeconds! % 60).toString()
                              : '',
                          decoration: InputDecoration(
                            hintText: AppStrings.seconds,
                            border: InputBorder.none,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final minutes =
                                int.tryParse(minutesController.text) ?? 0;
                            final seconds = int.tryParse(value) ?? 0;
                            provider.updateVideoEntry(
                              index,
                              entry.copyWith(
                                  timeInSeconds: (minutes * 60) + seconds),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => provider.removeVideoEntry(index),
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                AppStrings.remove,
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentBottomSheet(BuildContext context, PlanProvider planProvider,
      Plan plan, String userId) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: 500,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    AppStrings.commentsTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // Real-time Comment List
                Expanded(
                  child: StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance
                        .ref('PLANS/${plan.id}/comments')
                        .orderByChild('timestamp')
                        .onValue,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.snapshot.value == null) {
                        return const Center(child: Text(AppStrings.commentsListEmptyMessage));
                      }

                      final rawComments = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map);
                      final comments = rawComments.entries.map((entry) {
                        final data = Map<String, dynamic>.from(entry.value);
                        return Comment.fromMap(data);
                      }).toList()
                        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return ListTile(
                            leading: const Icon(Icons.person),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(comment.userId),
                                const SizedBox(
                                  width: 2,
                                ),
                                Text('(${Util.timeAgo(comment.timestamp)})',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey))
                              ],
                            ),
                            subtitle: Text(
                              comment.text,
                              style: TextStyle(fontSize: 18),
                            ),
                            trailing: plan.userId == planProvider.loggedUserId
                                ? IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      planProvider.deleteComment(
                                          plan.id, comment.id);
                                    },
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(height: 1),

                // Comment Input
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: const InputDecoration(
                            hintText: AppStrings.commentTypeHint,
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () async {
                          final text = commentController.text.trim();
                          if (text.isNotEmpty) {
                            planProvider.addComment(plan.id, userId, '', text,
                                isShared: widget.isShared);
                            commentController.clear();
                          }
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = Provider.of<PlanProvider>(context, listen: true);

    List<Plan> parentPlans = planProvider.getParentPlans(
        plan!.id, (widget.isShared || widget.plan.isShared))
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)) // Sort by timestamp
      ..forEach((plan) => plan.isExpanded = false); // Reset isExpanded

    List<Plan> childPlans = planProvider.getChildPlans(
        plan!.id, (widget.isShared || widget.plan.isShared))
      ..sort((a, b) =>
          b.timestamp.compareTo(a.timestamp)) // Sort children by timestamp
      ..forEach((plan) => plan.isExpanded = false); // Reset isExpanded

    return WillPopScope(
      onWillPop: () async {
        planProvider.resetVideoEntries();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.detailsTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (isEditing) ...[
                            Consumer<ValidationProvider>(
                              builder: (context, provider, child) {
                                return IconButton(
                                  icon: Icon(Icons.check,
                                      color: provider.titleError == null
                                          ? Colors.green
                                          : Colors.grey),
                                  onPressed: (provider.titleError == null)
                                      ? () {
                                          // Save or confirm action
                                          _toggleEdit(
                                              planProvider); // or call save method
                                        }
                                      : null,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                // Cancel edit
                                _cancelEdit(); // implement this to reset changes
                              },
                            ),
                          ] else ...[
                            widget.isShared
                                ? const SizedBox.shrink()
                                : IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.black),
                                    onPressed: () {
                                      if (!widget.isShared) {
                                        _toggleEdit(planProvider);
                                      }
                                    },
                                  ),
                          ],
                        ],
                      )
                    ],
                  ),
                ),
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildTagsInput(context),
                  ),
                if (plan!.tags.isNotEmpty && !isEditing)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: -8,
                        children: plan!.tags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        width: 1,
                                        color: Theme.of(context).primaryColor),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: isEditing
                        ? TitleInputField(controller: titleController)
                        : Text(
                            plan!.title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if(widget.isShared)
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(AppStrings.disableEditModeError,style: TextStyle(color: Colors.red,fontSize: 18),),),
                if (plan!.description.isNotEmpty || isEditing)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: isEditing
                          ? DescriptionField(
                              initialDescription: descriptionController.text,
                              onChanged: (description) {
                                descriptionController.text = description;
                              },
                            )
                          : ExpandableDescription(
                              description: plan!.description),
                    ),
                  ),
                if (isEditing) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.videocam,
                            size: 18, color: Theme.of(context).primaryColor),
                        SizedBox(width: 6),
                        Text(
                          AppStrings.videoLinksTitle,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer<PlanProvider>(
                          builder: (context, planProvider, _) {
                            final videoEntries = planProvider.videoEntries;
                            return Column(
                              children:
                                  List.generate(videoEntries.length, (index) {
                                return KeyedSubtree(
                                  key: ValueKey(index),
                                  child: _buildVideoEntry(
                                      context, planProvider, index),
                                );
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: () {
                            if (widget.isShared || plan!.isShared) {
                              return;
                            }
                            planProvider.addVideoEntry(VideoEntry(
                                title: '',
                                url: '',
                                timestamp:
                                    DateTime.now().millisecondsSinceEpoch,
                                isYoutubeUrl: false));
                          },
                          icon: Icon(Icons.add,
                              color: Theme.of(context).primaryColor),
                          label: Text(
                            AppStrings.addAnotherVideoLabel,
                            style: TextStyle(
                                color: Theme.of(context).primaryColor),
                          ),
                          style: TextButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                ],
                if (!isEditing)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppStrings.videosLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '${plan!.videos!.length} ${AppStrings.videosLabel}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Column(
                          children: [
                            SizedBox(
                              height: plan!.videos!.isEmpty
                                  ? 0
                                  : plan!.videos!.length == 1
                                      ? 80
                                      : 130,
                              child: VideoListView(
                                videos: plan!.videos!
                                  ..sort((a, b) =>
                                      b.timestamp.compareTo(a.timestamp)),
                                onAddVideo: () {},
                                onPlayVideo: (video) =>
                                    _openVideo(video, context),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            widget.isShared
                                ? const SizedBox.shrink()
                                : GestureDetector(
                                    onTap: () {
                                      print('Add Video tapped');
                                      if (widget.isShared || plan!.isShared) {
                                        return;
                                      }
                                      showAddVideosBottomSheet(
                                          context, planProvider, plan!);
                                    },
                                    child: DottedBorder(
                                      color: Colors.grey,
                                      borderType: BorderType.RRect,
                                      radius: const Radius.circular(12),
                                      dashPattern: [6, 3],
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        alignment: Alignment.center,
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, color: Colors.grey),
                                            SizedBox(width: 8),
                                            Text(
                                              AppStrings.addVideoLabel,
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        )
                      ],
                    ),
                  ),
                if (isEditing) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 18, color: Theme.of(context).primaryColor),
                        SizedBox(width: 6),
                        Text(
                         AppStrings.imagesTitle,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 4),
                        Text(
                          AppStrings.optionalLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // + Button to pick images
                        TextButton.icon(
                          onPressed: () {
                            if (widget.isShared || plan!.isShared) {
                              return;
                            }
                            planProvider.pickImages();
                          },
                          icon: Icon(Icons.upload_outlined,
                              color: Theme.of(context).primaryColor),
                          label: Text(
                            AppStrings.uploadImageLabel,
                            style: TextStyle(
                                color: Theme.of(context).primaryColor),
                          ),
                          style: TextButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).primaryColor),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Show selected images horizontally
                        if (planProvider.selectedImages.isNotEmpty)
                          SizedBox(
                            height: 100, // Adjust height as needed
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: planProvider.selectedImages.length,
                              itemBuilder: (context, index) {
                                final selectedImage =
                                    planProvider.selectedImages[index];
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: selectedImage.isLocal
                                            ? Image.file(
                                                selectedImage.localFile!,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                selectedImage.url!,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    width: 100,
                                                    height: 100,
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                        Icons.error,
                                                        color: Colors.red),
                                                  );
                                                },
                                              ),
                                      ),
                                    ),
                                    // Remove button
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          planProvider
                                              .removeSelectedImage(index);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        const SizedBox(
                          height: 4,
                        ),
                        Consumer<ValidationProvider>(
                          builder: (context, validationProvider, child) {
                            return validationProvider.imagesError != null
                                ? Text(
                                    validationProvider.imagesError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 14),
                                  )
                                : const SizedBox
                                    .shrink(); // returns nothing if no error
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                ],
                if (!isEditing)
                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.white,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.imagesTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        SizedBox(
                          height: 180, // Adjust height as needed
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: plan!.images.length + 1,
                            itemBuilder: (context, index) {
                              if (index < plan!.images.length) {
                                final image = plan!.images[index];
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          FullImageViewerDialog(
                                              imageUrl: image),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        image,
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            width: 150,
                                            height: 150,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 150,
                                            height: 150,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error,
                                                color: Colors.red),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return widget.isShared ? const SizedBox.shrink() :
                                 planProvider.isLoading
                                    ? SizedBox(
                                        width: 100,
                                        height: 100,
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      )
                                    : AddImageCard(onTap: () async {
                                        if (widget.isShared || plan!.isShared) {
                                          return;
                                        }
                                        final updatedPlan = await planProvider
                                            .pickAndUploadImages(plan);
                                        setState(() {
                                          plan = updatedPlan;
                                        });
                                      });
                              }
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Consumer<ValidationProvider>(
                          builder: (context, validationProvider, child) {
                            return validationProvider.imagesError != null
                                ? Text(
                                    validationProvider.imagesError!,
                                    style: const TextStyle(
                                        color: Colors.red, fontSize: 14),
                                  )
                                : const SizedBox
                                    .shrink(); // returns nothing if no error
                          },
                        ),
                      ],
                    ),
                  ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.linkedPositionsTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(AppStrings.linkedPositionsParentHint,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: parentPlans.isEmpty
                                ? 50
                                : parentPlans.length == 1
                                    ? 100
                                    : parentPlans.length == 2
                                        ? 200
                                        : 300,
                            // or any height depending on how many items you want to show
                            child: parentPlans.isEmpty
                                ? ListView(
                                    children: [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          child: Text(
                                            AppStrings.linkedPositionsParentListEmpty,
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    itemCount: parentPlans.length,
                                    itemBuilder: (context, index) {
                                      return _buildLinksItemCard(
                                          parentPlans[index],
                                          context,
                                          planProvider,widget.plan.id,true);
                                    },
                                  ),
                          ),
                          // Add Button for Parent
                         widget.isShared ? const SizedBox.shrink(): Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () {
                                if (widget.isShared || plan!.isShared) {
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SelectPlanScreen(
                                      planId: plan!.id,
                                      isParent: true,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.add,
                                        color: Theme.of(context).primaryColor),
                                    SizedBox(width: 4),
                                    Text(AppStrings.addLabel,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .primaryColor)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text(AppStrings.linkedPositionsChildHint,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: childPlans.isEmpty
                                ? 50
                                : childPlans.length == 1
                                    ? 100
                                    : childPlans.length == 2
                                        ? 200
                                        : 300,
                            // or any height depending on how many items you want to show
                            child: childPlans.isEmpty
                                ? ListView(
                                    children: [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          child: Text(
                                            AppStrings.linkedPositionsChildListEmpty,
                                            style:
                                                TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    itemCount: childPlans.length,
                                    itemBuilder: (context, index) {
                                      return _buildLinksItemCard(
                                        childPlans[index],
                                        context,
                                        planProvider,
                                        widget.plan.id,
                                        false
                                      );
                                    },
                                  ),
                          ),
                          // Add Button for Child
                          widget.isShared ? const SizedBox.shrink(): Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () {
                                if (widget.isShared || plan!.isShared) {
                                  return;
                                }
                                showAddLinksOptions(
                                    context, widget.plan, planProvider);
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.add,
                                        color: Theme.of(context).primaryColor),
                                    SizedBox(width: 4),
                                    Text(AppStrings.addLabel,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .primaryColor)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Like Button
                    TextButton.icon(
                      onPressed: () {
                        if (!plan!.likedBy
                            .contains(planProvider.loggedUserId)) {
                          planProvider.likePlan(
                              plan!.id, planProvider.loggedUserId,
                              isShared: widget.isShared);
                        }
                      },
                      icon: Icon(
                        plan!.likedBy.contains(planProvider.loggedUserId)
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        color: Colors.blue,
                      ),
                      label: Text('${plan!.likedBy.length} ${AppStrings.likeLabel}'),
                    ),

                    // Favourite Button
                    TextButton.icon(
                      onPressed: () {
                        if (widget.isShared ||
                            plan!.userId != planProvider.loggedUserId) {
                          planProvider.toggleFavourite(plan!.id,
                              planProvider.loggedUserId, widget.isShared);
                        }
                      },
                      icon: Icon(
                        plan!.favouritedBy.contains(planProvider.loggedUserId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      label: Text(AppStrings.favouriteLabel),
                    ),

                    // Comment Button
                    TextButton.icon(
                      onPressed: () {
                        _showCommentBottomSheet(context, planProvider, plan!,
                            planProvider.loggedUserId);
                      },
                      icon: const Icon(Icons.comment, color: Colors.green),
                      label: const Text(AppStrings.commentLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
