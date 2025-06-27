import 'dart:io';

import 'package:bjj_dairy/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/plan.dart';
import '../model/video_entry.dart';
import '../providers/plan_provider.dart';
import '../providers/validation_provider.dart';
import '../utils/utils.dart';
import '../widgets/description_field.dart';
import '../widgets/title_input_field.dart';

class EditPlanScreen extends StatefulWidget {
  final Plan plan;

  const EditPlanScreen({super.key, required this.plan});

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Plan? plan;
  final TextEditingController _tagController = TextEditingController();
  List<String> _tags = [];
  late List<String> _suggestedTags =
      []; //['submissions','escapes','pressure','defense];

  @override
  void initState() {
    super.initState();
    plan = widget.plan;
    _titleController.text = plan!.title;
    _descriptionController.text = plan!.description;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<ValidationProvider>(context, listen: false).resetAll();
      Provider.of<PlanProvider>(context, listen: false)
          .setVideoEntries(plan!.videos ?? []);
      Provider.of<PlanProvider>(context, listen: false)
          .setSelectedImages(plan!.images);
    });
    _tags = plan!.tags;
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
            child:
            Consumer<ValidationProvider>(
              builder: (context, validator, _) {
                return TextFormField(
                  initialValue: entry.url,
                  decoration: InputDecoration(
                    hintText: 'URL',
                    border: InputBorder.none,
                    errorText: validator.urlError,
                    // Uncomment and customize borders as needed
                    // filled: true,
                    // fillColor: Colors.white,
                    // border: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(8),
                    //   borderSide: BorderSide(color: Colors.grey.shade300),
                    // ),
                    // enabledBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(8),
                    //   borderSide: BorderSide(color: Colors.grey.shade300),
                    // ),
                    // focusedBorder: OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(8),
                    //   borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                    // ),
                    errorBorder: OutlineInputBorder(
                      // borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      // borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    validator.validUrl(value);
                    if(validator.urlError == null)
                    {
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
                    hintText: 'Video Title',
                    border: InputBorder.none,
                    errorText: validator.videoTitleError,
                    errorBorder: OutlineInputBorder(
                      // borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      // borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    validator.validateVideoTitle(value);
                    if(validator.videoTitleError == null){
                      provider.updateVideoEntry(index, entry.copyWith(title: value));
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
                      hintText: 'Minutes',
                      border: InputBorder.none,
                      // filled: true,
                      // fillColor: Colors.white,
                      // border: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   borderSide: BorderSide(color: Colors.grey.shade300),
                      // ),
                      // enabledBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   borderSide: BorderSide(color: Colors.grey.shade300),
                      // ),
                      // focusedBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                      // ),
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
                      hintText: 'Seconds',
                      border: InputBorder.none,
                      // filled: true,
                      // fillColor: Colors.white,
                      // border: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   borderSide: BorderSide(color: Colors.grey.shade300),
                      // ),
                      // enabledBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   borderSide: BorderSide(color: Colors.grey.shade300),
                      // ),
                      // focusedBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
                      // ),
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
                "Remove",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
          // const SizedBox(height: 12),
          // DropdownButtonFormField<String>(
          //   value: entry.type ?? "Explanation",
          //   decoration: InputDecoration(
          //     filled: true,
          //     fillColor: Colors.grey.shade100,
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(8),
          //       borderSide: BorderSide(color: Colors.grey.shade300),
          //     ),
          //   ),
          //   items: ['Explanation', 'Demo', 'Tutorial'].map((type) {
          //     return DropdownMenuItem(
          //       value: type,
          //       child: Text(type),
          //     );
          //   }).toList(),
          //   onChanged: (value) {
          //     provider.updateVideoEntry(index, entry.copyWith(type: value));
          //   },
          // ),
          // const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _addTag(String value, BuildContext context) async {
    final tag = value.trim();
    if (tag.isNotEmpty ) {
      await Provider.of<ValidationProvider>(context, listen: false)
          .validateTags(_tags,tag);
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
    // _suggestedTags
    //     .addAll(Provider.of<PlanProvider>(context, listen: false).allTags);
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
              'Tags',
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
                        .validateTags(_tags,suggestion);
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
                        hintText: 'Add custom tag',
                        border: InputBorder.none,
                        // filled: true,
                        // fillColor: Colors.grey[200],
                        // border: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(30),
                        //   borderSide: BorderSide.none,
                        // ),
                        // focusedBorder: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(30),
                        //   borderSide: BorderSide(color: Colors.blue, width: 2),
                        // ),
                        errorText: validator.tagsError,
                        errorBorder: OutlineInputBorder(
                          // borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          // borderRadius: BorderRadius.circular(30),
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
                await Provider.of<ValidationProvider>(context,
                    listen: false)
                    .validateTags(_tags,tag);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = Provider.of<PlanProvider>(context);
    final validationProvider = Provider.of<ValidationProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        planProvider.resetVideoEntries();
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        // appBar: AppBar(title: const Text('Update Plan')),
        body: SafeArea(
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
                        'Update Technique',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    planProvider.isLoading
                        ? CircularProgressIndicator()
                        : PrimaryButton(
                            text: 'Update',
                            width: 100,
                            onPressed: (_titleController.text.isNotEmpty &&
                                validationProvider.titleError == null)
                                ? () async {
                              if (_titleController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Title field is required!')),
                                );
                                return;
                              }

                              // if (planProvider.videoEntries
                              //     .any((video) => video.title.isEmpty)) {
                              //   ScaffoldMessenger.of(context).showSnackBar(
                              //     const SnackBar(
                              //         content: Text('Video Title is required!')),
                              //   );
                              //   return;
                              // }

                              if (planProvider.videoEntries.any((video) =>
                                  !Util.isValidVideoUrl(video.url))) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'One or more video URLs are invalid')),
                                );
                                return;
                              }
                              Plan updatePlan = Plan(
                                  id: plan!.id,
                                  userId: plan!.userId,
                                  title: _titleController.text,
                                  description: _descriptionController.text,
                                  tags: _tags,
                                  folderId: plan!.folderId,
                                  videos: planProvider.videoEntries,
                                  timestamp: plan!.timestamp);
                              await planProvider.updatePlan(updatePlan);
                              Future.delayed(const Duration(seconds: 1), () {
                                updatePlan.images =
                                    planProvider.finalUploadImages;
                                planProvider.resetUploadImages();
                                Navigator.pop(context, updatePlan);
                              });
                            }:null,
                          ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TitleInputField(controller: _titleController),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildTagsInput(context),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: DescriptionField(
                          initialDescription: widget.plan.description,
                          onChanged: (description) {
                            _descriptionController.text = description;
                          },
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(Icons.videocam,
                                size: 18,
                                color: Theme.of(context).primaryColor),
                            SizedBox(width: 6),
                            Text(
                              "Video Links",
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
                                  children: List.generate(videoEntries.length, (index) {
                                    return KeyedSubtree(
                                      key: ValueKey(index),
                                      child: _buildVideoEntry(context, planProvider, index),
                                    );
                                  }),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () {
                                planProvider.addVideoEntry(VideoEntry(
                                    title: '', url: '',timestamp: DateTime.now().millisecondsSinceEpoch, isYoutubeUrl: false));
                              },
                              icon: Icon(Icons.add,
                                  color: Theme.of(context).primaryColor),
                              label: Text(
                                'Add Another Video',
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
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(Icons.photo_library_outlined,
                                size: 18,
                                color: Theme.of(context).primaryColor),
                            SizedBox(width: 6),
                            Text(
                              "Images",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 4),
                            Text(
                              "(optional)",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey),
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
                                planProvider.pickImages();
                              },
                              icon: Icon(Icons.upload_outlined,
                                  color: Theme.of(context).primaryColor),
                              label: Text(
                                'Upload Image',
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
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
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
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Container(
                                                        width: 100,
                                                        height: 100,
                                                        color: Colors.grey[300],
                                                        child: const Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
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
                            const SizedBox(height: 4,),
                            Consumer<ValidationProvider>(
                              builder: (context, validationProvider, child) {
                                return validationProvider.imagesError != null
                                    ? Text(
                                  validationProvider.imagesError!,
                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                )
                                    : const SizedBox.shrink(); // returns nothing if no error
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: planProvider.isLoading
                            ? Center(child: CircularProgressIndicator())
                            : PrimaryButton(
                                text: 'Update Technique',
                                onPressed: (_titleController.text.isNotEmpty &&
                                    validationProvider.titleError == null)
                                    ? () async {
                                  if (_titleController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Title field is required!')),
                                    );
                                    return;
                                  }

                                  // if (planProvider.videoEntries
                                  //     .any((video) => video.title.isEmpty)) {
                                  //   ScaffoldMessenger.of(context).showSnackBar(
                                  //     const SnackBar(
                                  //         content: Text('Video Title is required!')),
                                  //   );
                                  //   return;
                                  // }

                                  if (planProvider.videoEntries.any((video) =>
                                      !Util.isValidVideoUrl(video.url))) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'One or more video URLs are invalid')),
                                    );
                                    return;
                                  }
                                  Plan updatePlan = Plan(
                                      id: plan!.id,
                                      userId: plan!.userId,
                                      title: _titleController.text,
                                      description: _descriptionController.text,
                                      tags: _tags,
                                      folderId: plan!.folderId,
                                      videos: planProvider.videoEntries,
                                      timestamp: plan!.timestamp);
                                  await planProvider.updatePlan(updatePlan);
                                  Future.delayed(const Duration(seconds: 1),
                                      () {
                                    updatePlan.images =
                                        planProvider.finalUploadImages;
                                    planProvider.resetUploadImages();
                                    Navigator.pop(context, updatePlan);
                                  });
                                }:null,
                              ),
                      )
                      // const SizedBox(height: 20),
                      //         TextField(
                      //           controller: _titleController,
                      //           decoration: InputDecoration(
                      //             labelText: 'Plan Title',
                      //             hintText: 'Enter plan title',
                      //             labelStyle: TextStyle(color: Colors.grey),
                      //             prefixIcon: Icon(Icons.text_fields,
                      //                 color: Theme.of(context).primaryColor),
                      //             filled: true,
                      //             fillColor: Colors.grey[200],
                      //             border: OutlineInputBorder(
                      //               borderRadius: BorderRadius.circular(30), // Rounded edges
                      //               borderSide: BorderSide.none, // Removes default border
                      //             ),
                      //             focusedBorder: OutlineInputBorder(
                      //               borderRadius: BorderRadius.circular(30),
                      //               borderSide: BorderSide(
                      //                   color: Theme.of(context).primaryColor,
                      //                   width: 2), // Blue border when focused
                      //             ),
                      //             enabledBorder: OutlineInputBorder(
                      //               borderRadius: BorderRadius.circular(30),
                      //               borderSide: BorderSide(color: Colors.grey.shade300),
                      //             ),
                      //             contentPadding:
                      //                 EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                      //           ),
                      //           style: TextStyle(fontSize: 16),
                      //           keyboardType: TextInputType.text,
                      //         ),
                      //         const SizedBox(height: 16),
                      //         DescriptionField(
                      //           initialDescription: widget.plan.description,
                      //           onChanged: (description) {
                      //             _descriptionController.text = description;
                      //           },
                      //         ),
                      //         const SizedBox(height: 16),
                      //         _buildTagsInput(),
                      //         const SizedBox(height: 16),
                      //         Column(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: [
                      //             // + Button to pick images
                      //             ElevatedButton.icon(
                      //               onPressed: () {
                      //                 planProvider
                      //                     .pickImages(); // Call your existing pickImages method
                      //               },
                      //               icon: Icon(Icons.add),
                      //               label: Text('Add Images'),
                      //             ),
                      //
                      //             const SizedBox(height: 16),
                      //             // Show selected images horizontally
                      //             if (planProvider.selectedImages.isNotEmpty)
                      //               SizedBox(
                      //                 height: 100, // Adjust height as needed
                      //                 child: ListView.builder(
                      //                   scrollDirection: Axis.horizontal,
                      //                   itemCount: planProvider.selectedImages.length,
                      //                   itemBuilder: (context, index) {
                      //                     final selectedImage = planProvider.selectedImages[index];
                      //                     return Stack(
                      //                       children: [
                      //                         Container(
                      //                           margin: const EdgeInsets.only(right: 8),
                      //                           child: ClipRRect(
                      //                             borderRadius: BorderRadius.circular(8),
                      //                             child: selectedImage.isLocal
                      //                                 ? Image.file(
                      //                               selectedImage.localFile!,
                      //                               width: 100,
                      //                               height: 100,
                      //                               fit: BoxFit.cover,
                      //                             )
                      //                                 : Image.network(
                      //                               selectedImage.url!,
                      //                               width: 100,
                      //                               height: 100,
                      //                               fit: BoxFit.cover,
                      //                               loadingBuilder: (context, child, loadingProgress) {
                      //                                 if (loadingProgress == null) return child;
                      //                                 return Container(
                      //                                   width: 100,
                      //                                   height: 100,
                      //                                   color: Colors.grey[300],
                      //                                   child: const Center(
                      //                                     child: CircularProgressIndicator(strokeWidth: 2),
                      //                                   ),
                      //                                 );
                      //                               },
                      //                               errorBuilder: (context, error, stackTrace) {
                      //                                 return Container(
                      //                                   width: 100,
                      //                                   height: 100,
                      //                                   color: Colors.grey[300],
                      //                                   child: const Icon(Icons.error, color: Colors.red),
                      //                                 );
                      //                               },
                      //                             ),
                      //                           ),
                      //                         ),
                      //                         // Remove button
                      //                         Positioned(
                      //                           top: 0,
                      //                           right: 0,
                      //                           child: GestureDetector(
                      //                             onTap: () {
                      //                               planProvider.removeSelectedImage(index);
                      //                             },
                      //                             child: Container(
                      //                               decoration: BoxDecoration(
                      //                                 color: Colors.black54,
                      //                                 shape: BoxShape.circle,
                      //                               ),
                      //                               child: const Icon(
                      //                                 Icons.close,
                      //                                 color: Colors.white,
                      //                                 size: 20,
                      //                               ),
                      //                             ),
                      //                           ),
                      //                         ),
                      //                       ],
                      //                     );
                      //                   },
                      //                 ),
                      //               ),
                      //           ],
                      //         ),
                      //         const SizedBox(height: 16),
                      //         // Videos Section
                      //         const Align(
                      //           alignment: Alignment.centerLeft,
                      //           child: Text('Videos',
                      //               style:
                      //                   TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      //         ),
                      //         const SizedBox(height: 8),
                      //         Consumer<PlanProvider>(
                      //           builder: (context, planProvider, _) {
                      //             final videoEntries = planProvider.videoEntries;
                      //             return Column(
                      //               children: List.generate(videoEntries.length, (index) {
                      //                 return _buildVideoEntry(context, planProvider, index);
                      //               }),
                      //             );
                      //           },
                      //         ),
                      //         const SizedBox(height: 10),
                      //         TextButton.icon(
                      //           icon: const Icon(Icons.add),
                      //           label: const Text('Add Video'),
                      //           onPressed: () {
                      //             planProvider.addVideoEntry(
                      //               VideoEntry(title: '', url: '', isYoutubeUrl: false),
                      //             );
                      //           },
                      //         ),
                      //         const SizedBox(height: 24),
                      //         planProvider.isLoading
                      //             ? CircularProgressIndicator()
                      //             : PrimaryButton(
                      //                 text: 'Update Plan',
                      //                 onPressed: () async {
                      //                   if (_titleController.text.isEmpty) {
                      //                     ScaffoldMessenger.of(context).showSnackBar(
                      //                       const SnackBar(
                      //                           content: Text('Title field is required!')),
                      //                     );
                      //                     return;
                      //                   }
                      //
                      //                   // if (planProvider.videoEntries
                      //                   //     .any((video) => video.title.isEmpty)) {
                      //                   //   ScaffoldMessenger.of(context).showSnackBar(
                      //                   //     const SnackBar(
                      //                   //         content: Text('Video Title is required!')),
                      //                   //   );
                      //                   //   return;
                      //                   // }
                      //
                      //                   if (planProvider.videoEntries.any(
                      //                       (video) => !Util.isValidVideoUrl(video.url))) {
                      //                     ScaffoldMessenger.of(context).showSnackBar(
                      //                       const SnackBar(
                      //                           content: Text(
                      //                               'One or more video URLs are invalid')),
                      //                     );
                      //                     return;
                      //                   }
                      //                   Plan updatePlan = Plan(
                      //                       id: plan!.id,
                      //                       title: _titleController.text,
                      //                       description: _descriptionController.text,
                      //                       tags: _tags,
                      //                       videos: planProvider.videoEntries,
                      //                       timestamp: plan!.timestamp);
                      //                   await planProvider.updatePlan(updatePlan);
                      //                   Future.delayed(const Duration(seconds: 1),(){
                      //                     updatePlan.images = planProvider.finalUploadImages;
                      //                     planProvider.resetUploadImages();
                      //                     Navigator.pop(context, updatePlan);
                      //                   });
                      //                 },
                      //               ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
