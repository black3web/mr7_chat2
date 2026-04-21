// Firebase options for mr7-chat project
// Generated for Flutter Firebase v3.x

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAYpjkEuRitIqSvNloUUtrHsEWUohJR3lY',
    authDomain: 'mr7-chat.firebaseapp.com',
    projectId: 'mr7-chat',
    storageBucket: 'mr7-chat.firebasestorage.app',
    messagingSenderId: '231946174968',
    appId: '1:231946174968:web:c1d829d43e1857402b960d',
    measurementId: 'G-MKV2ZB46WB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbPrTj2kZjkw5vwNZNHoL4bcu1MbiE5J4',
    appId: '1:231946174968:android:46d734ccc11935bd2b960d',
    messagingSenderId: '231946174968',
    projectId: 'mr7-chat',
    storageBucket: 'mr7-chat.firebasestorage.app',
  );
}