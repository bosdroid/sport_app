import 'dart:async';

import 'package:bjj_dairy/utils/app_strings.dart';
import 'package:bjj_dairy/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:provider/provider.dart';

import '../model/folder.dart';
import '../providers/plan_provider.dart';
import '../widgets/collection_card.dart';
import 'folder_plans_screen.dart';

class SearchFolderScreen extends StatefulWidget {
  const SearchFolderScreen({super.key});

  @override
  State<SearchFolderScreen> createState() => _SearchFolderScreenState();
}

class _SearchFolderScreenState extends State<SearchFolderScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isInternetAvailable = false;
  late StreamSubscription<InternetStatus> listener;
   @override
  void initState() {
    super.initState();
    checkInternet();
  }

  @override
  void dispose() {
    listener.cancel();
    super.dispose();
  }

  Future<void> checkInternet() async {
    isInternetAvailable = await InternetConnection().hasInternetAccess;

    listener = InternetConnection().onStatusChange.listen((InternetStatus status) {
      switch (status) {
        case InternetStatus.connected:
        // The internet is now connected
        setState(() {
          isInternetAvailable = true;
        });
          break;
        case InternetStatus.disconnected:
        // The internet is now disconnected
          setState(() {
            isInternetAvailable = false;
          });
          break;
      }
    });
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
                leading: const Icon(Icons.copy_all),
                title: const Text(AppStrings.getFolder),
                onTap: () async {
                  Navigator.pop(context); // Dismiss bottom sheet
                  if (!isInternetAvailable) {
                    Util.showMessageDialog(parentContext, AppStrings.internetRequired);
                    return;
                  }
                  if (collection.access == 'private') {
                    Util.showMessageDialog(parentContext, AppStrings.noAccess);
                    return;
                  } else if (collection.access == 'specific' &&
                      !collection.allowedUsers.contains(planProvider.loggedUserId)) {
                    Util.showMessageDialog(parentContext, AppStrings.noAccess);
                    return;
                  }

                  if (await planProvider.checkFolderPermission(planProvider.loggedUserId, collection.id!)) {
                    await planProvider.copySharedFolderWithTechniques(collection);
                    await Util.showMessageDialog(parentContext, AppStrings.copiedSuccess);
                  } else {
                    Util.showMessageDialog(parentContext, AppStrings.noAccess);
                  }

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
        planProvider.searchPublicFolders('');
        return true;
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
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
                    const Expanded(
                      child: Text(
                        AppStrings.searchFolderByShareId,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // To balance the back icon
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchFoldersHint,
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              planProvider.searchPublicFolders('');
                              // planProvider.clearSearchResults();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    if(value.isEmpty){
                      planProvider.searchPublicFolders('');
                    }
                    else{
                      if(!isInternetAvailable){
                        Util.showMessageDialog(context,AppStrings.internetRequired);
                        return;
                      }
                      planProvider.searchPublicFolders(value);
                    }

                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: planProvider.searchFolders.isEmpty
                    ? const Center(child: Text(AppStrings.noFoldersFound))
                    :
                ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: planProvider.searchFolders.length,
                  onReorder: (oldIndex, newIndex) {},
                  buildDefaultDragHandles: true,
                  itemBuilder: (context, index) {
                    if (index < planProvider.searchFolders.length) {
                      final collection = planProvider.searchFolders[index];

                      return Container(
                        key: ValueKey(collection.id),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: FutureBuilder<int>(
                          future: planProvider.getPlanCountForSearchFolder(collection),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;

                            return CollectionCard(
                              folder: collection,
                              count: count,
                              userId: planProvider.loggedUserId,
                              onTap: () async {
                                if (!isInternetAvailable) {
                                  Util.showMessageDialog(context, AppStrings.internetRequired);
                                  return;
                                }
                                if (collection.access == 'private') {
                                  Util.showMessageDialog(context, AppStrings.noAccess);
                                  return;
                                } else if (collection.access == 'specific' &&
                                    !collection.allowedUsers.contains(planProvider.loggedUserId)) {
                                  Util.showMessageDialog(context, AppStrings.noAccess);
                                  return;
                                }

                                if (await planProvider.checkFolderPermission(planProvider.loggedUserId, collection.id!)) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FolderPlansScreen(
                                        folderId: collection.id!,
                                        isShared: true,
                                      ),
                                    ),
                                  );
                                } else {
                                  Util.showMessageDialog(context, AppStrings.noAccess);
                                }
                              },
                              onMore: () {
                                showCollectionOptions(context, collection, planProvider);
                              },
                            );
                          },
                        ),
                      );
                    } else {
                      return const SizedBox();
                    }
                  },
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}
