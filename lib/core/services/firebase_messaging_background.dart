import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:language_learning_app/firebase_options.dart';

/// Must be a top-level function. Runs in a background isolate when the app
/// is terminated or in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    debugPrint(
      'FCM background: id=${message.messageId} title=${message.notification?.title}',
    );
  }
}
