import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bjj_dairy/domain/entities/user.dart';
import 'package:bjj_dairy/domain/repositories/profile_repository.dart';
import 'package:bjj_dairy/presentation/providers/profile_provider.dart';

// ----- Mocks -----
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository mockRepository;
  late ProfileProvider provider;
  final testUser = User(
    id: '1',
    username: 'john',
    email: 'john@example.com',
    type: 'email',
  );

  setUpAll(() {
    registerFallbackValue(testUser);
  });

  setUp(() {
    mockRepository = MockProfileRepository();
    provider = ProfileProvider(mockRepository);
  });

  test('getUserDetails sets loggedUser and notifies listeners', () async {
    when(() => mockRepository.getUserDetails())
        .thenAnswer((_) async => testUser);

    var notified = false;
    provider.addListener(() => notified = true);

    await provider.getUserDetails();

    expect(provider.loggedUser, equals(testUser));
    expect(notified, isTrue);
    verify(() => mockRepository.getUserDetails()).called(1);
  });

  test('updateUserProfile updates loggedUser and notifies listeners', () async {
    when(() => mockRepository.updateUserProfile(any()))
        .thenAnswer((_) async => {});

    var notified = false;
    provider.addListener(() => notified = true);

    await provider.updateUserProfile(testUser);

    expect(provider.loggedUser, equals(testUser));
    expect(notified, isTrue);
    verify(() => mockRepository.updateUserProfile(testUser)).called(1);
  });
}
