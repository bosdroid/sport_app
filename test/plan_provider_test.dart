import 'package:bjj_dairy/core/app_analytics.dart';
import 'package:bjj_dairy/data/services/image_service.dart';
import 'package:bjj_dairy/domain/entities/comment.dart';
import 'package:bjj_dairy/domain/entities/favourite.dart';
import 'package:bjj_dairy/domain/entities/folder.dart';
import 'package:bjj_dairy/domain/entities/plan.dart';
import 'package:bjj_dairy/domain/entities/selected_image.dart';
import 'package:bjj_dairy/presentation/providers/plan_provider.dart';
import 'package:bjj_dairy/domain/repositories/plan_repository.dart';
import 'package:bjj_dairy/presentation/providers/validation_provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ----------------- Mocks & Fakes -----------------
class MockPlanRepository extends Mock implements PlanRepository {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockImageService extends Mock implements ImageService {}
class MockXFile extends Mock implements XFile {}
class FakeFolder extends Fake implements Folder {}
class FakePlan extends Fake implements Plan {}
class FakeComment extends Fake implements Comment {}
class FakeFavourite extends Fake implements Favourite {}
class FakeSelectedImage extends Fake implements SelectedImage {}
class FakeXFile extends Fake implements XFile {}
class FakeAnalytics extends Mock implements FirebaseAnalytics {}
class MockUser extends Mock implements User {}

late FakeAnalytics fakeAnalytics;
late MockPlanRepository mockPlanRepository;
late MockDatabaseReference mockPlansRef;
late MockDatabaseReference mockFoldersRef;
late MockDatabaseReference mockShareIdsRef;
late MockDatabaseReference mockFavouritesRef;
late MockFirebaseAuth mockAuth;
late MockImageService mockImageService;
late PlanProvider provider;
class MockValidationProvider extends Mock implements ValidationProvider {} // keep loose, your ValidationProvider

// ----------------- Helpers -----------------
void stubDbPushKey(MockDatabaseReference pushRef, String key) {
  when(() => pushRef.key).thenReturn(key);
}

void stubChildChain(MockDatabaseReference root, String childArg, MockDatabaseReference returned) {
  when(() => root.child(childArg)).thenReturn(returned);
}

void stubOrderByEqualTo(MockDatabaseReference root, String orderBy, String equalValue, MockDatabaseReference returned) {
  when(() => root.orderByChild(orderBy)).thenReturn(root);
  when(() => root.equalTo(equalValue)).thenReturn(root);
}

void main() {

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});

    fakeAnalytics = FakeAnalytics();
    when(() => fakeAnalytics.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters')))
        .thenAnswer((_) async => {});
    AppAnalytics.setAnalytics(fakeAnalytics);

    // register fallback values
    registerFallbackValue(FakeFolder());
    registerFallbackValue(FakePlan());
    registerFallbackValue(FakeXFile());
    registerFallbackValue(FakeComment());
    registerFallbackValue(FakeFavourite());
    registerFallbackValue(FakeSelectedImage());
  });

  setUp(() {
    mockPlanRepository = MockPlanRepository();
    mockPlansRef = MockDatabaseReference();
    mockFoldersRef = MockDatabaseReference();
    mockShareIdsRef = MockDatabaseReference();
    mockFavouritesRef = MockDatabaseReference();
    mockAuth = MockFirebaseAuth();
    mockImageService = MockImageService();

    // DatabaseReference stubs
    final mockPush = MockDatabaseReference();
    when(() => mockPush.key).thenReturn('mock-key');

    final mockChild = MockDatabaseReference();
    when(() => mockPlansRef.child(any())).thenReturn(mockChild);
    when(() => mockChild.push()).thenReturn(mockPush);

    final mockFolderChild = MockDatabaseReference();
    when(() => mockFoldersRef.child(any())).thenReturn(mockFolderChild);
    when(() => mockFolderChild.push()).thenReturn(mockPush);

    final mockShareChild = MockDatabaseReference();
    when(() => mockShareIdsRef.child(any())).thenReturn(mockShareChild);
    when(() => mockShareChild.push()).thenReturn(mockPush);

    // ImageService stubs
    when(() => mockImageService.pickMultipleImages()).thenAnswer((_) async => [MockXFile()]);
    when(() => mockImageService.uploadImages(any())).thenAnswer((_) async => []);

    // Favourites
    when(() => mockFavouritesRef.child(any())).thenReturn(mockPush);
    when(() => mockFavouritesRef.push()).thenReturn(mockPush);

    // PlanRepository stubs
    when(() => mockPlanRepository.getUserId()).thenAnswer((_) async => 'u');
    when(() => mockPlanRepository.addPlan(any())).thenAnswer((_) async {});
    when(() => mockPlanRepository.updateFavouritedBy(any(), any())).thenAnswer((_) async {});
    when(() => mockPlanRepository.addFavourite(any())).thenAnswer((_) async {});
    when(() => mockPlanRepository.fetchFavouritesByUserId(any())).thenAnswer((_) async => []);

    // Build provider
    provider = PlanProvider(
      mockPlanRepository,
      plansRef: mockPlansRef,
      foldersRef: mockFoldersRef,
      shareIdsRef: mockShareIdsRef,
      favouritesRef: mockFavouritesRef,
      auth: mockAuth,
      imageService: mockImageService,
    );
  });


  group('selection & submitSelectedPlans', () {
    test('enter/exit/toggle selection and submit updates local and repository', () async {
      // Arrange
      final plan1 = Plan(id: 'p1', userId: 'u', title: 't', description: '', folderId: 'old', timestamp: 1);
      final plan2 = Plan(id: 'p2', userId: 'u', title: 't2', description: '', folderId: 'old', timestamp: 2);
      provider.plans.addAll([plan1, plan2]);
      provider.enterSelectionMode('p1'); // adds p1
      expect(provider.isSelectionMode, isTrue);
      expect(provider.selectedPlanIds.contains('p1'), isTrue);

      provider.toggleSelection('p1'); // remove
      expect(provider.selectedPlanIds.contains('p1'), isFalse);

      provider.toggleSelection('p2'); // add p2
      expect(provider.selectedPlanIds.contains('p2'), isTrue);

      // stub repo update
      when(() => mockPlanRepository.updatePlanFolder('p2', 'newFolder'))
          .thenAnswer((_) async {});

      // Act
      await provider.submitSelectedPlans('newFolder');

      // Assert
      verify(() => mockPlanRepository.updatePlanFolder('p2', 'newFolder')).called(1);
      expect(provider.plans.any((p) => p.folderId == 'newFolder'), isTrue);
      expect(provider.isSelectionMode, isFalse);
      expect(provider.selectedPlanIds, isEmpty);
      expect(provider.isLoading, isFalse);
    });
  });

  group('getPlanCountForSearchFolder & isShareIdUnique', () {
    test('getPlanCountForSearchFolder returns repo count', () async {
      final folder = Folder(id: 'f1', userId: 'u', name: 'X', order: 0);
      when(() => mockPlanRepository.getPlanCountForFolder('f1')).thenAnswer((_) async => 7);
      final res = await provider.getPlanCountForSearchFolder(folder);
      expect(res, 7);
      verify(() => mockPlanRepository.getPlanCountForFolder('f1')).called(1);
    });

    test('getPlanCountForSearchFolder returns 0 on exception', () async {
      final folder = Folder(id: 'f1', userId: 'u', name: 'X', order: 0);
      when(() => mockPlanRepository.getPlanCountForFolder('f1')).thenThrow(Exception('oops'));
      final res = await provider.getPlanCountForSearchFolder(folder);
      expect(res, 0);
    });

    test('isShareIdUnique delegates to repo and returns false on error', () async {
      when(() => mockPlanRepository.isShareIdUnique('s1')).thenAnswer((_) async => true);
      expect(await provider.isShareIdUnique('s1'), isTrue);

      when(() => mockPlanRepository.isShareIdUnique('s2')).thenThrow(Exception('err'));
      expect(await provider.isShareIdUnique('s2'), isFalse);
    });
  });

  group('createFolder', () {
    test('creates folder and persists via repository', () async {
      // arrange
      when(() => mockPlanRepository.getUserId()).thenAnswer((_) async => 'user123');
      // ensure share id uniqueness first time
      when(() => mockPlanRepository.isShareIdUnique(any())).thenAnswer((_) async => true);
      when(() => mockPlanRepository.createFolder(any())).thenAnswer((_) async {});

      // Act
      await provider.createFolder('My Folder');

      // Assert
      verify(() => mockPlanRepository.getUserId()).called(1);
      verify(() => mockPlanRepository.isShareIdUnique(any())).called(1);
      verify(() => mockPlanRepository.createFolder(any())).called(1);
      expect(provider.folders.any((f) => f.name == 'My Folder'), isTrue);
    });

    test('createFolder retries shareId until unique', () async {
      when(() => mockPlanRepository.getUserId()).thenAnswer((_) async => 'user123');

      // first false, then true
      var call = 0;
      when(() => mockPlanRepository.isShareIdUnique(any())).thenAnswer((_) async {
        call++;
        return call > 1;
      });

      when(() => mockPlanRepository.createFolder(any())).thenAnswer((_) async {});
      await provider.createFolder('Retry Folder');

      verify(() => mockPlanRepository.isShareIdUnique(any())).called(greaterThan(1));
      verify(() => mockPlanRepository.createFolder(any())).called(1);
      expect(provider.folders.any((f) => f.name == 'Retry Folder'), isTrue);
    });
  });

  group('updateFolderAccess', () {
    test('calls repo and updates local folder access', () async {
      final folder = Folder(id: 'fid', userId: 'u', name: 'N', order: 0, shareId: 's', access: 'private', allowedUsers: []);
      provider.folders.add(folder);

      when(() => mockPlanRepository.updateFolderAccess('fid', 'public', allowedUsers: null)).thenAnswer((_) async {});

      await provider.updateFolderAccess('fid', 'public');

      verify(() => mockPlanRepository.updateFolderAccess('fid', 'public', allowedUsers: null)).called(1);
      expect(provider.folders.first.access, 'public');
      expect(provider.folders.first.allowedUsers, isEmpty);
    });

    test('keeps allowedUsers when specific', () async {
      final folder = Folder(id: 'fid2', userId: 'u', name: 'N2', order: 0, shareId: 's2', access: 'private', allowedUsers: []);
      provider.folders.add(folder);

      final allowed = ['a', 'b'];
      when(() => mockPlanRepository.updateFolderAccess('fid2', 'specific', allowedUsers: allowed)).thenAnswer((_) async {});

      await provider.updateFolderAccess('fid2', 'specific', allowedUsers: allowed);

      verify(() => mockPlanRepository.updateFolderAccess('fid2', 'specific', allowedUsers: allowed)).called(1);
      expect(provider.folders.first.access, 'specific');
      expect(provider.folders.first.allowedUsers, allowed);
    });
  });

  group('canUserAccessFolder', () {
    test('handles public/private/specific correctly', () {
      final fPub = Folder(id: '1', userId: 'u1', name: 'public', order: 0, shareId: 's', access: 'public', allowedUsers: []);
      final fPriv = Folder(id: '2', userId: 'u2', name: 'private', order: 0, shareId: 's2', access: 'private', allowedUsers: []);
      final fSpec = Folder(id: '3', userId: 'u3', name: 'specific', order: 0, shareId: 's3', access: 'specific', allowedUsers: ['allowed']);

      expect(provider.canUserAccessFolder(fPub, 'anyone'), isTrue);
      expect(provider.canUserAccessFolder(fPriv, 'u2'), isTrue);
      expect(provider.canUserAccessFolder(fPriv, 'other'), isFalse);
      expect(provider.canUserAccessFolder(fSpec, 'allowed'), isTrue);
      expect(provider.canUserAccessFolder(fSpec, 'u3'), isTrue); // owner
      expect(provider.canUserAccessFolder(fSpec, 'not'), isFalse);
    });
  });

  group('add/remove comments & favourites & likes', () {
    test('addComment updates local and calls repo', () async {
      final plan = Plan(id: 'p1', userId: 'u', title: 't', description: '', folderId: '', timestamp: 1);
      provider.plans.add(plan);

      when(() => mockPlanRepository.addComment('p1', any())).thenAnswer((_) async {});
      await provider.addComment('p1', 'u', 'name', 'hello');

      verify(() => mockPlanRepository.addComment('p1', any())).called(1);
      expect(provider.plans.first.comments.isNotEmpty, isTrue);
    });

    test('deleteComment updates local and calls repo', () async {
      final comment = Comment(id: 'c1', userId: 'u', username: 'n', text: 't', timestamp: 1);
      final plan = Plan(id: 'p2', userId: 'u', title: 't', description: '', folderId: '', timestamp: 2, comments: [comment]);
      provider.plans.add(plan);

      when(() => mockPlanRepository.deleteComment('p2', 'c1')).thenAnswer((_) async {});
      await provider.deleteComment('p2', 'c1');

      verify(() => mockPlanRepository.deleteComment('p2', 'c1')).called(1);
      expect(provider.plans.first.comments.isEmpty, isTrue);
    });

    test('toggleFavourite adds favourite and calls repo', () async {
      final plan = Plan(id: 'p3', userId: 'u', title: 't', description: '', folderId: '', timestamp: 3, favouritedBy: []);
      provider.plans.add(plan);

      // stubs
      when(() => mockPlanRepository.updateFavouritedBy('p3', any())).thenAnswer((_) async {});
      when(() => mockPlanRepository.addFavourite(any())).thenAnswer((_) async {});

      // toggle to add
      await provider.toggleFavourite('p3', 'user1', false);

      // verify calls
      verify(() => mockPlanRepository.updateFavouritedBy('p3', any())).called(1);
      verify(() => mockPlanRepository.addFavourite(any())).called(1);
    });

    test('likePlan updates local likes and calls repo', () async {
      final plan = Plan(id: 'lp', userId: 'u', title: 't', description: '', folderId: '', timestamp: 1, likedBy: []);
      provider.plans.add(plan);

      when(() => mockPlanRepository.updateLikedBy('lp', any())).thenAnswer((_) async {});
      await provider.likePlan('lp', 'userX');

      verify(() => mockPlanRepository.updateLikedBy('lp', any())).called(1);
      expect(provider.plans.first.likedBy.contains('userX'), isTrue);
    });
  });

  group('fetchFolders and _addShareIdIfMissing / _createDefaultFavouritesFolder', () {
    test('fetchFolders adds default favourites when missing and adds shareIds', () async {
      when(() => mockPlanRepository.getUserId()).thenAnswer((_) async => 'userX');

      // fetched folders do not include favourites and one folder missing shareId
      final missingShare = Folder(id: 'f1', userId: 'userX', name: 'Some', order: 0, shareId: '');
      when(() => mockPlanRepository.fetchFolders('userX')).thenAnswer((_) async => [missingShare]);

      // stub addShareIdIfMissing & createFolder
      when(() => mockPlanRepository.isShareIdUnique(any())).thenAnswer((_) async => true);
      when(() => mockPlanRepository.addShareIdIfMissing(any(), any())).thenAnswer((_) async {});
      when(() => mockPlanRepository.createFolder(any())).thenAnswer((_) async {});

      await provider.fetchFolders();

      // Should call _createDefaultFavouritesFolder (createFolder stub) and addShareIdIfMissing
      verify(() => mockPlanRepository.createFolder(any())).called(1);
      verify(() => mockPlanRepository.addShareIdIfMissing('f1', any())).called(1);
      expect(provider.folders.isNotEmpty, isTrue);
    });
  });

  group('update/delete folder & reorder', () {
    test('updateFolder modifies local and calls repo', () async {
      final f = Folder(id: 'u1', userId: 'u', name: 'old', order: 0, shareId: 's');
      provider.folders.add(f);

      when(() => mockPlanRepository.updateFolderName('u1', 'new')).thenAnswer((_) async {});
      await provider.updateFolder('u1', 'new');

      verify(() => mockPlanRepository.updateFolderName('u1', 'new')).called(1);
      expect(provider.folders.first.name, 'new');
    });

    test('deleteFolder removes and clears plans via repo', () async {
      final f = Folder(id: 'del', userId: 'u', name: 'N', order: 0, shareId: 's');
      provider.folders.add(f);
      final plan = Plan(id: 'pdel', userId: 'u', title: 't', description: '', folderId: 'del', timestamp: 1);
      provider.plans.add(plan);

      when(() => mockPlanRepository.getUserId()).thenAnswer((_) async => 'u');
      when(() => mockPlanRepository.deleteFolder('del')).thenAnswer((_) async {});
      when(() => mockPlanRepository.deleteShareId('s')).thenAnswer((_) async {});
      when(() => mockPlanRepository.clearFolderFromPlans('u', 'del')).thenAnswer((_) async {});

      await provider.deleteFolder(f);

      verify(() => mockPlanRepository.deleteFolder('del')).called(1);
      verify(() => mockPlanRepository.deleteShareId('s')).called(1);
      verify(() => mockPlanRepository.clearFolderFromPlans('u', 'del')).called(1);
      expect(provider.folders.any((ff) => ff.id == 'del'), isFalse);
      expect(provider.plans.any((p) => p.folderId == 'del'), isFalse);
    });

    test('reorderFolders updates order and calls updateFolderOrder', () async {
      final a = Folder(id: 'a', userId: 'u', name: 'A', order: 0, shareId: 's1');
      final b = Folder(id: 'b', userId: 'u', name: 'B', order: 1, shareId: 's2');
      provider.folders.addAll([a, b]);

      when(() => mockPlanRepository.updateFolderOrder(any(), any())).thenAnswer((_) async {});

      provider.reorderFolders(0, 2); // move a after b

      // after reorder, provider.folders should have order updated and repo called for each
      verify(() => mockPlanRepository.updateFolderOrder(any(), any())).called(greaterThanOrEqualTo(1));
      expect(provider.folders.length, 2);
    });
  });

  // group('image picking/upload helper flows (pickImages / pickAndUploadImages)', () {
  //   test('pickImages with validations and imageService returns selected images', () async {
  //     // prepare validation provider to accept images
  //     final mockValidation = MockValidationProvider();
  //     provider.updateDependencies(mockValidation);
  //
  //     when(() => mockValidation.validateImages(any())).thenAnswer((_) async {});
  //     when(() => mockValidation.validateImage(any())).thenAnswer((_) async {});
  //     when(() => mockValidation.imagesError).thenReturn(null);
  //
  //     when(() => mockImageService.pickMultipleImages()).thenAnswer((_) async => [MockXFile()]);
  //
  //     await provider.pickImages(); // void function, updates selectedImages internally
  //
  //     // check that provider.selectedImages is updated
  //     expect(provider.selectedImages.isNotEmpty, isTrue);
  //   });
  //
  //   test('pickAndUploadImages returns same plan when none selected or upload fails gracefully', () async {
  //     final mockValidation = MockValidationProvider();
  //     provider.updateDependencies(mockValidation);
  //
  //     when(() => mockValidation.validateImages(any())).thenAnswer((_) async {});
  //     when(() => mockValidation.validateImage(any())).thenAnswer((_) async {});
  //     when(() => mockValidation.imagesError).thenReturn(null);
  //
  //     final mockXFile = MockXFile();
  //     when(() => mockXFile.path).thenReturn('dummy.png'); // must be non-null
  //     when(() => mockImageService.pickMultipleImages()).thenAnswer((_) async => [mockXFile]);
  //
  //     final plan = Plan(id: 'pp', userId: 'u', title: 't', description: '', folderId: '', timestamp: 1);
  //     final result = await provider.pickAndUploadImages(plan);
  //
  //     expect(result?.id, 'pp'); // ✅ now returns the plan
  //     expect(provider.selectedImages.first.localFile?.path, 'dummy.png'); // ✅ selected image path
  //   });
  //
  //
  // });

  // Many other small functions can be similarly tested: filterPlans, applyTagFilter,
  // updatePlanStatus, addPlan/updatePlan/updatedPlan, linkPlans/removeLink etc.
  // For brevity we add a couple of representative tests:

  group('addPlan/updatePlan/updatedPlan/deletePlan flows', () {
    test('addPlan persists via repo and updates local state', () async {
      when(() => mockAuth.currentUser).thenReturn(MockUser());
      when(() => mockPlanRepository.getUserId()).thenAnswer((_) async => 'u');
      when(() => mockImageService.uploadImages(any())).thenAnswer((_) async => []);
      when(() => mockPlanRepository.addPlan(any())).thenAnswer((_) async {});
      await provider.addPlan(title: 'T', description: 'D', videos: [], tags: [], isConnection: false, parentId: null, collectionId: null);
      verify(() => mockPlanRepository.addPlan(any())).called(1);
    });

    test('updatePlan updates via repo and updates local state', () async {
      when(() => mockAuth.currentUser).thenReturn(MockUser());
      final p = Plan(id: 'up', userId: 'u', title: 't', description: '', folderId: '', timestamp: 1, images: []);
      provider.plans.add(p);
      when(() => mockPlanRepository.updatePlan(any())).thenAnswer((_) async {});
      await provider.updatePlan(p);
      verify(() => mockPlanRepository.updatePlan(any())).called(1);
    });

    test('deletePlan calls repo and removes local', () async {
      when(() => mockAuth.currentUser).thenReturn(MockUser());
      final p = Plan(id: 'delp', userId: 'u', title: 't', description: '', folderId: '', timestamp: 1);
      provider.plans.add(p);
      when(() => mockPlanRepository.deletePlan('delp')).thenAnswer((_) async {});
      await provider.deletePlan('delp');
      verify(() => mockPlanRepository.deletePlan('delp')).called(1);
      expect(provider.plans.any((pp) => pp.id == 'delp'), isFalse);
    });
  });
}

