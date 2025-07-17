import 'package:bjj_dairy/view/plan_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/folder.dart';
import '../model/plan.dart';
import '../providers/plan_provider.dart';
import '../utils/routes/routes_names.dart';
import '../utils/utils.dart';
import '../widgets/tag_selector.dart';
import '../widgets/technique_card.dart';
import 'edit_plan_screen.dart';
import 'in_app_webview_screen.dart';

class FolderPlansScreen extends StatefulWidget {
  final String folderId;
  final bool isShared;

  const FolderPlansScreen({super.key, required this.folderId,required this.isShared});

  @override
  State<FolderPlansScreen> createState() => _FolderPlansScreenState();
}

class _FolderPlansScreenState extends State<FolderPlansScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if(widget.isShared){
        Provider.of<PlanProvider>(context,listen: false).fetchShareFolderPlans(widget.folderId);
      }
    });
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

  String getVideoUrlWithTimestamp(Plan plan) {
    if (plan.videos![0].timeInSeconds! > 0) {
      return '${plan.videos![0].url}?t=${plan.videos![0].timeInSeconds}';
    }
    return plan.videos![0].url;
  }

  void showFolderSelectionBottomSheet(
    BuildContext context,
    List<Folder> folders,
    Function(String folderId) onFolderSelected,
  ) {
    final List<Folder> foldersWithDefault = [
      Folder(id: '', name: 'Default'), // Add default at the top
      ...folders.where((folder) => folder.id != widget.folderId),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Select Collection',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: ListView.separated(
                  itemCount: foldersWithDefault.length,
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                    height: 0,
                  ),
                  itemBuilder: (context, index) {
                    final folder = foldersWithDefault[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        folder.name ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onFolderSelected(folder.id ?? '');
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openVideoInWebView(Plan plan, BuildContext context) async {
    if (plan.videos!.isEmpty) {
      return;
    }
    if (Util.isYouTubeUrl(plan.videos![0].url)) {
      String url = getVideoUrlWithTimestamp(plan);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InAppWebViewScreen(url: url),
        ),
      );
    } else {
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

  void showTechniqueOptions(
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
                    'Options',
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
              if (plan.videos != null && plan.videos!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.play_circle_fill),
                  title: const Text('Play Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _openVideoInWebView(plan, context);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('More Details'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlanDetailScreen(plan: plan,isShared: widget.isShared,)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: const Text('Move to Collection'),
                onTap: () {
                  Navigator.pop(context);
                  if(widget.isShared){
                    Util.showMessageDialog(context, 'No permission to move');
                    return;
                  }
                  showFolderSelectionBottomSheet(
                    context,
                    planProvider.folders,
                    (selectedFolderId) {
                      planProvider.addPlanToCollection(
                          plan.id, selectedFolderId);
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.edit,
                ),
                title: const Text('Edit'),
                onTap: () async {
                  Navigator.pop(context);
                  if(widget.isShared){
                    Util.showMessageDialog(context, 'No permission to edit');
                    return;
                  }
                  final updatedPlan = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPlanScreen(plan: plan),
                    ),
                  );
                  if (updatedPlan != null && updatedPlan is Plan) {
                    setState(() {});
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  if(widget.isShared){
                    Util.showMessageDialog(context, 'No permission to edit');
                    return;
                  }
                  Util.showConfirmationDialog(
                    context: context,
                    title: 'Delete Technique',
                    content: 'Are you sure you want to delete?',
                    onConfirmed: () {
                      planProvider.deletePlan(plan.id);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planProvider = Provider.of<PlanProvider>(context, listen: true);

    return WillPopScope(
      onWillPop: () async {
        planProvider.filterPlans("", null);
        planProvider.applyTagFilter([], null);
        return true;
      },
      child: Scaffold(
        // appBar: AppBar(title: Text('Collection Plans')),
        // backgroundColor: Colors.grey.shade100,
        body: SafeArea(
          child: Column(
            children: [
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: TextField(
              //     controller: _searchController,
              //     decoration: InputDecoration(
              //       hintText: 'Searching...',
              //       prefixIcon: Icon(Icons.search),
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //       contentPadding: EdgeInsets.symmetric(horizontal: 16),
              //     ),
              //     onChanged: (value) {
              //       planProvider.filterPlans(value,widget.folderId);
              //     },
              //   ),
              // ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade400,
                      // Change to your desired color
                      width: 1.0, // Thickness of the border
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Colors.black, size: 30),
                        onPressed: () {
                          planProvider.filterPlans("", null);
                          planProvider.applyTagFilter([], null);
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search techniques...',
                                    border: InputBorder.none,
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: Icon(Icons.clear),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  // setState(() {}); // Rebuild to hide the icon
                                                  planProvider.filterPlans(
                                                      '',
                                                      widget
                                                          .folderId); // Optional: reset filter
                                                },
                                              )
                                            : null,
                                  ),
                                  onChanged: (value) {
                                    // setState(() {});
                                    planProvider.filterPlans(
                                        value, widget.folderId);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child:
              //   MultiSelectDialogField(
              //     items: planProvider.allTags
              //         .map((tag) => MultiSelectItem<String>(tag, tag))
              //         .toList(),
              //     title: Text("Select Tags"),
              //     buttonText: Text("Filter by Tags"),
              //     dialogHeight: 300,
              //     onConfirm: (values) {
              //       planProvider.applyTagFilter(values.map((tag) => tag.toLowerCase()).toList(),widget.folderId);
              //     },
              //   ),
              // ),
              if (planProvider.getAllCollectionTags(widget.folderId).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: TagSelector(
                    tags: planProvider.getAllCollectionTags(widget.folderId,isShared: widget.isShared),
                    initialSelected: ['All'],
                    onTagsSelected: (List<String> selectedTags) {
                      List<String> list =
                          selectedTags.map((tag) => tag.toLowerCase()).toList();
                      planProvider.applyTagFilter(list, widget.folderId);
                    },
                  ),
                ),
              // Expanded(
              //   child: planProvider.isLoading
              //       ? const Center(child: CircularProgressIndicator())
              //       : planProvider.plans.isEmpty
              //       ? Center(
              //     child: Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 8.0),
              //       child: Text(
              //         'Plan list is empty, Tap on plus icon to \n Get Started!',
              //         textAlign: TextAlign.center,
              //         style: TextStyle(fontSize: 16, color: Colors.grey),
              //       ),
              //     ),
              //   )
              //       : ListView(
              //     children: planProvider.plans
              //         .where((plan) => plan.folderId == widget.folderId)
              //         .map((plan) {
              //       return PlanTile(
              //         plan: plan,
              //         planProvider: planProvider,
              //         isCardView: true,
              //       );
              //     }).toList(),
              //   ),
              // ),
              Expanded(
                child: planProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (!widget.isShared && [...planProvider.plans,...planProvider.favouritesPlans]
                            // .where((plan) => plan.folderId == widget.folderId)
                            .isEmpty) || (widget.isShared && [...planProvider.sharedFolderPlans,...planProvider.favouritesPlans]
                    // .where((plan) => plan.folderId == widget.folderId || plan.isShared)
                    .isEmpty)
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Technique list is empty in this collection.\nTap on plus icon to Get Started!',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 60.0),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text('All Techniques',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              if(!widget.isShared)
                                ...[...planProvider.plans,...planProvider.favouritesPlans]
                                  .where((plan) =>
                                      plan.folderId == widget.folderId || plan.isShared)
                                  .map(
                                    (plan) => TechniqueCard(
                                      plan: plan,
                                      planProvider: planProvider,
                                      folderId: widget.folderId,
                                      isShared: plan.isShared,
                                      onMore: () {
                                        // Handle more actions
                                        showTechniqueOptions(
                                            context, plan, planProvider);
                                      },
                                    ),
                                  ),
                              if(widget.isShared)
                                ...[...planProvider.sharedFolderPlans,...planProvider.favouritesPlans]
                                //     .where((plan) =>
                                // plan.folderId == widget.folderId)
                                    .map(
                                      (plan) => TechniqueCard(
                                    plan: plan,
                                    planProvider: planProvider,
                                    isShared: true,
                                    folderId: widget.folderId,
                                    onMore: () {
                                      // Handle more actions
                                      showTechniqueOptions(
                                          context, plan, planProvider);
                                    },
                                  ),
                                ),
                            ],
                          ),
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (planProvider.isSelectionMode && !widget.isShared)
              Column(
                children: [
                  FloatingActionButton(
                    heroTag: 'cancel',
                    // Unique tag for each FAB
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    mini: true,
                    onPressed: () {
                      planProvider.exitSelectionMode();
                    },
                    child: const Icon(Icons.cancel_outlined),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  FloatingActionButton(
                    heroTag: 'done',
                    // Unique tag for each FAB
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    mini: true,
                    onPressed: () {
                      showFolderSelectionBottomSheet(
                        context,
                        planProvider.folders,
                        (selectedFolderId) {
                          // Call your method here
                          planProvider.submitSelectedPlans(selectedFolderId);
                        },
                      );
                    },
                    child: const Icon(Icons.check),
                  ),
                ],
              )
            //     :
            // FloatingActionButton(
            //   heroTag: 'createFolder', // Unique tag for each FAB
            //   backgroundColor: Theme.of(context).primaryColor,
            //   foregroundColor: Colors.white,
            //   mini: true,
            //   onPressed: () {
            //     final TextEditingController _folderNameController = TextEditingController();
            //
            //     showDialog(
            //       context: context,
            //       builder: (context) {
            //         return AlertDialog(
            //           title: const Text('Create Folder'),
            //           content: TextField(
            //             controller: _folderNameController,
            //             decoration: const InputDecoration(
            //               labelText: 'Folder Name',
            //               border: OutlineInputBorder(),
            //             ),
            //           ),
            //           actions: [
            //             TextButton(
            //               onPressed: () => Navigator.pop(context), // Close dialog
            //               child: const Text('Cancel'),
            //             ),
            //             ElevatedButton(
            //               onPressed: () {
            //                 final folderName = _folderNameController.text.trim();
            //                 if (folderName.isNotEmpty) {
            //                   planProvider.createFolder(folderName);
            //                   Navigator.pop(context); // Close the dialog
            //                   ScaffoldMessenger.of(context).showSnackBar(
            //                     SnackBar(content: Text('Folder "$folderName" created!')),
            //                   );
            //                 }
            //               },
            //               child: const Text('Create'),
            //             ),
            //           ],
            //         );
            //       },
            //     );
            //   },
            //   child: const Icon(Icons.create_new_folder),
            // ),
            ,
            const SizedBox(height: 12),
            if(!widget.isShared)
            FloatingActionButton(
              heroTag: 'addPlan',
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              mini: true,
              onPressed: () async {
                await Navigator.pushNamed(
                  context,
                  RoutesNames.addPlanScreen,
                  arguments: {
                    "parentId": '',
                    "isConnection": false,
                    "folderId": widget.folderId
                  },
                );
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}
