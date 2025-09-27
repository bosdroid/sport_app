import 'dart:async';

import 'package:bjj_dairy/core/app_analytics.dart';
import 'package:bjj_dairy/data/repositories/plan_repository_impl.dart';
import 'package:bjj_dairy/data/services/image_service.dart';
import 'package:bjj_dairy/domain/entities/comment.dart';
import 'package:bjj_dairy/domain/entities/favourite.dart';
import 'package:bjj_dairy/domain/entities/folder.dart';
import 'package:bjj_dairy/domain/entities/plan.dart';
import 'package:bjj_dairy/domain/entities/selected_image.dart';
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
late PlanRepositoryImpl repo;
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

class MockDataSnapshot extends Mock implements DataSnapshot {}
late MockDataSnapshot mockSnapshot;
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
    mockSnapshot = MockDataSnapshot();
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

    repo = PlanRepositoryImpl(
      plansRef: mockPlansRef,
      foldersRef: mockFoldersRef,
      shareIdsRef: mockShareIdsRef,
      favouritesRef: mockFavouritesRef,
      auth: mockAuth,
      imageService: mockImageService,
    );

    SharedPreferences.setMockInitialValues({'user_name': 'user123'});
  });

  group('getUserId', () {
    test('returns stored user_name when auth.currentUser present', () async {
      when(() => mockAuth.currentUser).thenReturn(MockUser());
      final res = await repo.getUserId();
      expect(res, 'user123');
    });

    test('returns null when no currentUser', () async {
      when(() => mockAuth.currentUser).thenReturn(null);
      final res = await repo.getUserId();
      expect(res, null);
    });
  });

  group('updatePlanFolder', () {
    test('calls update on plan node', () async {
      final childRef = MockDatabaseReference();

      // Stub child call
      when(() => mockPlansRef.child('p1')).thenReturn(childRef);

      // Stub update
      when(() => childRef.update({'folderId': 'f1'})).thenAnswer((_) async {});

      // Call the method
      await repo.updatePlanFolder('p1', 'f1');

      // Verify update was called
      verify(() => childRef.update({'folderId': 'f1'})).called(1);
    });
  });

  group('getPlanCountForFolder', () {

    test('returns length when snapshot is map', () async {
      when(() => mockPlansRef.orderByChild('folderId')).thenReturn(mockPlansRef);
      when(() => mockPlansRef.equalTo('f1')).thenReturn(mockPlansRef);
      when(() => mockPlansRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn({'a': 1, 'b': 2});

      final count = await repo.getPlanCountForFolder('f1');
      expect(count, 2);
    });

    test('returns 0 on exception', () async {
      when(() => mockPlansRef.orderByChild('folderId')).thenReturn(mockPlansRef);
      when(() => mockPlansRef.equalTo('f1')).thenReturn(mockPlansRef);
      when(() => mockPlansRef.get()).thenThrow(Exception('err'));

      final count = await repo.getPlanCountForFolder('f1');
      expect(count, 0);
    });
  });


  group('isShareIdUnique / isUnique / saveShareId', () {
    late MockDatabaseReference childRef;
    late MockDataSnapshot mockSnapshot;

    setUp(() {
      childRef = MockDatabaseReference();
      mockSnapshot = MockDataSnapshot();
    });

    test('isShareIdUnique returns true when snapshot value null', () async {
      when(() => mockShareIdsRef.child('s1')).thenReturn(childRef);
      when(() => childRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.value).thenReturn(null);

      final r = await repo.isShareIdUnique('s1');
      expect(r, isTrue);
    });

    test('isUnique uses same logic', () async {
      when(() => mockShareIdsRef.child('s2')).thenReturn(childRef);
      when(() => childRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.value).thenReturn(null);

      final r = await repo.isUnique('s2');
      expect(r, isTrue);
    });

    test('saveShareId writes to shareIdsRef', () async {
      when(() => mockShareIdsRef.child('s3')).thenReturn(childRef);
      when(() => childRef.set('folderX')).thenAnswer((_) async {});

      await repo.saveShareId('s3', 'folderX');

      verify(() => childRef.set('folderX')).called(1);
    });
  });


  group('createFolder / addShareIdIfMissing / deleteFolder', () {
    late MockDatabaseReference folderChildRef;
    late MockDatabaseReference shareChildRef;
    late MockDataSnapshot mockSnapshot;

    setUp(() {
      folderChildRef = MockDatabaseReference();
      shareChildRef = MockDatabaseReference();
      mockSnapshot = MockDataSnapshot();
    });

    test('createFolder writes folder and shareId', () async {
      final folder = Folder(
        id: 'fid',
        userId: 'u',
        name: 'N',
        order: 0,
        shareId: 'sid',
        access: 'private',
        allowedUsers: [],
      );

      when(() => mockFoldersRef.child('fid')).thenReturn(folderChildRef);
      when(() => folderChildRef.set(folder.toMap())).thenAnswer((_) async {});

      when(() => mockShareIdsRef.child('sid')).thenReturn(shareChildRef);
      when(() => shareChildRef.set('fid')).thenAnswer((_) async {});

      await repo.createFolder(folder);

      verify(() => folderChildRef.set(folder.toMap())).called(1);
      verify(() => shareChildRef.set('fid')).called(1);
    });

    test('addShareIdIfMissing checks snapshot and updates', () async {
      when(() => mockFoldersRef.child('fid')).thenReturn(folderChildRef);
      when(() => folderChildRef.child('shareId')).thenReturn(folderChildRef);

      // snapshot does not exist -> update
      when(() => folderChildRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(false);
      when(() => folderChildRef.update({'shareId': 'sid'})).thenAnswer((_) async {});

      when(() => mockShareIdsRef.child('sid')).thenReturn(shareChildRef);
      when(() => shareChildRef.set('fid')).thenAnswer((_) async {});

      await repo.addShareIdIfMissing('fid', 'sid');

      verify(() => folderChildRef.update({'shareId': 'sid'})).called(1);
      verify(() => mockShareIdsRef.child('sid')).called(1);
    });

    test('deleteFolder and deleteShareId call remove', () async {
      when(() => mockFoldersRef.child('fid')).thenReturn(folderChildRef);
      when(() => folderChildRef.remove()).thenAnswer((_) async {});

      await repo.deleteFolder('fid');
      verify(() => folderChildRef.remove()).called(1);

      when(() => mockShareIdsRef.child('sid')).thenReturn(shareChildRef);
      when(() => shareChildRef.remove()).thenAnswer((_) async {});

      await repo.deleteShareId('sid');
      verify(() => shareChildRef.remove()).called(1);
    });
  });


  group('fetchFolders / fetchFoldersByShareId / findByName', () {
    late MockDataSnapshot mockSnapshot;

    setUp(() {
      mockSnapshot = MockDataSnapshot();
    });

    test('fetchFolders returns parsed folders', () async {
      final map = {
        'k1': {
          'id': 'f1',
          'userId': 'user123',
          'name': 'A',
          'order': 0,
          'shareId': 's1',
          'access': 'private',
          'allowedUsers': []
        }
      };

      when(() => mockFoldersRef.orderByChild('userId')).thenReturn(mockFoldersRef);
      when(() => mockFoldersRef.equalTo('user123')).thenReturn(mockFoldersRef);
      when(() => mockFoldersRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(map);

      final res = await repo.fetchFolders('user123');

      expect(res.length, 1);
      expect(res.first.userId, 'user123');
    });

    test('fetchFoldersByShareId filters by shareId', () async {
      final map = {
        'k1': {
          'id': 'f1',
          'userId': 'other',
          'name': 'A',
          'order': 0,
          'shareId': 'mys',
          'access': 'public',
          'allowedUsers': []
        }
      };

      when(() => mockFoldersRef.orderByChild('shareId')).thenReturn(mockFoldersRef);
      when(() => mockFoldersRef.equalTo('mys')).thenReturn(mockFoldersRef);
      when(() => mockFoldersRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(map);

      final res = await repo.fetchFoldersByShareId('mys');

      expect(res.length, 1);
      expect(res.first.shareId, 'mys');
    });

    test('findByName returns folder if exists', () async {
      final map = {
        'k1': {
          'id': 'f1',
          'userId': 'user123',
          'name': 'Target',
          'order': 0,
          'shareId': 's',
          'access': 'private',
          'allowedUsers': []
        }
      };

      when(() => mockFoldersRef.orderByChild('userId')).thenReturn(mockFoldersRef);
      when(() => mockFoldersRef.equalTo('user123')).thenReturn(mockFoldersRef);
      when(() => mockFoldersRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(map);

      final res = await repo.findByName('user123', 'Target');

      expect(res, isNotNull);
      expect(res!.name!.toLowerCase(), 'target');
    });
  });


  group('plan CRUD & queries', () {
    late MockDataSnapshot mockSnapshot;
    late MockDatabaseReference childRef;

    setUp(() {
      mockSnapshot = MockDataSnapshot();
      childRef = MockDatabaseReference();
    });

    test('fetchPlansByUserId returns plans list parsed', () async {
      final map = {
        'p1': {
          'id': 'p1',
          'userId': 'user123',
          'title': 'T',
          'description': '',
          'timestamp': 1,
          'videos': [],
          'tags': [],
          'from': [],
          'to': [],
          'images': [],
          'status': '',
          'note': '',
          'folderId': ''
        }
      };

      when(() => mockPlansRef.orderByChild('userId')).thenReturn(mockPlansRef);
      when(() => mockPlansRef.equalTo('user123')).thenReturn(mockPlansRef);
      when(() => mockPlansRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(map);

      final res = await repo.fetchPlansByUserId('user123');

      expect(res.length, 1);
      expect(res.first.userId, 'user123');
    });

    test('fetchFavouritesByUserId reads favourites and plans', () async {
      final favMap = {
        'k1': {'id': 'fav1', 'userId': 'user123', 'planId': 'plan1'}
      };

      // Stub favourites
      when(() => mockFavouritesRef.orderByChild('userId')).thenReturn(mockFavouritesRef);
      when(() => mockFavouritesRef.equalTo('user123')).thenReturn(mockFavouritesRef);
      when(() => mockFavouritesRef.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.value).thenReturn(favMap);

      // Stub individual plan
      final planMap = {
        'id': 'plan1',
        'userId': 'user123',
        'title': 'T',
        'description': '',
        'timestamp': 1,
        'videos': [],
        'tags': [],
        'from': [],
        'to': [],
        'images': [],
        'status': '',
        'note': '',
        'folderId': ''
      };
      final planSnapshot = MockDataSnapshot();
      when(() => mockPlansRef.child('plan1')).thenReturn(childRef);
      when(() => childRef.get()).thenAnswer((_) async => planSnapshot);
      when(() => planSnapshot.exists).thenReturn(true);
      when(() => planSnapshot.value).thenReturn(planMap);

      final res = await repo.fetchFavouritesByUserId('user123');

      expect(res.length, 1);
      expect(res.first.id, 'plan1');
    });

    test('add/update/delete Plan call underlying set/update/remove', () async {
      final plan = Plan(
        id: 'pid',
        userId: 'user123',
        title: 'T',
        description: '',
        folderId: '',
        timestamp: 1,
        images: [],
        videos: []
      );

      final planRef = MockDatabaseReference();

      // Make sure all calls to child('pid') return the same mock
      when(() => mockPlansRef.child('pid')).thenReturn(planRef);

      // Stub methods with any() matcher (not exact map)
      when(() => planRef.set(any())).thenAnswer((_) async {});
      when(() => planRef.update(any())).thenAnswer((_) async {});
      when(() => planRef.remove()).thenAnswer((_) async {});

      // addPlan
      await repo.addPlan(plan);
      verify(() => planRef.set(any())).called(1);

      // updatePlan
      await repo.updatePlan(plan);
      verify(() => planRef.update(any())).called(1);

      // deletePlan
      await repo.deletePlan('pid');
      verify(() => planRef.remove()).called(1);
    });

  });



  group('misc updates (links / connections)', () {

    test('updateConnections performs update calls', () async {
      final toRef = MockDatabaseReference();
      final fromRef = MockDatabaseReference();

      when(() => mockPlansRef.child('parent/to')).thenReturn(toRef);
      when(() => mockPlansRef.child('child/from')).thenReturn(fromRef);

      // Use any() matcher so argument values don’t have to match exactly
      when(() => toRef.update(any())).thenAnswer((_) async {});
      when(() => fromRef.update(any())).thenAnswer((_) async {});

      await repo.updateConnections('parent', 'child');

      verify(() => toRef.update(any())).called(1);
      verify(() => fromRef.update(any())).called(1);
    });

    test('linkPlans pushes child and from', () async {
      final parentRef = MockDatabaseReference();
      final childRef = MockDatabaseReference();
      final parentPush = MockDatabaseReference();
      final childPush = MockDatabaseReference();

      when(() => mockPlansRef.child('parent')).thenReturn(parentRef);
      when(() => mockPlansRef.child('child')).thenReturn(childRef);

      when(() => parentRef.child('to')).thenReturn(parentRef);
      when(() => childRef.child('from')).thenReturn(childRef);

      when(() => parentRef.push()).thenReturn(parentPush);
      when(() => childRef.push()).thenReturn(childPush);

      when(() => parentPush.set('child')).thenAnswer((_) async {});
      when(() => childPush.set('parent')).thenAnswer((_) async {});

      await repo.linkPlans(parentId: 'parent', childId: 'child', userId: 'user123');

      verify(() => parentRef.push()).called(1);
      verify(() => childRef.push()).called(1);
      verify(() => parentPush.set('child')).called(1);
      verify(() => childPush.set('parent')).called(1);
    });

    test('removeLink uses remove on expected path', () async {
      final parentToChild = MockDatabaseReference();
      final childFromParent = MockDatabaseReference();

      when(() => mockPlansRef.child('parent/to/child')).thenReturn(parentToChild);
      when(() => mockPlansRef.child('child/from/parent')).thenReturn(childFromParent);

      when(() => parentToChild.remove()).thenAnswer((_) async {});
      when(() => childFromParent.remove()).thenAnswer((_) async {});

      await repo.removeLink(parentId: 'parent', childId: 'child', userId: 'user123');

      verify(() => parentToChild.remove()).called(1);
      verify(() => childFromParent.remove()).called(1);
    });
  });

}
