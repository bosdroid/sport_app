// DO NOT EDIT — generated automatically by FlutterFire CLI
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDgIR4g0A01rGdZthkGGWNRkcHDtfoWRpY",
    authDomain: "astrowayusers.firebaseapp.com",
    projectId: "bjj-diary-ba601",
    storageBucket: "bjj-diary-ba601.firebasestorage.app",
    messagingSenderId: "1037131909342", //381086206621
    appId: "1:1037131909342:android:0b8310e84656a9f1701a4f",
    measurementId: "G-MVCSV4DDZH",
  );

  // Add your own values copied from the Firebase console ↓
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDgIR4g0A01rGdZthkGGWNRkcHDtfoWRpY',
    appId: '1:1037131909342:ios:1c511f664d10be98701a4f',
    messagingSenderId: '1037131909342',
    projectId: 'bjj-diary-ba601',
    iosBundleId: 'com.bjjdairy.app',
    iosClientId: '...',
    databaseURL: 'https://bjj-diary-ba601-default-rtdb.firebaseio.com',
    storageBucket: 'bjj-diary-ba601.firebasestorage.app',
  );


  // const firebaseConfig = {
  //   apiKey: "AIzaSyA9sVtKvBCj-_48RHvYvoerUnTUjv8Uy0o",
  //   authDomain: "bjj-diary-ba601.firebaseapp.com",
  //   databaseURL: "https://bjj-diary-ba601-default-rtdb.firebaseio.com",
  //   projectId: "bjj-diary-ba601",
  //   storageBucket: "bjj-diary-ba601.firebasestorage.app",
  //   messagingSenderId: "1037131909342",
  //   appId: "1:1037131909342:web:b8fdd81c3f767263701a4f",
  //   measurementId: "G-MVCSV4DDZH"
  // };

}
