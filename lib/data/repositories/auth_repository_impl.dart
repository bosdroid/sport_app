import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/utils.dart';
import '../../domain/entities/user.dart' as localUser;
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final DatabaseReference _usernamesRef;
  final DatabaseReference _usersDetailsRef;

  AuthRepositoryImpl(this._firebaseAuth, FirebaseDatabase database)
      : _usernamesRef = database.ref().child('USERNAMES/'),
        _usersDetailsRef = database.ref().child('USERS_DETAILS/');

  @override
  Future<User?> loadUserFromSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final username = prefs.getString('user_name');
    final loginType = prefs.getString('login_type');
    if (email != null && loginType != 'guest') {
      Util.isUserLogged = true;
      return _firebaseAuth.currentUser;
    }
    Util.isUserLogged = false;
    await loginAsGuest();
    await prefs.setString('is_registered', 'false');
    return null;
  }

  @override
  Future<User?> loginWithEmail(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = credential.user;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final userSnapshot = await _usernamesRef.child(user.uid).get();

      if (userSnapshot.exists) {
        final value = userSnapshot.value as Map?;
        prefs.setString('user_name', value?['username']);
        // Perform guest data migration safely
        await _migrateGuestData(value?['username']);
      }
      prefs.setString('user_email', user.email!);
    }

    return user;
  }

  @override
  Future<User?> signUpWithEmail(String username, String email, String password) async {
    // ✅ 1️⃣ Check if the username already exists
    final snapshot = await _usernamesRef.orderByChild('username').equalTo(username).get();
    if (snapshot.exists) {
      throw FirebaseAuthException(
        code: 'username-taken',
        message: 'Username already exists.',
      );
    }

    // ✅ 2️⃣ Create a new Firebase Auth user
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    // ✅ 3️⃣ Save username to Firebase Realtime Database (usernames node)
    await _usernamesRef.child(user.uid).set({'username': username});

    // ✅ 4️⃣ Save user details
    await _usersDetailsRef.child(username).set({
      'id': user.uid,
      'username': username,
      'email': user.email,
      'type': 'email',
    });

    // ✅ 5️⃣ Update local session data
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', user.email!);
    await prefs.setString('user_name', username);
    await prefs.setString('login_type', 'email');

    // ✅ 6️⃣ Migrate guest data (if exists)
    // Store the old guest ID (if not already stored) before migration
    final guestId = prefs.getString('guest_id');
    if (guestId == null || guestId.isEmpty) {
      final oldGuestId = prefs.getString('user_name') ?? '';
      if (oldGuestId.isNotEmpty) {
        await prefs.setString('guest_id', oldGuestId);
      }
    }

    // Perform guest data migration safely
    await _migrateGuestData(username);

    return user;
  }

  @override
  Future<User?> loginWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final authResult = await _firebaseAuth.signInWithCredential(credential);
    final user = authResult.user;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final userSnapshot = await _usernamesRef.child(user.uid).get();

      if (!userSnapshot.exists) {
        final defaultUsername = await _generateDefaultUsername();
        await _usernamesRef.child(user.uid).set({'username': defaultUsername});
        await _usersDetailsRef.child(defaultUsername).update({
          'id': user.uid,
          'username': defaultUsername,
          'email': user.email,
          'type': 'google',
        });
        prefs.setString('user_name', defaultUsername);
        // Perform guest data migration safely
        await _migrateGuestData(defaultUsername);
      } else {
        final value = userSnapshot.value as Map?;
        final username = value?['username'];
        prefs.setString('user_name', username);
        await _migrateGuestData(username);
      }

      prefs.setString('user_email', user.email!);
    }
    return user;
  }

  @override
  Future<User?> loginWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final authResult = await _firebaseAuth.signInWithCredential(oauthCredential);
    final user = authResult.user;

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      final userSnapshot = await _usernamesRef.child(user.uid).get();

      if (!userSnapshot.exists) {
        final defaultUsername = await _generateDefaultUsername();
        await _usernamesRef.child(user.uid).set({'username': defaultUsername});
        await _usersDetailsRef.child(defaultUsername).update({
          'id': user.uid,
          'username': defaultUsername,
          'email': user.email,
          'type': 'apple',
        });
        prefs.setString('user_name', defaultUsername);
        await _migrateGuestData(defaultUsername);
      }
      else{
        final value = userSnapshot.value as Map?;
        final username = value?['username'];
        prefs.setString('user_name', username);
        await _migrateGuestData(username);
      }
      prefs.setString('user_email', user.email ?? "");
    }
    return user;
  }

  // Future<void> loginAsGuest() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //
  //     // 1️⃣ Get device ID
  //     final deviceId = await _getHashedDeviceId();
  //     if (deviceId == null) {
  //       throw Exception("Unable to get device ID");
  //     }
  //
  //     // 2️⃣ Check Firebase for existing guest record
  //     final snapshot = await _usernamesRef
  //         .orderByChild("deviceId")
  //         .equalTo(deviceId)
  //         .get();
  //
  //     String username;
  //
  //     if (snapshot.exists) {
  //       // Existing guest found → reuse username
  //       final Map data = snapshot.value as Map;
  //       final firstEntry = data.entries.first;
  //       username = firstEntry.value['username'];
  //     } else {
  //       // New guest → generate username
  //       final defaultUsername = await _generateDefaultUsername(prefix: 'guest');
  //       username = defaultUsername;
  //
  //       await _usernamesRef.child(_usernamesRef.push().key.toString()).set({
  //         'username': defaultUsername,
  //         'deviceId': deviceId,
  //       });
  //     }
  //
  //     // 3️⃣ Save locally to maintain session
  //     prefs.setString('user_name', username);
  //     prefs.setString('user_email', 'guest@local');
  //     prefs.setString('device_id', deviceId);
  //     prefs.setString('login_type', 'guest');
  //
  //     // 4️⃣ Return a simple user model (like your normal login)
  //     // localUser.User guestUser = localUser.User(
  //     //   id: deviceId,
  //     //   username: username,
  //     //   email: 'guest@local',
  //     //   type: 'guest',
  //     // );
  //
  //   } catch (e) {
  //     throw Exception('Failed to sign in as guest: $e');
  //   }
  // }

  Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();

    // 👇 Check if we already have a guest_id
    String? guestId = prefs.getString('guest_id');
    if (guestId != null) {
      // Already a guest user → restore session
      prefs.setString('login_type', 'guest');
      return;
    }

    final deviceId = await _getHashedDeviceId();
    if (deviceId == null) throw Exception("Unable to get device ID");

    final guestUsername = "guest_${deviceId.substring(0, 10)}"; // unique pattern
    await _usernamesRef.push().set({
      'username': guestUsername,
      'deviceId': deviceId,
    });

    prefs.setString('user_name', guestUsername);
    prefs.setString('user_email', 'guest@local');
    prefs.setString('device_id', deviceId);
    prefs.setString('guest_id', guestUsername); // save for reuse
    prefs.setString('login_type', 'guest');
  }


  Future<String?> _getHashedDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String? id;

    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      id = info.id;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      id = info.identifierForVendor;
    }

    if (id == null) return null;

    // Hash it for privacy & uniform length
    return crypto.sha256.convert(utf8.encode(id)).toString();
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await GoogleSignIn().signOut();
    final prefs = await SharedPreferences.getInstance();
    final guestId = prefs.getString('guest_id');

    // ✅ Clear email login info but restore guest session
    prefs.remove('user_email');
    prefs.setString('login_type', 'guest');
    prefs.setString('user_name', guestId ?? 'guest_demo');
  }

  @override
  String? validateUsernameInput(String username) {
    if (username.isEmpty) {
      return 'Username cannot be empty';
    }
    if (username.length < 6) {
      return 'Username must be at least 6 characters long';
    }
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegExp.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null; // ✅ valid
  }

  // Helpers
  // Future<String> _generateDefaultUsername() async {
  //   final snapshot = await _usernamesRef.orderByChild('username').limitToLast(1).get();
  //   if (!snapshot.exists) return 'user001';
  //
  //   final value = snapshot.children.last.value as Map?;
  //   final lastUsername = value?['username'] as String? ?? '';
  //   final lastNumber = int.tryParse(lastUsername.replaceFirst(RegExp(r'user'), '')) ?? 0;
  //   return 'user${(lastNumber + 1).toString().padLeft(3, '0')}';
  // }
  Future<String> _generateDefaultUsername({String prefix = 'user'}) async {
    final snapshot = await _usernamesRef.get();
    if (!snapshot.exists) return '${prefix}001';

    int maxNum = 0;
    for (final child in snapshot.children) {
      final value = child.value as Map?;
      final username = value?['username'] as String?;
      if (username != null && username.startsWith(prefix)) {
        final numPart = int.tryParse(username.replaceAll(RegExp(r'[^0-9]'), ''));
        if (numPart != null && numPart > maxNum) maxNum = numPart;
      }
    }
    return '${prefix}${(maxNum + 1).toString().padLeft(3, '0')}';
  }


  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    final charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }

  @override
  String getErrorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for that email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Try again later.';
        case 'username-taken':
          return 'This username is already taken. Please choose another.';
        default:
          return 'Unexpected error during login: ${e.message}';
      }
    }
    return 'Unexpected error: ${e.toString()}';
  }

  @override
  String getAppleLoginErrorMessage(Object e) {
    if (e is SignInWithAppleAuthorizationException) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          return "Apple login was cancelled by the user.";
        case AuthorizationErrorCode.failed:
          return "Apple login failed. Please try again.";
        case AuthorizationErrorCode.invalidResponse:
          return "Invalid response from Apple login.";
        case AuthorizationErrorCode.notHandled:
          return "Apple login was not handled.";
        case AuthorizationErrorCode.unknown:
          return "An unknown error occurred during Apple login.";
        default:
          return 'Unexpected error during login: ${e.message}';
      }
    }
    return "Unexpected error during Apple login: ${e.toString()}";
  }

  Future<void> _migrateGuestData(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();

    // ✅ Use the saved guest_id instead of user_name to identify guest data
    final guestUserId = prefs.getString('guest_id');
    if (guestUserId == null || guestUserId.isEmpty) return;

    // ✅ Reference to all necessary database nodes
    final db = FirebaseDatabase.instance;
    final foldersRef = db.ref('FOLDERS/');
    final plansRef = db.ref('PLANS/');
    final shareIdsRef = db.ref('SHARE_IDS/');
    final favouritesRef = db.ref('FAVOURITES/');

    // 🗂 1️⃣ Move guest folders to new account
    final guestFoldersSnap =
    await foldersRef.orderByChild('userId').equalTo(guestUserId).get();

    if (guestFoldersSnap.exists) {
      for (final folderSnap in guestFoldersSnap.children) {
        final data = Map<String, dynamic>.from(folderSnap.value as Map);
        data['userId'] = newUsername;

        await foldersRef.child(folderSnap.key!).set(data);
        // Optional: remove guest version after migration
        // await foldersRef.child(folderSnap.key!).remove();
      }
    }

    // 🧩 2️⃣ Move guest plans to new account
    final guestPlansSnap =
    await plansRef.orderByChild('userId').equalTo(guestUserId).get();

    if (guestPlansSnap.exists) {
      for (final planSnap in guestPlansSnap.children) {
        final data = Map<String, dynamic>.from(planSnap.value as Map);
        data['userId'] = newUsername;

        await plansRef.child(planSnap.key!).set(data);
        // Optional: remove guest version after migration
        // await plansRef.child(planSnap.key!).remove();
      }
    }

    // ❤️ 3️⃣ Move favourites (if any)
    final favSnap =
    await favouritesRef.orderByChild('userId').equalTo(guestUserId).get();

    if (favSnap.exists) {
      for (final fav in favSnap.children) {
        final data = Map<String, dynamic>.from(fav.value as Map);
        data['userId'] = newUsername;

        await favouritesRef.child(fav.key!).set(data);
        // Optional: remove guest version
        // await favouritesRef.child(fav.key!).remove();
      }
    }

    // 🔗 4️⃣ Move shared IDs (optional if used)
    final shareSnap =
    await shareIdsRef.orderByChild('userId').equalTo(guestUserId).get();

    if (shareSnap.exists) {
      for (final share in shareSnap.children) {
        final data = Map<String, dynamic>.from(share.value as Map);
        data['userId'] = newUsername;

        await shareIdsRef.child(share.key!).set(data);
        // Optional: remove guest version
        // await shareIdsRef.child(share.key!).remove();
      }
    }

    // 🧽 5️⃣ Update local session and preserve guest_id for fallback guest mode
    prefs.setString('user_name', newUsername);
    prefs.setString('login_type', 'email');
    prefs.setString('is_registered', 'true');

    // ✅ Do NOT remove guest_id — needed if user logs out to guest mode again
    // prefs.remove('guest_id'); ❌
  }

}
