import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/plan_provider.dart';
import '../widgets/collection_card.dart';

class SearchFolderScreen extends StatefulWidget {
  const SearchFolderScreen({super.key});

  @override
  State<SearchFolderScreen> createState() => _SearchFolderScreenState();
}

class _SearchFolderScreenState extends State<SearchFolderScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final planProvider = Provider.of<PlanProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: () async {
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
                        'Search Folder by Share ID',
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
                    hintText: 'Search folders...',
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              // planProvider.clearSearchResults();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    planProvider.searchPublicFolders(value);
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: planProvider.searchFolders.isEmpty
                    ? const Center(child: Text('No folders found'))
                    :
                // ListView.builder(
                //         itemCount: planProvider.searchFolders.length,
                //         itemBuilder: (context, index) {
                //           final collection = planProvider.searchFolders[index];
                //           return CollectionCard(
                //             title: collection.name ?? '',
                //             count: planProvider
                //                 .getPlanCountForFolder(collection.id!),
                //             onTap: () {
                //
                //               // Navigator.push(
                //               //   context,
                //               //   MaterialPageRoute(
                //               //     builder: (_) => FolderPlansScreen(
                //               //         folderId: collection.id!),
                //               //   ),
                //               // );
                //             },
                //             onMore: () {
                //               // showCollectionOptions(
                //               //     context, collection, planProvider);
                //             },
                //           );
                //         },
                //       ),
                ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: planProvider.searchFolders.length,
                  onReorder: (oldIndex, newIndex) {
                    // // Prevent reordering if AddCollectionCard is involved
                    // if (oldIndex >= planProvider.folders.length ||
                    //     newIndex > planProvider.folders.length - 1) {
                    //   return; // Do nothing if trying to reorder the AddCollectionCard
                    // }
                    // planProvider.reorderFolders(oldIndex, newIndex);
                  },
                  buildDefaultDragHandles: true,
                  // Use default drag handles for draggable items
                  itemBuilder: (context, index) {
                    if (index < planProvider.searchFolders.length) {
                      final collection = planProvider.searchFolders[index];
                      return Container(
                        key: ValueKey(collection.id),
                        // 🔑 Required key for reordering
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: CollectionCard(
                          title: collection.name ?? '',
                          count: 0,
                          onTap: () {
                            // planProvider.filterPlans("", null);
                            // planProvider.applyTagFilter([], null);
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (_) => FolderPlansScreen(
                            //         folderId: collection.id!),
                            //   ),
                            // );
                          },
                          onMore: () {
                            // showCollectionOptions(
                            //     context, collection, planProvider);
                          },
                        ),
                      );
                    } else {
                      // AddCollectionCard with a fixed key, not draggable
                      return SizedBox(
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
