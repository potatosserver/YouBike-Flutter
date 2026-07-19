import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for $defaultTargetPlatform. '
          'Firebase is only available on Android and iOS in this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDdN8jhIDBekL5Xc05ohlLXdGnnzIwc_ZE',
    appId: '1:1035318135469:android:1a9c661b28d1a7570e5424',
    messagingSenderId: '1035318135469',
    projectId: 'youbike-52680',
    storageBucket: 'youbike-52680.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDdN8KjhIDBekL5Xc05ohlLXdGnnzIwc_ZE',
    appId: '1:1035318135469:ios:placeholder',
    messagingSenderId: '1035318135469',
    projectId: 'youbike-52680',
    storageBucket: 'youbike-52680.firebasestorage.app',
  );
}