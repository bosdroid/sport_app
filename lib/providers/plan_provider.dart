import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:bjj_dairy/model/folder.dart';
import 'package:bjj_dairy/model/video_entry.dart';
import 'package:bjj_dairy/providers/validation_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/plan.dart';
import '../model/selected_image.dart';
import '../services/image_service.dart';
import '../utils/app_analytics.dart';

class PlanProvider with ChangeNotifier {
  final DatabaseReference _plansRef =
      FirebaseDatabase.instance.ref().child('PLANS/');
  final DatabaseReference _foldersRef =
      FirebaseDatabase.instance.ref().child('FOLDERS/');
  final DatabaseReference _shareIdsRef =
  FirebaseDatabase.instance.ref().child('SHARE_IDS/');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _suggestedTags = [
    'submissions',
    'escapes',
    'pressure',
    'defense'
  ];
  List<Plan> _allPlans = [];
  List<Plan> _plans = [];
  List<Folder> _folders = [];
  List<Folder> _searchFolders = [];

  List<Folder> get folders => _folders;
  List<Folder> get searchFolders => _searchFolders;
  bool _isLoading = false;
  List<Plan> _filteredPlans = [];

  // List<Plan> get plans => _filteredPlans.isNotEmpty ? _filteredPlans : _plans;
  List<Plan> get plans => _plans;

  bool get isLoading => _isLoading;
  Timer? _debounce;
  Plan? _selectedPlan;

  Plan? get selectedPlan => _selectedPlan;
  List<String> _allTags = [];

  List<String> get allTags => _allTags;
  List<VideoEntry> _videoEntries = [];

  List<VideoEntry> get videoEntries => _videoEntries;
  List<SelectedImage> _selectedImages = [];

  List<SelectedImage> get selectedImages => _selectedImages;
  final ImageService _imageService = ImageService();
  List<String> _finalUploadImages = [];

  List<String> get finalUploadImages => _finalUploadImages;
  Set<String> selectedPlanIds = {};
  bool isSelectionMode = false;
  late ValidationProvider _validationProvider;

  void updateDependencies(ValidationProvider validationProvider) {
    _validationProvider = validationProvider;
  }

  void enterSelectionMode(String planId) {
    isSelectionMode = true;
    selectedPlanIds.add(planId);
    notifyListeners();
  }

  void addPlanToCollection(String planId, String fId) {
    selectedPlanIds.add(planId);
    submitSelectedPlans(fId);
  }

  void toggleSelection(String planId) {
    if (selectedPlanIds.contains(planId)) {
      selectedPlanIds.remove(planId);
    } else {
      selectedPlanIds.add(planId);
    }
    notifyListeners();
  }

  void exitSelectionMode() {
    isSelectionMode = false;
    selectedPlanIds.clear();
    notifyListeners();
  }

  Future<void> submitSelectedPlans(String fId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';

    _isLoading = true;
    notifyListeners();

    try {
      for (String planId in selectedPlanIds) {
        final index = _plans.indexWhere((plan) => plan.id == planId);
        if (index != -1) {
          Plan currentPlan = _plans[index];

          // Update Firebase
          await _plansRef.child(currentPlan.id).update({
            'folderId': fId,
          });

          // Update local list
          _plans[index].folderId = fId;
        }
      }

      _isLoading = false;
      exitSelectionMode();
    } catch (e) {
      print('Error updating selected plans: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> getAllCollectionTags(String cid) {
    final allTags = _allPlans
        .where((plan) => plan.folderId == cid)
        .expand((plan) => plan.tags)
        .toSet()
        .toList();

    allTags.sort(); // Optional: Sort tags alphabetically if needed
    return ['All', ...allTags];
  }

  List<String> getAllListTags() {
    final allTags = _allPlans
        .where((plan) => plan.folderId.isEmpty)
        .expand((plan) => plan.tags)
        .toSet()
        .toList();

    allTags.sort(); // Optional: Sort tags alphabetically if needed
    return ['All', ...allTags];
  }

  int getPlanCountForFolder(String folderId) {
    return _allPlans.where((plan) => plan.folderId == folderId).length;
  }

  String generateRandomShareId({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<bool> isShareIdUnique(String shareId) async {
    final snapshot = await _shareIdsRef.child(shareId).get();
    return snapshot.value == null;
  }


  Future<void> createFolder(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;
    final String folderId = _foldersRef.child(userId).push().key!;

    // Generate a unique shareId
    String shareId;
    do {
      shareId = generateRandomShareId();
    } while (!(await isShareIdUnique(shareId)));

    final newFolder = Folder(
      id: folderId,
      userId: userId,
      name: name,
      order: _folders.length,
      shareId: shareId,
      access: 'private', // default access
      allowedUsers: [], // initially empty
    );

    await _foldersRef.child(folderId).set(newFolder.toMap());
    await _shareIdsRef.child(shareId).set(folderId);
    _folders.add(newFolder);
    notifyListeners();
  }

  Future<void> updateFolderAccess(String folderId, String accessType, {List<String>? allowedUsers}) async {
    final updateData = {
      'access': accessType,
      'allowedUsers': accessType == 'specific' ? (allowedUsers ?? []) : [],
    };

    await _foldersRef.child(folderId).update(updateData);

    final index = _folders.indexWhere((folder) => folder.id == folderId);
    if (index != -1) {
      final updated = _folders[index].copyWith(
        access: accessType,
        allowedUsers: List<String>.from(updateData['allowedUsers'] as List),
      );
      _folders[index] = updated;
      notifyListeners();
    }
  }

  bool canUserAccessFolder(Folder folder, String currentUserId) {
    if (folder.access == 'public') return true;
    if (folder.access == 'private') return folder.userId == currentUserId;
    if (folder.access == 'specific') {
      return folder.userId == currentUserId || folder.allowedUsers.contains(currentUserId);
    }
    return false;
  }


  // Future<void> createFolder(String name) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String userId = prefs.getString("user_name") as String;
  //   final String folderId = _foldersRef.child(userId).push().key!;
  //   await _foldersRef.child(folderId).set({
  //     'id': folderId,
  //     'user_id':userId,
  //     'name': name,
  //     'order': _folders.length,
  //   });
  //   _folders.add(Folder(id: folderId,userId: userId, name: name,order: _folders.length));
  //   notifyListeners();
  // }

  // Future<void> fetchFolders() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String userId = prefs.getString("user_name") as String;
  //
  //   final DataSnapshot snapshot = await _foldersRef.child(userId).get();
  //
  //   if (snapshot.exists) {
  //     final Map<dynamic, dynamic> data =
  //         snapshot.value as Map<dynamic, dynamic>;
  //
  //     _folders = data.entries.map((entry) {
  //       final folderId = entry.key;
  //       final folderData = Map<String, dynamic>.from(entry.value);
  //       return Folder.fromMap(folderData, folderId);
  //     }).toList();
  //     _folders.sort((a, b) => a.order.compareTo(b.order));
  //   } else {
  //     _folders = [];
  //   }
  //
  //   notifyListeners();
  // }

  Future<void> _addShareIdIfMissing(String folderId) async {
    final DatabaseReference folderRef = _foldersRef.child(folderId);

    // Double‑check on the server that it’s still missing (race‑condition safe)
    final DataSnapshot current = await folderRef.child('shareId').get();
    if (current.exists && (current.value as String).isNotEmpty) return;

    // Generate a unique shareId
    String shareId;
    do {
      shareId = generateRandomShareId();          // e.g. “X7Q9b2”
    } while (!(await isShareIdUnique(shareId)));

    // Atomically write shareId into both nodes
    await folderRef.update({'shareId': shareId});
    await _shareIdsRef.child(shareId).set(folderId);
  }

  Future<void> fetchFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString('user_name') ?? '';

    final DataSnapshot snapshot = await _foldersRef.orderByChild('userId').equalTo(userId).get();            // /folders
    if (!snapshot.exists) {
      _folders = [];
      notifyListeners();
      return;
    }

    final Map<dynamic, dynamic> data =
    Map<dynamic, dynamic>.from(snapshot.value as Map);

    // ── 1.  Add a shareId where it’s missing ────────────────────────
    final List<Future<void>> pendingUpdates = [];

    data.forEach((folderId, raw) {
      final folderData = Map<String, dynamic>.from(raw);

      if (folderData['userId'] != userId) return;

      // No shareId?  Create & queue an update
      if (folderData['shareId'] == null || (folderData['shareId'] as String).isEmpty) {
        pendingUpdates.add(_addShareIdIfMissing(folderId));
      }
    });

    // Wait until every missing‑shareId folder is fixed in Firebase
    if (pendingUpdates.isNotEmpty) await Future.wait(pendingUpdates);

    // ── 2.  Build the local list (now guaranteed to have shareIds) ──
    _folders = data.entries
        .map((e) => Folder.fromMap(Map<String, dynamic>.from(e.value)))
        .where((f) => f.userId == userId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    notifyListeners();
  }

  Future<void> searchPublicFolders(String shareId) async {
    final DataSnapshot snapshot = await _foldersRef.orderByChild('shareId').equalTo(shareId).get();

    if (!snapshot.exists) {
      // Folder doesn't exist
      _searchFolders = [];
      notifyListeners();
      return;
    }

    final Map<dynamic, dynamic> data =
    Map<dynamic, dynamic>.from(snapshot.value as Map);

    _searchFolders = data.entries
        .map((e) => Folder.fromMap(Map<String, dynamic>.from(e.value)))
        .where((f) => f.access == 'public')
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    // final access = (data['access'] ?? '').toString().trim().toLowerCase();
     print('Access value: ${_searchFolders.length}'); // Add for debugging
    // // Check if the folder is public
    // if (access == 'public') {
    //   final Folder folder = Folder.fromMap(data);
    //
    //   // Do something with the folder (e.g., add to a list or update UI)
    //   print('Public Folder Found: ${folder.name}');
    //
    //   // If you maintain a list like `_publicFolders`, update it here
    //   _searchFolders = [folder]; // Optional: maintain a separate list
    //   notifyListeners();
    // } else {
    //   print('Folder is not public');
    //   _searchFolders = [];
      notifyListeners();
    // }
  }


  // Future<void> fetchFolders() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final String userId = prefs.getString("user_name") ?? '';
  //
  //   final DataSnapshot snapshot = await _foldersRef.get(); // get all folders
  //
  //   if (snapshot.exists) {
  //     final Map<dynamic, dynamic> data =
  //     snapshot.value as Map<dynamic, dynamic>;
  //
  //     _folders = data.entries.map((entry) {
  //       final folderId = entry.key;
  //       final folderData = Map<String, dynamic>.from(entry.value);
  //       return Folder.fromMap(folderData, folderId);
  //     }).where((folder) => folder.userId == userId).toList();
  //     _folders.sort((a, b) => a.order.compareTo(b.order));
  //   } else {
  //     _folders = [];
  //   }
  //
  //   notifyListeners();
  // }


  Future<void> deleteFolder(Folder folder) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    // Remove the folder from Firebase
    await _foldersRef.child('${folder.id}').remove();
    await _shareIdsRef.child('${folder.shareId}').remove();

    // Remove from local folder list
    _folders.removeWhere((folder) => folder.id == '${folder.id}');

    // Update plans that were assigned to this folder
    for (var plan in _plans) {
      if (plan.folderId == '${folder.id}') {
        plan.folderId = ""; // or set to "" or "unassigned" as needed
        await _plansRef.child('$userId/${plan.id}').update({
          'folderId': '',
        });
      }
    }

    notifyListeners();
  }

  Future<void> updateFolder(String folderId, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") as String;

    await _foldersRef.child(folderId).update({
      'name': newName,
    });

    final index = _folders.indexWhere((folder) => folder.id == folderId);
    if (index != -1) {
      _folders[index].name = newName;
      notifyListeners();
    }
  }

  void reorderFolders(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name")!;

    final folder = _folders.removeAt(oldIndex);
    _folders.insert(newIndex, folder);

    // Update the order field in memory
    for (int i = 0; i < _folders.length; i++) {
      _folders[i] = _folders[i].copyWith(order: i);
      // Optionally update in Firebase
      _foldersRef.child("${_folders[i].id}").update({'order': i});
    }

    notifyListeners();
  }

  void pickImages() async {
    try {
      await _validationProvider.validateImages(_selectedImages);
      if (_validationProvider.imagesError != null) {
        return;
      }

      List<XFile> pickedImages = await _imageService.pickMultipleImages();

      if (pickedImages.isNotEmpty) {
        if (_selectedImages.length + pickedImages.length > 5) {
          await _validationProvider.updateImageError();
          return;
        }
        pickedImages.map((xfile) async {
          await _validationProvider.validateImage(xfile);
          if (_validationProvider.imagesError != null) {
            return;
          }
        });
        _selectedImages.addAll(
          pickedImages
              .map((xfile) => SelectedImage(localFile: File(xfile.path))),
        );
        notifyListeners(); // Update your UI
      } else {
        print('No images selected.');
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  Future<Plan?> pickAndUploadImages(Plan? plan) async {
    try {
      await _validationProvider.validateImages(_selectedImages);
      if (_validationProvider.imagesError != null) {
        plan;
      }

      List<XFile> pickedImages = await _imageService.pickMultipleImages();

      if (pickedImages.isNotEmpty) {
        if(_selectedImages.length + pickedImages.length > 5)
        {
          await _validationProvider.updateImageError();
          return plan;
        }
        pickedImages.map((xfile) async {
          await _validationProvider.validateImage(xfile);
          if (_validationProvider.imagesError != null) {
            return plan;
          }
        });
        _selectedImages.addAll(
          pickedImages
              .map((xfile) => SelectedImage(localFile: File(xfile.path))),
        );
        if (plan != null) {
          final latestPlan = await updatedPlan(plan);
          return latestPlan;
        }
        notifyListeners(); // Update your UI
      } else {
        // print('No images selected.');
        return plan;
      }
    } catch (e) {
      // print('Error picking images: $e');
      return plan;
    }
  }

  void setSelectedImages(List<String> images) {
    _selectedImages = images.map((url) => SelectedImage(url: url)).toList();
    notifyListeners();
  }

  void removeSelectedImage(int index) {
    selectedImages.removeAt(index);
    notifyListeners();
  }

  void setVideoEntries(List<VideoEntry> videos) {
    _videoEntries = videos;
    notifyListeners();
  }

  void addVideoEntry(VideoEntry entry) {
    _videoEntries.add(entry);
    notifyListeners();
  }

  void updateVideoEntry(int index, VideoEntry updatedEntry) {
    _videoEntries[index] = updatedEntry;
    notifyListeners();
  }

  void removeVideoEntry(int index) {
    _videoEntries.removeAt(index);
    notifyListeners();
  }

  void updateSelectPlan(Plan value) {
    _selectedPlan = value;
    notifyListeners();
  }

  void resetUploadImages() {
    _finalUploadImages = [];
    _selectedImages = [];
    notifyListeners();
  }

  // Future<void> fetchPlans() async {
  //   final user = _auth.currentUser;
  //   if (user == null) return;
  //
  //   final prefs = await SharedPreferences.getInstance();
  //   final String userId = prefs.getString("user_name") ?? '';
  //
  //   _isLoading = true;
  //   notifyListeners();
  //
  //   try {
  //     final snapshot = await _plansRef.child(userId).get();
  //
  //     if (snapshot.exists && snapshot.value != null) {
  //       final rawData = snapshot.value;
  //       debugPrint("Fetched Data: $rawData"); // Log the raw data
  //
  //       if (rawData is Map<Object?, Object?>) {
  //         _plans = rawData.entries
  //             .map((entry) {
  //               final key = entry.key.toString();
  //               final value = entry.value;
  //
  //               if (value is Map<Object?, Object?>) {
  //                 final data = value.map((k, v) => MapEntry(k.toString(), v));
  //
  //                 Plan plan = Plan.fromMap(data);
  //                 debugPrint(
  //                     "Plan ID: ${plan.id}, From: ${plan.from}, To: ${plan.to}"); // Debug
  //                 return plan;
  //               } else {
  //                 debugPrint("Skipping invalid entry: Key=$key, Value=$value");
  //                 return null;
  //               }
  //             })
  //             .whereType<Plan>()
  //             .toList();
  //         _plans = _plans..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  //         _allPlans.addAll(_plans);
  //         updateAllTags();
  //       } else {
  //         debugPrint("Fetched data is not a Map: $rawData");
  //         _plans = [];
  //       }
  //     } else {
  //       debugPrint("No plans found for user: $userId");
  //       _plans = [];
  //     }
  //   } catch (e, stackTrace) {
  //     debugPrint("Error fetching plans: $e\n$stackTrace");
  //     AppAnalytics.logErrorStateShown('404');
  //     _plans = [];
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchPlans() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _plansRef.orderByChild('userId').equalTo(userId).get();

      if (snapshot.exists && snapshot.value != null) {
        final rawData = snapshot.value;
        debugPrint("Fetched Data: $rawData");

        if (rawData is Map<Object?, Object?>) {
          final List<Plan> fetchedPlans = [];

          for (final entry in rawData.entries) {
            final value = entry.value;

            if (value is Map<Object?, Object?>) {
              final data = value.map((k, v) => MapEntry(k.toString(), v));

              final plan = Plan.fromMap(data);
              if (plan.userId == userId) {
                fetchedPlans.add(plan);
                debugPrint("Plan ID: ${plan.id}, From: ${plan.from}, To: ${plan.to}");
              } else {
                debugPrint("Skipped plan with mismatched userId: ${plan.userId}");
              }
            } else {
              debugPrint("Skipping invalid entry: Key=${entry.key}, Value=$value");
            }
          }

          _plans = fetchedPlans..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _allPlans.addAll(_plans);
          updateAllTags();
        } else {
          debugPrint("Fetched data is not a valid Map: $rawData");
          _plans = [];
        }
      } else {
        debugPrint("No plans found for user: $userId");
        _plans = [];
      }
    } catch (e, stackTrace) {
      debugPrint("Error fetching plans: $e\n$stackTrace");
      AppAnalytics.logErrorStateShown('404');
      _plans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  void updateAllTags() {
    if (_allTags.isNotEmpty) {
      _allTags = [];
    }
    _allTags.addAll(['All', 'Start Position']);
    _allTags.addAll(_suggestedTags);
    for (var plan in _plans) {
      _allTags.addAll(plan.tags);
    }
    _allTags = _allTags.toSet().toList();
    notifyListeners();
  }

  // void filterPlans(String query, String? fId) {
  //   _debounce?.cancel();
  //
  //   _debounce = Timer(const Duration(milliseconds: 300), () {
  //     final normalizedQuery = query.trim().toLowerCase();
  //     final hasQuery = normalizedQuery.isNotEmpty;
  //     final hasFolder = fId != null && fId.isNotEmpty;
  //
  //     if (!hasQuery && !hasFolder) {
  //       _filteredPlans = List.from(_plans);
  //     } else {
  //       _filteredPlans = _plans.where((plan) {
  //         final title = plan.title.trim().toLowerCase();
  //         final matchesQuery = title.contains(normalizedQuery);
  //
  //         if (hasFolder) {
  //           // FolderId is provided — match both query and folderId
  //           return matchesQuery && plan.folderId == fId;
  //         } else {
  //           // FolderId is not provided — match only query
  //           return matchesQuery;
  //         }
  //       }).toList();
  //       print('_filteredPlans: $_filteredPlans');
  //     }
  //
  //     // Logging analytics only when a query is provided
  //     if (hasQuery) {
  //       AppAnalytics.logSearchPerformed(normalizedQuery);
  //       if (_filteredPlans.isEmpty) {
  //         AppAnalytics.logEmptyStateShown('search');
  //       }
  //     }
  //
  //     if (kDebugMode) {
  //       print('Filtered plans: $_filteredPlans');
  //     }
  //
  //     notifyListeners();
  //   });
  // }

  void filterPlans(String query, String? fId) {
    if (query.length < 2) {
      return;
    }
    _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final normalizedQuery = query.trim().toLowerCase();
      final hasQuery = normalizedQuery.isNotEmpty;
      final hasFolder = fId != null && fId.isNotEmpty;

      List<Plan> sourceList = _allPlans;

      if (!hasQuery && !hasFolder) {
        _plans = List.from(sourceList);
      } else {
        _plans = sourceList.where((plan) {
          final title = plan.title.trim().toLowerCase();
          final matchesQuery = title.contains(normalizedQuery);
          return hasFolder
              ? matchesQuery && plan.folderId == fId
              : matchesQuery;
        }).toList();
      }

      if (hasQuery) {
        AppAnalytics.logSearchPerformed(normalizedQuery);
        if (_plans.isEmpty) {
          AppAnalytics.logEmptyStateShown('search');
        }
      }

      notifyListeners();
    });
  }

  // void applyTagFilter(List<String> selectedTags, String? folderId) {
  //   AppAnalytics.logFilterTagSelected(selectedTags.join(","));
  //   if (selectedTags.isEmpty) {
  //     _filteredPlans = [];
  //   } else {
  //     List<Plan> filtered = [];
  //
  //     if (selectedTags.contains('all')) {
  //       filtered = _plans;
  //     } else if (selectedTags.contains('start position')) {
  //       filtered = _plans.where((plan) => plan.tags.isNotEmpty && plan.from.isEmpty).toList();
  //     } else {
  //       filtered = _plans.where((plan) {
  //         // Only include plans that have tags
  //         if (plan.tags.isEmpty) return false;
  //
  //         // Case-insensitive check: all selectedTags must be found in plan.tags
  //         return selectedTags.any((tag) =>
  //             plan.tags.any((planTag) => planTag.toLowerCase() == tag.toLowerCase())
  //         );
  //       }).toList();
  //     }
  //     print(selectedTags);
  //     // Apply folderId filter if it's not null or empty
  //     if (folderId != null && folderId.isNotEmpty) {
  //       filtered = filtered.where((plan) => plan.folderId == folderId).toList();
  //     }
  //
  //      if(filtered.isEmpty){
  //        AppAnalytics.logEmptyStateShown('tag');
  //      }
  //     _filteredPlans = filtered;
  //
  //     if (kDebugMode) {
  //       print(_filteredPlans);
  //     }
  //   }
  //
  //   notifyListeners();
  // }

  void applyTagFilter(List<String> selectedTags, String? folderId) {
    AppAnalytics.logFilterTagSelected(selectedTags.join(","));

    List<Plan> filtered = [];

    if (selectedTags.isEmpty) {
      _plans = List.from(_allPlans); // No tag filter: reset to all plans
    } else {
      // Start with the full list
      List<Plan> sourceList = List.from(_allPlans);

      if (selectedTags.contains('all')) {
        filtered = sourceList;
      } else if (selectedTags.contains('start position')) {
        filtered = sourceList
            .where(
              (plan) => plan.tags.isNotEmpty && plan.from.isEmpty,
            )
            .toList();
      } else {
        filtered = sourceList.where((plan) {
          if (plan.tags.isEmpty) return false;

          return selectedTags.any((tag) => plan.tags
              .any((planTag) => planTag.toLowerCase() == tag.toLowerCase()));
        }).toList();
      }

      // Apply folderId filter if provided
      if (folderId != null && folderId.isNotEmpty) {
        filtered = filtered.where((plan) => plan.folderId == folderId).toList();
      }

      if (filtered.isEmpty) {
        AppAnalytics.logEmptyStateShown('tag');
      }

      _plans = filtered;
    }

    if (kDebugMode) {
      print('Filtered plans (tags): $_plans');
    }

    notifyListeners();
  }

  Future<void> updatePlanStatus(Plan plan, String value) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String userId =
        prefs.getString("user_name") ?? ''; // ✅ Prevent null issues

    try {
      await _plansRef.child(plan.id).update({
        'status': value,
      });

      // ✅ Update only specific fields while keeping existing references
      final index = _plans.indexWhere((item) => item.id == plan.id);
      if (index != -1) {
        _plans[index].status = value;
        // _filteredPlans[index].status = value;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error updating plan: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetVideoEntries() {
    _videoEntries = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    resetVideoEntries();
    super.dispose();
  }

  Future<void> addPlan(
      {required String title,
      required String description,
      required List<VideoEntry> videos,
      required List<String> tags,
      String? parentId, // ID of the parent card
      required bool isConnection, // Determines if this plan is a child
      String? collectionId}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';
    final String planId = _plansRef.child(userId).push().key!;

    List<String> uploadedImageUrls = [];

    if (_selectedImages.isNotEmpty) {
      uploadedImageUrls = await _imageService.uploadImages(_selectedImages);
    }

    Plan newPlan = Plan(
        id: planId,
        userId: userId,
        title: title,
        description: description,
        videos: videos,
        tags: tags,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        from: isConnection && parentId != null ? [parentId] : [],
        to: [],
        images: uploadedImageUrls,
        folderId: collectionId ?? '');

    await _plansRef.child(planId).set(newPlan.toMap());

    if (isConnection && parentId != null) {
      await updateConnections(userId, parentId, planId);
    }

    _plans.add(newPlan);
    // _filteredPlans.add(newPlan);
    AppAnalytics.logCardCreated(planId);
    _plans = _plans..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    // _filteredPlans = _filteredPlans..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _allPlans = [];
    _allPlans.addAll(_plans);
    resetVideoEntries();
    _selectedImages = [];
    updateAllTags();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updatePlan(Plan updatedPlan) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';

    List<String> uploadedImageUrls = [];

    if (_selectedImages.isNotEmpty) {
      // Separate local and firebase images
      List<SelectedImage> localImages =
          _selectedImages.where((img) => img.localFile != null).toList();
      List<SelectedImage> firebaseImages =
          _selectedImages.where((img) => img.url != null).toList();

      // Upload new images
      List<String> newUploadedUrls = [];
      if (localImages.isNotEmpty) {
        newUploadedUrls = await _imageService.uploadImages(localImages);
      }

      // Merge firebase existing URLs and newly uploaded URLs
      uploadedImageUrls = [
        ...firebaseImages.map((img) => img.url!),
        ...newUploadedUrls,
      ];
    }
    _finalUploadImages = uploadedImageUrls;
    try {
      await _plansRef.child(updatedPlan.id).update({
        'title': updatedPlan.title,
        'userId': updatedPlan.userId,
        'description': updatedPlan.description,
        'videos': updatedPlan.videos!.map((video) => video.toMap()).toList(),
        'tags': updatedPlan.tags,
        'folderId': updatedPlan.folderId,
        'images': uploadedImageUrls,
      });

      final index = _plans.indexWhere((plan) => plan.id == updatedPlan.id);
      if (index != -1) {
        _plans[index] = Plan(
          id: updatedPlan.id,
          userId: updatedPlan.userId,
          title: updatedPlan.title,
          description: updatedPlan.description,
          videos: updatedPlan.videos!.map((v) => v.copyWith()).toList(),
          tags: updatedPlan.tags,
          folderId: updatedPlan.folderId,
          images: uploadedImageUrls,
          timestamp: updatedPlan.timestamp,
          from: List.from(_plans[index].from),
          to: List.from(_plans[index].to),
        );
        _allPlans = [];
        _allPlans.addAll(_plans);
      }
      AppAnalytics.logCardEdited(updatedPlan.id);
      resetVideoEntries();
      updateAllTags();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error updating plan: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Plan?> updatedPlan(Plan updatedPlan) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';

    List<String> uploadedImageUrls = [];

    if (_selectedImages.isNotEmpty) {
      // Separate local and firebase images
      List<SelectedImage> localImages =
          _selectedImages.where((img) => img.localFile != null).toList();
      List<SelectedImage> firebaseImages =
          _selectedImages.where((img) => img.url != null).toList();

      // Upload new images
      List<String> newUploadedUrls = [];
      if (localImages.isNotEmpty) {
        newUploadedUrls = await _imageService.uploadImages(localImages);
      }

      // Merge firebase existing URLs and newly uploaded URLs
      uploadedImageUrls = [
        ...firebaseImages.map((img) => img.url!),
        ...newUploadedUrls,
      ];
    }
    _finalUploadImages = uploadedImageUrls;
    try {
      await _plansRef.child(updatedPlan.id).update({
        'title': updatedPlan.title,
        'userId': updatedPlan.userId,
        'description': updatedPlan.description,
        'videos': updatedPlan.videos!.map((video) => video.toMap()).toList(),
        'tags': updatedPlan.tags,
        'folderId': updatedPlan.folderId,
        'images': uploadedImageUrls,
      });

      final index = _plans.indexWhere((plan) => plan.id == updatedPlan.id);
      if (index != -1) {
        _plans[index] = Plan(
          id: updatedPlan.id,
          userId: updatedPlan.userId,
          title: updatedPlan.title,
          description: updatedPlan.description,
          videos: updatedPlan.videos!.map((v) => v.copyWith()).toList(),
          tags: updatedPlan.tags,
          folderId: updatedPlan.folderId,
          images: uploadedImageUrls,
          timestamp: updatedPlan.timestamp,
          from: List.from(_plans[index].from),
          to: List.from(_plans[index].to),
        );
        // _filteredPlans[index] = _plans[index];
        _allPlans = [];
        _allPlans.addAll(_plans);
      }
      AppAnalytics.logCardEdited(updatedPlan.id);
      resetVideoEntries();
      updateAllTags();
      _isLoading = false;
      notifyListeners();
      return _plans[index];
    } catch (e) {
      print('Error updating plan: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> updatePlanNote(String planId, String note) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';

    try {
      await _plansRef.child(planId).update({'note': note});

      final index = _plans.indexWhere((plan) => plan.id == planId);
      if (index != -1) {
        _plans[index].note = note;
        // _filteredPlans[index].note = note;
        _allPlans = [];
        _allPlans.addAll(_plans);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error updating plan: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlan(String planId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';

    // Find the plan
    final planToDelete = _plans.isNotEmpty
        ? _plans.firstWhere(
            (plan) => plan.id == planId,
            orElse: () => Plan.empty(),
          )
        : null;

    if (planToDelete == null || planToDelete.id.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Remove the plan from Firebase
    await _plansRef.child(planId).remove();

    for (var plan in _plans) {
      plan.from = List.from(plan.from)..remove(planId);
      plan.to = List.from(plan.to)..remove(planId);
    }

    // Ensure _plans is a modifiable list before removing
    _plans = List.from(_plans)..removeWhere((plan) => plan.id == planId);
    // _filteredPlans.removeWhere((plan) => plan.id == planId);
    _allPlans = [];
    _allPlans.addAll(_plans);
    updateAllTags();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateConnections(
      String userId, String parentId, String childId) async {
    try {
      // Add childId to parent's "to" list
      await _plansRef.child('$parentId/to').update({
        childId: true,
      });

      // Add parentId to child's "from" list
      await _plansRef.child('$childId/from').update({
        parentId: true,
      });

      // Update local cache
      final parentIndex = _plans.indexWhere((plan) => plan.id == parentId);
      if (parentIndex != -1) {
        _plans[parentIndex].to.add(childId);
        // _filteredPlans[parentIndex].to.add(childId);
      }
      final childIndex = _plans.indexWhere((plan) => plan.id == childId);
      if (childIndex != -1) {
        _plans[childIndex].from.add(parentId);
        // _filteredPlans[childIndex].from.add(parentId);
      }
      _allPlans = [];
      _allPlans.addAll(_plans);
      notifyListeners();
    } catch (e) {
      print('Error updating connections: $e');
    }
  }

  Future<void> updateConnections2(
      String userId, List<String> parentIds, String childId) async {
    try {
      for (String parentId in parentIds) {
        // Add childId to parent's "to" list
        await _plansRef.child('$parentId/to').update({
          childId: true,
        });

        // Add parentId to child's "from" list
        await _plansRef.child('$childId/from').update({
          parentId: true,
        });

        // Update local cache
        final parentIndex = _plans.indexWhere((plan) => plan.id == parentId);
        if (parentIndex != -1) {
          _plans[parentIndex].to.add(childId);
          // _filteredPlans[parentIndex].to.add(childId);
        }
      }

      // Update local cache for the child only once
      final childIndex = _plans.indexWhere((plan) => plan.id == childId);
      if (childIndex != -1) {
        _plans[childIndex].from.addAll(parentIds);
        //_filteredPlans[childIndex].from.addAll(parentIds);
      }
      _allPlans = [];
      _allPlans.addAll(_plans);
      notifyListeners();
    } catch (e) {
      print('Error updating connections: $e');
    }
  }

  Future<void> linkPlans(
      {required String parentId, required String childId}) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';

    final DatabaseReference parentRef = _plansRef.child(parentId);
    final DatabaseReference childRef = _plansRef.child(childId);

    // Add childId to parent's "To" list
    await parentRef.child("to").push().set(childId);

    // Add parentId to child's "From" list
    await childRef.child("from").push().set(parentId);

    notifyListeners();
  }

  Future<void> removeLink(
      {required String parentId, required String childId}) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = prefs.getString("user_name") ?? '';

    final DatabaseReference parentRef = _plansRef.child("$parentId/to");
    final DatabaseReference childRef = _plansRef.child("$childId/from");

    // Find and remove childId from parent's "To" list
    final parentSnapshot = await parentRef.once();
    if (parentSnapshot.snapshot.value != null) {
      Map<dynamic, dynamic> parentData = parentSnapshot.snapshot.value as Map;
      for (var key in parentData.keys) {
        if (parentData[key] == childId) {
          await parentRef.child(key).remove();
          break;
        }
      }
    }

    // Find and remove parentId from child's "From" list
    final childSnapshot = await childRef.once();
    if (childSnapshot.snapshot.value != null) {
      Map<dynamic, dynamic> childData = childSnapshot.snapshot.value as Map;
      for (var key in childData.keys) {
        if (childData[key] == parentId) {
          await childRef.child(key).remove();
          break;
        }
      }
    }

    notifyListeners();
  }

  List<Plan> getParentPlans(String planId) {
    return _plans.where((plan) => plan.to.contains(planId)).toList();
  }

  List<Plan> getChildPlans(String parentId) {
    return _plans.where((plan) => plan.from.contains(parentId)).toList();
  }
}
