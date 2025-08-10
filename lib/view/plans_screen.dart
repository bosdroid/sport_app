import 'package:bjj_dairy/view/folder_plans_screen.dart';
import 'package:bjj_dairy/view/pdf_export_screen.dart';
import 'package:bjj_dairy/view/plan_detail_screen.dart';
import 'package:bjj_dairy/widgets/plan_tile.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/folder.dart';
import '../model/plan.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/plan_provider.dart';
import '../utils/routes/routes_names.dart';
import '../utils/utils.dart';
import '../widgets/add_collection_card.dart';
import '../widgets/change_access_bottom_sheet.dart';
import '../widgets/collection_bottom_sheet.dart';
import '../widgets/collection_card.dart';
import '../widgets/collection_dialog.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/shaking_info_icon.dart';
import '../widgets/tag_selector.dart';
import '../widgets/technique_card.dart';
import '../widgets/videos_dailog.dart';
import 'edit_plan_screen.dart';
import 'in_app_webview_screen.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _selectedTags = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseReference _usersDetailsRef = FirebaseDatabase.instance.ref().child('USERS_DETAILS/');
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<PlanProvider>(context, listen: false).fetchFolders();
      await Provider.of<PlanProvider>(context, listen: false).fetchPlans();
      await Provider.of<PlanProvider>(context, listen: false).fetchFavouritesPlans();
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.fetchAndSaveVideos();  // Then update from Firebase
      await appProvider.loadVideosFromPrefs(); // Load locally first
      await FirebaseMessaging.instance.getToken().then((token) {
        _usersDetailsRef.child(Provider.of<PlanProvider>(context, listen: false).loggedUserId)
            .update({'fcmToken': token});
      });
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
    if (plan.videos![0].timeInSeconds != null &&
        plan.videos![0].timeInSeconds! > 0) {
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
      ...folders,
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
                        builder: (_) => PlanDetailScreen(plan: plan,isShared: false,)),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_outline),
                title: const Text('Move to Collection'),
                onTap: () {
                  Navigator.pop(context);

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

  void _showCreateCollectionDialog(
      PlanProvider planProvider, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CollectionBottomSheet(
        title: 'Create Collection',
        planProvider: planProvider,
        onConfirm: (folderName) {
          planProvider.createFolder(folderName);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Collection "$folderName" created!')),
          );
        },
      ),
    );
  }

  void _showEditCollectionDialog(PlanProvider planProvider,
      BuildContext context, String currentName, String folderId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CollectionBottomSheet(
        title: 'Edit Collection',
        initialName: currentName,
        planProvider: planProvider,
        onConfirm: (newName) {
          Util.showConfirmationDialog(
            context: context,
            title: 'Rename Collection',
            content: 'Are you sure you want to rename this collection?',
            onConfirmed: () {
              planProvider.updateFolder(folderId, newName);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Collection updated to "$newName"!')),
              );
            },
          );
        },
      ),
    );
  }

  void showChangeAccessBottomSheet({
    required BuildContext context,
    required PlanProvider planProvider,
    required Folder collection,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeAccessBottomSheet(
        collection: collection,
        planProvider: planProvider,
      ),
    );
  }

  void showCollectionOptions(
    BuildContext context,
    Folder collection,
    PlanProvider planProvider,
  ) {
    final parentContext =
        context; // Save parent context before opening bottom sheet

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
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
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context); // Dismiss bottom sheet
                  // Use the outer context, not this builder context
                  Future.delayed(Duration.zero, () {
                    _showEditCollectionDialog(
                      planProvider,
                      parentContext,
                      collection.name!,
                      collection.id!,
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(Duration.zero, () {
                    Util.showConfirmationDialog(
                      context: parentContext,
                      title: 'Delete Collection',
                      content:
                          'If you remove this collection, all cards inside will be removed. Are you sure you want to delete this collection?',
                      onConfirmed: () {
                        planProvider.deleteFolder(collection);
                      },
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: const Text('Change Access'),
                trailing: Text(collection.access.toUpperCase(),style: TextStyle(fontSize: 14,color: Theme.of(context).primaryColor),),
                onTap: () {
                  Navigator.pop(context); // Dismiss bottom sheet
                  Future.delayed(Duration.zero, () {
                    showChangeAccessBottomSheet(
                      context: parentContext,
                      planProvider: planProvider,
                      collection: collection,
                    );
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy'),
                subtitle: Row(children: [
                  Text('ID:',style: TextStyle(color: Colors.black, fontSize: 16),),
                  const SizedBox(width: 6,),
                  Text('${collection.shareId}',style: TextStyle(color: Colors.grey, fontSize: 16),)
                ],),
                onTap: () {
                  final shareId = collection.shareId;
                  if (shareId != null && shareId.isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: shareId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ID is not available'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  Navigator.pop(context); // Dismiss bottom sheet

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
    final authProvider = Provider.of<AuthProvider>(context,listen: true);

    return WillPopScope(
      onWillPop: () async {
        planProvider.filterPlans("", null);
        planProvider.applyTagFilter([], null);
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        key: _scaffoldKey,
        drawer: CustomDrawer(
          onItemTap: (action) async {
            _scaffoldKey.currentState?.closeDrawer();

            // Handle the action callback
            switch (action) {
              case 'profile':
                print('Navigate to Profile');
                Navigator.pushNamed(
                    context, RoutesNames.profileScreen);
                break;
              case 'search_folder':
                print('Navigate to search_folder');
                Navigator.pushNamed(
                    context, RoutesNames.searchFolderScreen);
                break;
              case 'rate':
                print('Navigate to Rate Us');
                break;
              case 'recommend':
                print('Share with friends');
                break;
              case 'support':
                print('Open Contact Support');
                break;
              case 'logout':
                await planProvider.resetLoggedId();
                await authProvider.logout();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(
                    context, RoutesNames.loginScreen);
                break;
              case 'privacy':
                print('Show Privacy Policy');
                break;
            }
          },
        ),
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
              //       planProvider.filterPlans(value,null);
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
                        icon: Icon(Icons.menu,
                            color: Theme.of(context).primaryColor, size: 30),
                        onPressed: () {
                          // Open drawer or do something
                          _scaffoldKey.currentState?.openDrawer();
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
                                                  planProvider.filterPlans('',
                                                      null); // Optional: reset filter
                                                },
                                              )
                                            : null,
                                  ),
                                  onChanged: (value) {
                                    // setState(() {});
                                    planProvider.filterPlans(value, null);
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
              //       planProvider.applyTagFilter(values.map((tag) => tag.toLowerCase()).toList(),null);
              //     },
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Collections',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ShakingInfoIcon(onWatched: (){
                          final videos = Provider.of<AppProvider>(context,listen: false).videos;
                          showDialog(
                            context: context,
                            builder: (_) => VideosDialog(videos: videos),
                          );
                          // final firstVideo = videos['one'];
                          // Util.showYoutubeDialog(context, firstVideo as String);
                        })
                      ],
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child:
                      ReorderableListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: planProvider.folders.length + 1,
                        onReorder: (oldIndex, newIndex) {
                          // Prevent reordering if AddCollectionCard is involved
                          if (oldIndex >= planProvider.folders.length ||
                              newIndex > planProvider.folders.length - 1 || planProvider.loggedUserId != planProvider.folders[oldIndex].userId) {
                            return; // Do nothing if trying to reorder the AddCollectionCard
                          }
                          planProvider.reorderFolders(oldIndex, newIndex);
                        },
                        buildDefaultDragHandles: true,
                        // Use default drag handles for draggable items
                        itemBuilder: (context, index) {
                          if (index < planProvider.folders.length) {
                            final collection = planProvider.folders[index];
                            return Container(
                              key: ValueKey(collection.id),
                              // 🔑 Required key for reordering
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: CollectionCard(
                                folder: collection,
                                count: planProvider
                                    .getPlanCountForFolder(collection),
                                userId: planProvider.loggedUserId,
                                onTap: () {
                                  planProvider.filterPlans("", null);
                                  planProvider.applyTagFilter([], null);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FolderPlansScreen(
                                        folderId: collection.id!,isShared:
                                      false,),
                                    ),
                                  );
                                },
                                onMore: () {
                                  showCollectionOptions(
                                      context, collection, planProvider);
                                },
                              ),
                            );
                          } else {
                            // AddCollectionCard with a fixed key, not draggable
                            return Container(
                              key: const ValueKey('add_card'),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: AddCollectionCard(
                                onTap: () => _showCreateCollectionDialog(
                                    planProvider, context),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (planProvider.getAllListTags().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16.0, horizontal: 8.0),
                  child: TagSelector(
                    tags: planProvider.getAllListTags(),
                    initialSelected: ['All'],
                    onTagsSelected: (List<String> selectedTags) {
                      List<String> list =
                          selectedTags.map((tag) => tag.toLowerCase()).toList();
                      planProvider.applyTagFilter(list, null);
                    },
                  ),
                ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       const Text(
              //         'Collections',
              //         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              //       ),
              //       const SizedBox(height: 8),
              //       GridView.builder(
              //         shrinkWrap: true,
              //         physics: const NeverScrollableScrollPhysics(),
              //         itemCount: planProvider.folders.length,
              //         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              //           crossAxisCount: 3, // Three columns
              //           mainAxisSpacing: 8.0,
              //           crossAxisSpacing: 8.0,
              //             childAspectRatio: 3 / 2.4, // Adjust for layout balance
              //         ),
              //         itemBuilder: (context, index) {
              //           final folder = planProvider.folders[index];
              //           return GestureDetector(
              //             onTap: () {
              //               Navigator.push(
              //                 context,
              //                 MaterialPageRoute(builder: (_) => FolderPlansScreen(folderId: folder.id!)),
              //               );
              //             },
              //             child: Card(
              //               elevation: 2,
              //               child: Center(
              //                 child: Column(
              //                   mainAxisSize: MainAxisSize.min, // Prevents overflow
              //                   children: [
              //                     const Icon(Icons.folder, size: 32, color: Colors.amber),
              //                     const SizedBox(height: 8),
              //                     Text(
              //                       folder.name!.toUpperCase(),
              //                       textAlign: TextAlign.center,
              //                       style: const TextStyle(
              //                         color: Colors.black,
              //                         fontWeight: FontWeight.bold,
              //                         fontSize: 12,
              //                       ),
              //                     ),
              //                     const SizedBox(height: 4),
              //                     Text(
              //                       '(${planProvider.getPlanCountForFolder(folder.id!)})',
              //                       style: const TextStyle(color: Colors.grey, fontSize: 14),
              //                     ),
              //                   ],
              //                 ),
              //               ),
              //             ),
              //           );
              //         },
              //       ),
              //
              //     ],
              //   ),
              // ),

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
              //         .where((plan) => plan.folderId.isEmpty)
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
                    : planProvider.plans
                            .where((plan) => plan.folderId.isEmpty && plan.userId == planProvider.loggedUserId)
                            .isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Technique list is empty, Tap on plus icon to \n Get Started!',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 60.0),
                            // 👈 Bottom padding
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text('All Techniques',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ...planProvider.plans
                                  .where((plan) => plan.folderId.isEmpty && plan.userId == planProvider.loggedUserId)
                                  .map(
                                    (plan) => TechniqueCard(
                                      plan: plan,
                                      planProvider: planProvider,
                                      folderId: '',
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
            if (planProvider.isSelectionMode)
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
              ),
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
            const SizedBox(height: 12),
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
                    "folderId": ""
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
