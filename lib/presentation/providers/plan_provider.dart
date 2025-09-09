import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:bjj_dairy/core/utils.dart';
import 'package:bjj_dairy/presentation/providers/validation_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_analytics.dart';
import '../../data/services/image_service.dart';
import '../../domain/entities/comment.dart';
import '../../domain/entities/favourite.dart';
import '../../domain/entities/folder.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/selected_image.dart';
import '../../domain/entities/video_entry.dart';
import '../../domain/repositories/plan_repository.dart';


class PlanProvider with ChangeNotifier {

  final PlanRepository _planRepository;

  PlanProvider(this._planRepository);

  final DatabaseReference _plansRef =
      FirebaseDatabase.instance.ref().child('PLANS/');
  final DatabaseReference _foldersRef =
      FirebaseDatabase.instance.ref().child('FOLDERS/');
  final DatabaseReference _shareIdsRef =
  FirebaseDatabase.instance.ref().child('SHARE_IDS/');
  final DatabaseReference _favouritesRef = FirebaseDatabase.instance.ref().child('FAVOURITES/');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _suggestedTags = [
    'submissions',
    'escapes',
    'pressure',
    'defense'
  ];

  String _loggedUserId = '';
  String get loggedUserId => _loggedUserId;
  List<Plan> _allPlans = [];
  List<Plan> _plans = [];
  List<Plan> _favouritesPlans = [];
  List<Plan> _sharedFolderPlans = [];
  List<Folder> _folders = [];
  List<Folder> _searchFolders = [];

  List<Folder> get folders => _folders;
  List<Folder> get searchFolders => _searchFolders;
  bool _isLoading = false;
  List<Plan> _filteredPlans = [];

  List<Plan> get sharedFolderPlans => _sharedFolderPlans;
  List<Plan> get plans => _plans;
  List<Plan> get favouritesPlans => _favouritesPlans;
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
  bool _isFolderAccessValid = false;
  bool get isFolderAccessValid => _isFolderAccessValid;
  StreamSubscription<DatabaseEvent>? _plansSubscription;

  Future<void> resetLoggedId()async {
    _loggedUserId = '';
    notifyListeners();
  }

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
    // final user = _auth.currentUser;
    // if (user == null) return;
    //
    // final prefs = await SharedPreferences.getInstance();
    // final String userId = prefs.getString("user_name") ?? '';

    _isLoading = true;
    notifyListeners();

    try {
      for (String planId in selectedPlanIds) {
        final index = _plans.indexWhere((plan) => plan.id == planId);
        if (index != -1) {
          Plan currentPlan = _plans[index];

          // ✅ use repository instead of Firebase directly
          await _planRepository.updatePlanFolder(currentPlan.id, fId);

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

  List<String> getAllCollectionTags(String cid,{bool isShared = false}) {
    final list = isShared ? [..._sharedFolderPlans,..._favouritesPlans] : [..._plans,..._favouritesPlans];
    final allTags = list
        .where((plan) => plan.folderId == cid || plan.isShared)
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

  int getPlanCountForFolder(Folder folder) {
    if (folder.name!.toLowerCase() == 'favourites') {
      return _allPlans.where((plan) => plan.folderId == folder.id).length + _favouritesPlans.length;
    } else {
      return _allPlans.where((plan) => plan.folderId == folder.id).length;
    }
  }

  Future<int> getPlanCountForSearchFolder(Folder folder) async {
    try {
      return await _planRepository.getPlanCountForFolder(folder.id!);
    } catch (e) {
      print('Error fetching plans for folder ${folder.id}: $e');
      return 0;
    }
    // try {
    //   final snapshot = await _plansRef
    //       .orderByChild('folderId')
    //       .equalTo(folder.id)
    //       .get();
    //
    //   if (snapshot.exists && snapshot.value is Map) {
    //     final Map data = snapshot.value as Map;
    //     return data.length;
    //   }
    //
    //   return 0;
    // } catch (e) {
    //   print('Error fetching plans for folder ${folder.id}: $e');
    //   return 0;
    // }
  }

  Future<bool> isShareIdUnique(String shareId) async {
    try {
      return await _planRepository.isShareIdUnique(shareId);
    } catch (e) {
      print('Error checking shareId $shareId: $e');
      return false;
    }
  }


  Future<void> createFolder(String name) async {
    // final prefs = await SharedPreferences.getInstance();
    final String userId = await _planRepository.getUserId() as String;//prefs.getString("user_name") as String;
    final String folderId = _foldersRef.child(userId).push().key!;

    // Generate a unique shareId
    String shareId;
    do {
      shareId = Util.generateRandomShareId();
    } while (!(await _planRepository.isShareIdUnique(shareId)));

    final newFolder = Folder(
      id: folderId,
      userId: userId,
      name: name,
      order: _folders.length,
      shareId: shareId,
      access: 'private', // default access
      allowedUsers: [], // initially empty
    );

    // ✅ Use repository to persist
    await _planRepository.createFolder(newFolder);
    _folders.add(newFolder);
    notifyListeners();
  }

  Future<void> updateFolderAccess(String folderId, String accessType, {List<String>? allowedUsers}) async {
    // ✅ use repository instead of direct Firebase
    await _planRepository.updateFolderAccess(
      folderId,
      accessType,
      allowedUsers: allowedUsers,
    );

    final index = _folders.indexWhere((folder) => folder.id == folderId);
    if (index != -1) {
      final updated = _folders[index].copyWith(
        access: accessType,
        allowedUsers: accessType == 'specific' ? (allowedUsers ?? []) : [],
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

  Future<void> _addShareIdIfMissing(String folderId) async {
    // Generate a unique shareId
    String shareId;
    do {
      shareId = Util.generateRandomShareId();
    } while (!(await _planRepository.isShareIdUnique(shareId)));

    // ✅ delegate persistence to repository
    await _planRepository.addShareIdIfMissing(folderId, shareId);
  }

  Future<void> fetchFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = await _planRepository.getUserId() as String;//prefs.getString('user_name') ?? '';

    // ✅ Fetch folders using repository
    List<Folder> fetched = await _planRepository.fetchFolders(userId);

    // ── 1. Check for Favourites folder ─────────────────────
    bool hasFavourites = fetched.any(
          (f) => (f.name?.toLowerCase() == 'favourites'),
    );

    if (!hasFavourites) {
      await _createDefaultFavouritesFolder(userId);
    }

    // ── 2. Ensure every folder has shareId ─────────────────
    final List<Future<void>> pendingUpdates = [];
    for (final folder in fetched) {
      if (folder.shareId!.isEmpty) {
        pendingUpdates.add(_addShareIdIfMissing(folder.id!));
      }
    }
    if (pendingUpdates.isNotEmpty) await Future.wait(pendingUpdates);

    // ── 3. Update local state ──────────────────────────────
    _folders = fetched;
    notifyListeners();
  }

  Future<void> _createDefaultFavouritesFolder(String userId) async {
    final String folderId = _foldersRef.child(userId).push().key!;

    // Generate a unique shareId
    String shareId;
    do {
      shareId = Util.generateRandomShareId();
    } while (!(await _planRepository.isShareIdUnique(shareId)));

    final newFolder = Folder(
      id: folderId,
      userId: userId,
      name: 'Favourites',
      order: _folders.length,
      shareId: shareId,
      access: 'private',
      allowedUsers: [],
    );

    _folders.add(newFolder);

    // ✅ use repository instead of direct Firebase
    await _planRepository.createFolder(newFolder);
  }

  Future<void> searchPublicFolders(String shareId) async {
    try {
      final fetched = await _planRepository.fetchFoldersByShareId(shareId);

      _searchFolders = fetched
          .where((f) =>
      f.access == 'public' ||
          (f.access == 'specific' && f.allowedUsers.contains(_loggedUserId)))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      print('Access value: ${_searchFolders.length}');
    } catch (e) {
      print('Error searching public folders for $shareId: $e');
      _searchFolders = [];
    }

    notifyListeners();
  }

  Future<void> copySharedFolderWithTechniques(Folder folder) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = await _planRepository.getUserId() as String;//prefs.getString("user_name") as String;

    // ── Step 1: Check if folder with same name already exists ──
    Folder? existingFolder =
    await _planRepository.findByName(userId, folder.name ?? '');

    String targetFolderId;
    if (existingFolder != null) {
      targetFolderId = existingFolder.id!;
    } else {
      // Generate unique shareId
      String shareId;
      do {
        shareId = Util.generateRandomShareId();
      } while (!(await _planRepository.isUnique(shareId)));

      // Create folder
      final newFolderId = _foldersRef.push().key!;
      final newFolder = Folder(
        id: newFolderId,
        userId: userId,
        name: folder.name,
        order: _folders.length,
        shareId: shareId,
        access: 'private',
        allowedUsers: [],
      );

      await _planRepository.createFolder(newFolder);
      await _planRepository.saveShareId(shareId, newFolderId);

      _folders.add(newFolder);
      notifyListeners();

      targetFolderId = newFolderId;
    }

    // ── Step 2: Fetch + clone plans ──
    final Set<String> loadedPlanIds = {}; // track connected planIds
    final List<Plan> allPlans = [];

    final snapshot =
    await _plansRef.orderByChild('folderId').equalTo(folder.id).get();

    if (snapshot.exists && snapshot.value != null) {
      final rawData = snapshot.value;
      debugPrint("Fetched Data: $rawData");

      if (rawData is Map<Object?, Object?>) {
        for (final entry in rawData.entries) {
          final value = entry.value;
          if (value is Map<Object?, Object?>) {
            final data = value.map((k, v) => MapEntry(k.toString(), v));
            final plan = Plan.fromMap(data);

            allPlans.add(plan);
            debugPrint("Main Plan: ${plan.id}");

            // 🔹 Optionally fetch related parent plans
            // for (String parentId in plan.to) {
            //   if (loadedPlanIds.add(parentId)) {
            //     await fetchSinglePlanById(parentId, allPlans);
            //   }
            // }

            // 🔹 Optionally fetch related child plans
            // for (String childId in plan.from) {
            //   if (loadedPlanIds.add(childId)) {
            //     await fetchSinglePlanById(childId, allPlans);
            //   }
            // }
          }
        }
      }
    }

    // ── Step 3: Clone plans into target folder ──
    for (final plan in allPlans) {
      if (plan.folderId != folder.id) continue;

      final String newPlanId = _plansRef.push().key!;

      final Plan newPlan = Plan(
        id: newPlanId,
        userId: userId,
        title: plan.title,
        description: plan.description,
        videos: List<VideoEntry>.from(plan.videos!),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        // from: plan.from,   // enable later if you want relation cloning
        // to: plan.to,
        isExpanded: false,
        tags: List<String>.from(plan.tags),
        status: plan.status,
        images: List<String>.from(plan.images),
        note: plan.note,
        folderId: targetFolderId,
      );

      _plans.add(newPlan);
      await _plansRef.child(newPlanId).set(newPlan.toMap());
    }

    _plans.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> deleteFolder(Folder f) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = await _planRepository.getUserId() as String;//prefs.getString("user_name") as String;

    // ── 1. Delete folder & shareId in Firebase ──
    await _planRepository.deleteFolder(f.id!);
    await _planRepository.deleteShareId(f.shareId!);

    // ── 2. Remove from local folder list ──
    _folders.removeWhere((folder) => folder.id == f.id);

    // ── 3. Update local plans & clear folderId in Firebase ──
    for (var plan in _plans) {
      if (plan.folderId == f.id) {
        plan.folderId = "";
      }
    }
    await _planRepository.clearFolderFromPlans(userId, f.id!);

    notifyListeners();
  }


  Future<void> updateFolder(String folderId, String newName) async {
    try {
      await _planRepository.updateFolderName(folderId, newName);

      final index = _folders.indexWhere((folder) => folder.id == folderId);
      if (index != -1) {
        _folders[index] = _folders[index].copyWith(name: newName);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating folder name for $folderId: $e');
    }
  }

  void reorderFolders(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final folder = _folders.removeAt(oldIndex);
    _folders.insert(newIndex, folder);

    // Update order in memory + Firebase
    for (int i = 0; i < _folders.length; i++) {
      final updated = _folders[i].copyWith(order: i);
      _folders[i] = updated;

      try {
        await _planRepository.updateFolderOrder(updated.id!, i);
      } catch (e) {
        print('Error updating order for folder ${updated.id}: $e');
      }
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
        // if (_selectedImages.length + pickedImages.length > 5) {
        //   await _validationProvider.updateImageError();
        //   return;
        // }
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
        // if(_selectedImages.length + pickedImages.length > 5)
        // {
        //   await _validationProvider.updateImageError();
        //   return plan;
        // }
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

  Future<void> likePlan(String planId, String userId, {bool isShared = false}) async {
    final targetLists = isShared
        ? [_sharedFolderPlans, _favouritesPlans]
        : [_plans, _favouritesPlans];

    for (var list in targetLists) {
      final index = list.indexWhere((p) => p.id == planId);
      if (index != -1) {
        final plan = list[index];

        if (!plan.likedBy.contains(userId)) {
          // 🔹 Update local state immutably
          final updated = plan.copyWith(
            likedBy: [...plan.likedBy, userId],
          );
          list[index] = updated;
          notifyListeners();

          try {
            await _planRepository.updateLikedBy(planId, updated.likedBy);
          } catch (e) {
            print('Error updating likes for $planId: $e');
          }
        }
        break; // Stop after first match
      }
    }
  }

  Future<void> toggleFavourite(String planId, String userId, bool isShared) async {
    final targetLists = isShared
        ? [_sharedFolderPlans, _favouritesPlans]
        : [_plans, _favouritesPlans];

    for (var list in targetLists) {
      final index = list.indexWhere((p) => p.id == planId);
      if (index != -1) {
        final plan = list[index];
        final isFavourited = plan.favouritedBy.contains(userId);

        // 🔹 Update local state immutably
        final updatedPlan = plan.copyWith(
          favouritedBy: isFavourited
              ? plan.favouritedBy.where((id) => id != userId).toList()
              : [...plan.favouritedBy, userId],
        );
        list[index] = updatedPlan;
        notifyListeners();

        try {
          // 🔹 Update plan in Firebase
          await _planRepository.updateFavouritedBy(planId, updatedPlan.favouritedBy);

          // 🔹 Sync favourites node
          if (isFavourited) {
            await _planRepository.removeFavouriteByPlanId(userId, planId);
          } else {
            final String id = _favouritesRef.push().key!;
            final favourite = Favourite(id: id, userId: userId, planId: planId);
            await _planRepository.addFavourite(favourite);
          }
        } catch (e) {
          print('Error toggling favourite for $planId: $e');
        }

        break;
      }
    }

    // 🔹 Refresh favourites list
    await fetchFavouritesPlans();
  }

  Future<void> addComment(String planId, String userId, String username, String text, {bool isShared = false,}) async {
    final String commentId = _plansRef.child('$planId/comments').push().key!;
    final comment = Comment(
      id: commentId,
      userId: userId,
      username: username,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // 🔹 Update local state immutably
    final targetLists =
    isShared ? [_sharedFolderPlans, _favouritesPlans] : [_plans, _favouritesPlans];

    for (var list in targetLists) {
      final index = list.indexWhere((p) => p.id == planId);
      if (index != -1) {
        list[index] = list[index].copyWith(
          comments: [comment, ...list[index].comments],
        );
        notifyListeners();
        break;
      }
    }

    try {
      // 🔹 Save to Firebase via repository
      await _planRepository.addComment(planId, comment);
    } catch (e) {
      print('Error adding comment to $planId: $e');
    }
  }

  Future<void> deleteComment(String planId, String commentId) async {
    final index = _plans.indexWhere((plan) => plan.id == planId);
    if (index == -1) return;

    // 🔹 Update local state immutably
    final plan = _plans[index];
    final updatedComments =
    plan.comments.where((c) => c.id != commentId).toList();

    _plans[index] = plan.copyWith(comments: updatedComments);
    notifyListeners();

    try {
      // 🔹 Delete from Firebase via repository
      await _planRepository.deleteComment(planId, commentId);
    } catch (e) {
      print('Error deleting comment $commentId from plan $planId: $e');
    }
  }

  Future<void> fetchShareFolderPlans(String folderId) async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) {
      _sharedFolderPlans = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    final List<Plan> allPlans = [];

    try {
      final snapshot =
      await _plansRef.orderByChild('folderId').equalTo(folderId).get();

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint("No plans found for folder: $folderId");
        _sharedFolderPlans = [];
        return;
      }

      final rawData = snapshot.value;

      if (rawData is! Map<Object?, Object?>) {
        debugPrint("Fetched data is not a valid Map: $rawData");
        _sharedFolderPlans = [];
        return;
      }

      for (final entry in rawData.entries) {
        final value = entry.value;
        if (value is Map<Object?, Object?>) {
          final data = value.map((k, v) => MapEntry(k.toString(), v));
          final plan = Plan.fromMap(data);

          allPlans.add(plan);
          debugPrint("Fetched Plan: ${plan.id}");
        }
      }

      _sharedFolderPlans = allPlans
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e, stackTrace) {
      debugPrint("Error fetching plans for folder $folderId: $e\n$stackTrace");
      AppAnalytics.logErrorStateShown('404');
      _sharedFolderPlans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<Plan>?> fetchPlansForGenerateMap(String folderId) async {
    _isLoading = true;
    notifyListeners();

    final user = _auth.currentUser;
    if (user == null) return null;

    final Set<String> loadedPlanIds = {}; // Tracks connected plan IDs
    final List<Plan> allPlans = [];

    try {
      // Step 1: Fetch main plans for the folder
      final snapshot =
      await _plansRef.orderByChild('folderId').equalTo(folderId).get();

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint("No plans found for folder: $folderId");
        return [];
      }

      final rawData = snapshot.value;
      if (rawData is! Map<Object?, Object?>) {
        debugPrint("Fetched data is not a valid Map: $rawData");
        return [];
      }

      for (final entry in rawData.entries) {
        final value = entry.value;
        if (value is Map<Object?, Object?>) {
          final data = value.map((k, v) => MapEntry(k.toString(), v));
          final plan = Plan.fromMap(data);

          allPlans.add(plan); // Always add the main plan
          debugPrint("Main Plan: ${plan.id}");

          // Step 2: Fetch parent plans using `plan.to`
          for (final parentId in plan.to) {
            if (loadedPlanIds.add(parentId)) {
              await fetchSinglePlanById(parentId, allPlans);
            }
          }

          // Step 3: Fetch child plans using `plan.from`
          for (final childId in plan.from) {
            if (loadedPlanIds.add(childId)) {
              await fetchSinglePlanById(childId, allPlans);
            }
          }
        }
      }

      // Sort once at the end
      allPlans.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return allPlans;
    } catch (e, stackTrace) {
      debugPrint("Error fetching plans for folder $folderId: $e\n$stackTrace");
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkFolderPermission(String userId, String folderId) async {
    try {
      final snapshot = await _foldersRef.child(folderId).get();

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint("❌ Folder not found: $folderId");
        _isFolderAccessValid = false;
        return false;
      }

      final rawData = snapshot.value;
      if (rawData is! Map) {
        debugPrint("⚠️ Invalid folder data format for folderId: $folderId");
        _isFolderAccessValid = false;
        return false;
      }

      final data = Map<String, dynamic>.from(rawData);
      final folder = Folder.fromMap(data);

      // 🔹 1. Public access
      if (folder.access == 'public') {
        _isFolderAccessValid = true;
        return true;
      }

      // 🔹 2. Specific access with allowed user
      if (folder.access == 'specific' && folder.allowedUsers.contains(userId)) {
        _isFolderAccessValid = true;
        return true;
      }

      // 🔹 3. Folder owner always has access
      if (folder.userId == userId) {
        _isFolderAccessValid = true;
        return true;
      }

      // 🔹 4. Access denied
      _isFolderAccessValid = false;
      debugPrint("🚫 Access denied for user $userId on folder $folderId");
      return false;
    } catch (e, stackTrace) {
      debugPrint("🔥 Error checking folder permission: $e\n$stackTrace");
      _isFolderAccessValid = false;
      return false;
    }
  }

  Future<void> fetchSinglePlanById(String planId, List<Plan> allPlans) async {
    try {
      final snapshot = await _plansRef.child(planId).get();

      if (!snapshot.exists || snapshot.value == null) {
        debugPrint("⚠️ Plan not found: $planId");
        return;
      }

      final rawData = snapshot.value;
      if (rawData is! Map) {
        debugPrint("⚠️ Invalid data format for plan $planId: $rawData");
        return;
      }

      final data = Map<String, dynamic>.from(rawData);
      final plan = Plan.fromMap(data);

      allPlans.add(plan);
      debugPrint("✅ Fetched connected plan: ${plan.id}");
    } catch (e, stackTrace) {
      debugPrint("🔥 Failed to fetch plan $planId: $e\n$stackTrace");
    }
  }

  Future<void> fetchPlans() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = await _planRepository.getUserId() as String;//prefs.getString("user_name") ?? '';
    _loggedUserId = userId;

    _isLoading = true;
    _allPlans.clear();
    _plans.clear();
    _filteredPlans.clear();
    notifyListeners();

    try {
      final fetchedPlans = await _planRepository.fetchPlansByUserId(userId);

      _plans = fetchedPlans;
      _allPlans.addAll(fetchedPlans);

      updateAllTags();
    } catch (e, stackTrace) {
      debugPrint("🔥 Error fetching plans: $e\n$stackTrace");
      AppAnalytics.logErrorStateShown('404');
      _plans = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFavouritesPlans() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String userId = await _planRepository.getUserId() as String;//prefs.getString("user_name") ?? '';

    _isLoading = true;
    _favouritesPlans.clear();
    notifyListeners();

    try {
      final fetchedPlans = await _planRepository.fetchFavouritesByUserId(userId);
      _favouritesPlans = fetchedPlans;
      updateAllTags();
    } catch (e, stackTrace) {
      debugPrint("🔥 Error fetching favourites: $e\n$stackTrace");
      AppAnalytics.logErrorStateShown('404');
      _favouritesPlans = [];
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
    for (var plan in _favouritesPlans) {
      _allTags.addAll(plan.tags);
    }
    _allTags = _allTags.toSet().toList();
    notifyListeners();
  }

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

    try {
      await _planRepository.updatePlanStatus(plan.id, value);

      // ✅ Update only local state after successful repository update
      final index = _plans.indexWhere((item) => item.id == plan.id);
      if (index != -1) {
        _plans[index].status = value;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('🔥 Error updating plan status: $e');
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
    _plansSubscription?.cancel();
    resetVideoEntries();
    super.dispose();
  }

  Future<void> addPlan({required String title, required String description, required List<VideoEntry> videos, required List<String> tags, String? parentId, required bool isConnection, String? collectionId,}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final String userId = await _planRepository.getUserId() as String; //prefs.getString("user_name") ?? '';
      final String planId = _plansRef.child(userId).push().key!;

      // Upload images if any
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        uploadedImageUrls = await _imageService.uploadImages(_selectedImages);
      }

      final newPlan = Plan(
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
        folderId: collectionId ?? '',
      );

      // ✅ Save using repository
      await _planRepository.addPlan(newPlan);

      // ✅ Maintain connections if needed
      if (isConnection && parentId != null) {
        await updateConnections(userId, parentId, planId);
      }

      // ✅ Local state update
      _plans.add(newPlan);
      AppAnalytics.logCardCreated(planId);
      _plans.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _allPlans
        ..clear()
        ..addAll(_plans);

      resetVideoEntries();
      _selectedImages = [];
      updateAllTags();
    } catch (e) {
      debugPrint("🔥 Error adding plan: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlan(Plan updatedPlan) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // ✅ Handle images
      List<String> uploadedImageUrls = [];
      if (_selectedImages.isNotEmpty) {
        final localImages =
        _selectedImages.where((img) => img.localFile != null).toList();
        final firebaseImages =
        _selectedImages.where((img) => img.url != null).toList();

        List<String> newUploadedUrls = [];
        if (localImages.isNotEmpty) {
          newUploadedUrls = await _imageService.uploadImages(localImages);
        }

        uploadedImageUrls = [
          ...firebaseImages.map((img) => img.url!),
          ...newUploadedUrls,
        ];
      } else {
        uploadedImageUrls = updatedPlan.images;
      }

      _finalUploadImages = uploadedImageUrls;

      // ✅ Build updated plan
      final newPlan = updatedPlan.copyWith(images: uploadedImageUrls);

      // ✅ Persist via repository
      await _planRepository.updatePlan(newPlan);

      // ✅ Update in-memory state
      final index = _plans.indexWhere((plan) => plan.id == newPlan.id);
      if (index != -1) {
        _plans[index] = newPlan;
        _allPlans
          ..clear()
          ..addAll(_plans);
      }

      AppAnalytics.logCardEdited(newPlan.id);
      resetVideoEntries();
      updateAllTags();
    } catch (e) {
      debugPrint("🔥 Error updating plan: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Plan?> updatedPlan(Plan updatedPlan) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    _isLoading = true;
    notifyListeners();

    try {
      // ✅ Start with existing images
      List<String> uploadedImageUrls = List.from(updatedPlan.images);

      if (_selectedImages.isNotEmpty) {
        final localImages =
        _selectedImages.where((img) => img.localFile != null).toList();
        final firebaseImages =
        _selectedImages.where((img) => img.url != null).toList();

        // Upload new local images
        final newUploadedUrls = localImages.isNotEmpty
            ? await _imageService.uploadImages(localImages)
            : [];

        // ✅ Merge old + firebase + new (avoid duplicates)
        uploadedImageUrls = ({
          ...uploadedImageUrls,
          ...firebaseImages.map((img) => img.url!),
          ...newUploadedUrls,
        }).toList().cast<String>();
      }

      _finalUploadImages = uploadedImageUrls;

      // ✅ Create updated plan
      final newPlan = updatedPlan.copyWith(images: uploadedImageUrls);

      // ✅ Save to Firebase via repository
      await _planRepository.updatePlan(newPlan);

      // ✅ Update local state
      final index = _plans.indexWhere((plan) => plan.id == newPlan.id);
      if (index != -1) {
        _plans[index] = newPlan;
        _allPlans
          ..clear()
          ..addAll(_plans);
      }

      AppAnalytics.logCardEdited(newPlan.id);
      resetVideoEntries();
      updateAllTags();

      return newPlan;
    } catch (e) {
      debugPrint("🔥 Error updating plan: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePlanNote(String planId, String note) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // ✅ Save via repository
      await _planRepository.updateNote(planId, note);

      // ✅ Update local state
      final index = _plans.indexWhere((plan) => plan.id == planId);
      if (index != -1) {
        _plans[index] = _plans[index].copyWith(note: note);
        _allPlans
          ..clear()
          ..addAll(_plans);
      }
    } catch (e) {
      debugPrint("🔥 Error updating plan note: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePlan(String planId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // ✅ Remove from Firebase
      await _planRepository.deletePlan(planId);

      // ✅ Update connections (from/to references in other plans)
      for (var plan in _plans) {
        plan = plan.copyWith(
          from: List.from(plan.from)..remove(planId),
          to: List.from(plan.to)..remove(planId),
        );
      }

      // ✅ Remove from in-memory list
      _plans = _plans.where((plan) => plan.id != planId).toList();
      _allPlans
        ..clear()
        ..addAll(_plans);

      updateAllTags();
    } catch (e) {
      debugPrint("🔥 Error deleting plan: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateConnections(String userId, String parentId, String childId) async {
    try {
      // ✅ Update Firebase
      await _planRepository.updateConnections(parentId, childId);

      // ✅ Update parent in cache (copyWith instead of mutating)
      final parentIndex = _plans.indexWhere((plan) => plan.id == parentId);
      if (parentIndex != -1) {
        final parent = _plans[parentIndex];
        _plans[parentIndex] = parent.copyWith(
          to: List.from(parent.to)..add(childId),
        );
      }

      // ✅ Update child in cache (copyWith instead of mutating)
      final childIndex = _plans.indexWhere((plan) => plan.id == childId);
      if (childIndex != -1) {
        final child = _plans[childIndex];
        _plans[childIndex] = child.copyWith(
          from: List.from(child.from)..add(parentId),
        );
      }

      // ✅ Refresh derived lists
      _allPlans
        ..clear()
        ..addAll(_plans);

      notifyListeners();
    } catch (e) {
      debugPrint('🔥 Error updating connections: $e');
    }
  }

  Future<void> updateConnections2(String userId, List<String> parentIds, String childId) async {
    try {
      // 🔹 Batch Firebase updates
      for (final parentId in parentIds) {
        await _plansRef.child('$parentId/to').update({childId: true});
        await _plansRef.child('$childId/from').update({parentId: true});
      }

      // 🔹 Update local cache for parents
      for (final parentId in parentIds) {
        final parentIndex = _plans.indexWhere((plan) => plan.id == parentId);
        if (parentIndex != -1) {
          final parent = _plans[parentIndex];
          _plans[parentIndex] = parent.copyWith(
            to: List<String>.from(parent.to)..add(childId),
          );
        }
      }

      // 🔹 Update local cache for the child (all parentIds at once)
      final childIndex = _plans.indexWhere((plan) => plan.id == childId);
      if (childIndex != -1) {
        final child = _plans[childIndex];
        _plans[childIndex] = child.copyWith(
          from: List<String>.from(child.from)..addAll(parentIds),
        );
      }

      // 🔹 Rebuild derived state
      _allPlans
        ..clear()
        ..addAll(_plans);

      notifyListeners();
    } catch (e) {
      debugPrint('🔥 Error updating connections2: $e');
    }
  }

  Future<void> linkPlans({required String parentId, required String childId,}) async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = await _planRepository.getUserId() as String;//prefs.getString("user_name") ?? '';

    await _planRepository.linkPlans(
      parentId: parentId,
      childId: childId,
      userId: userId,
    );

    notifyListeners();
  }

  Future<void> removeLink({required String parentId, required String childId,}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String userId = await _planRepository.getUserId() as String;//prefs.getString("user_name") ?? '';

      await _planRepository.removeLink(
        parentId: parentId,
        childId: childId,
        userId: userId,
      );

      // 🔄 Local cache update (kept exactly as before)
      final parentIndex = _plans.indexWhere((plan) => plan.id == parentId);
      if (parentIndex != -1) {
        _plans[parentIndex].to.remove(childId);
      }

      final childIndex = _plans.indexWhere((plan) => plan.id == childId);
      if (childIndex != -1) {
        _plans[childIndex].from.remove(parentId);
      }

      _allPlans = [];
      _allPlans.addAll(_plans);
      notifyListeners();
    } catch (e) {
      print('Error removing link: $e');
    }
  }

  List<Plan> getParentPlans(String planId,bool isShared) {
    if(isShared){
      return _sharedFolderPlans.where((plan) => plan.to.contains(planId)).toList();
    }
    else{
      return _plans.where((plan) => plan.to.contains(planId)).toList();
    }
  }

  List<Plan> getChildPlans(String parentId,bool isShared) {
    if(isShared){
      return _sharedFolderPlans.where((plan) => plan.from.contains(parentId)).toList();
    }
    else{
      return _plans.where((plan) => plan.from.contains(parentId)).toList();
    }
  }
}
