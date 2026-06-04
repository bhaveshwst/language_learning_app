import 'dart:convert';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:language_learning_app/core/services/firebase_messaging_background.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/theme/app_theme.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/remote_config/app_remote_config.dart';

import 'package:language_learning_app/view/home_page.dart';
import 'package:language_learning_app/view/student/student_dashboard_shell.dart';
import 'package:language_learning_app/view/tutor/tutor_dashboard_shell.dart';
import 'package:language_learning_app/view/force_update_screen.dart';
import 'package:language_learning_app/core/widgets/connectivity_overlay.dart';
import 'package:language_learning_app/core/navigation/app_navigator.dart';

import 'package:language_learning_app/core/device/app_device_info.dart';

import 'firebase_options.dart';

export 'package:language_learning_app/core/device/app_device_info.dart'
    show deviceInfo, loadAppDeviceInfo;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const _AppBootstrap());
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  Object? _error;
  bool _ready = false;
  bool _forceUpdateRequired = false;
  String? _lastForegroundMessageId;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Crashlytics setup
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Shared Preferences init
      await PrefUtils.init();

      await loadAppDeviceInfo();

      _initializeNotifications();

      // Remote Config
      await AppRemoteConfig.initialize();
      final forceUpdate = await AppRemoteConfig.evaluateForceUpdate();

      if (!mounted) return;

      setState(() {
        _forceUpdateRequired = forceUpdate.mustUpdate;
        _ready = true;
      });
    } catch (e, st) {
      debugPrint('Startup init failed: $e\n$st');

      if (!mounted) return;

      setState(() {
        _error = e;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await AwesomeNotifications()
          .initialize('resource://drawable/notification', [
            NotificationChannel(
              channelKey: 'silent_channel',
              channelName: 'General Notifications',
              channelDescription: 'App push notifications',
              importance: NotificationImportance.High,
              playSound: true,
            ),
          ]);

      final fcmSettings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final isAwesomeAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAwesomeAllowed) {
        await AwesomeNotifications().requestPermissionToSendNotifications();
      }

      if (kDebugMode) {
        debugPrint(
          'FCM notification permission: ${fcmSettings.authorizationStatus.name}',
        );
      }

      final startupToken = await _fetchFcmTokenWithRetry();
      if (startupToken != null) {
        await PrefUtils.setFCMToken(startupToken);
        if (kDebugMode) {
          debugPrint('FCM Token saved at startup: $startupToken');
        }
      } else if (kDebugMode) {
        debugPrint('FCM Token was null after startup init');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        await PrefUtils.setFCMToken(token);
        if (kDebugMode) {
          debugPrint('FCM Token refreshed: $token');
        }
      });

      FirebaseMessaging.onMessage.listen((message) async {
        final messageId = message.messageId;
        if (messageId != null && messageId == _lastForegroundMessageId) return;
        _lastForegroundMessageId = messageId;

        final notification = message.notification;
        if (notification == null) return;

       if (defaultTargetPlatform == TargetPlatform.android) {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'silent_channel',
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        icon: 'resource://drawable/notification',
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
      ),
    );
  }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (kDebugMode) {
          debugPrint('Notification tapped with data: ${message.data}');
        }
      });
    } catch (e) {
      debugPrint('Notification init skipped: $e');
    }
  }

  Future<String?> _fetchFcmTokenWithRetry({int attempts = 15}) async {
    for (int i = 0; i < attempts; i++) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken;
        try {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        } on FirebaseException catch (e) {
          if (e.code == 'apns-token-not-set') {
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          rethrow;
        }
        if (apnsToken == null) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        return token;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  Widget _withFixedTextScale(Widget child, BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            _withFixedTextScale(child ?? const SizedBox.shrink(), context),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Could not start the app.\n$_error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) =>
            _withFixedTextScale(child ?? const SizedBox.shrink(), context),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MyApp(forceUpdateRequired: _forceUpdateRequired);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.forceUpdateRequired = false});

  final bool forceUpdateRequired;

  Widget _buildWithFixedTextScale(BuildContext context, Widget child) {
    final mediaQuery = MediaQuery.of(context);
    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: TextScaler.noScaling),
      child: ConnectivityOverlay(child: child),
    );
  }

  String? _inferUserTypeFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final payloadBase64 = parts[1];
      final normalized = base64Url.normalize(payloadBase64);
      final payloadJson = utf8.decode(base64Url.decode(normalized));
      final payload = jsonDecode(payloadJson);

      final dynamic rawRole =
          payload['user_type'] ??
          payload['userType'] ??
          payload['user_role'] ??
          payload['role'] ??
          payload['type'];

      if (rawRole is! String) return null;

      final role = rawRole.toLowerCase();

      if (role.contains('tutor')) return 'tutor';
      if (role.contains('student')) return 'student';

      if (role == 'becometutor' || role == 'findtutor') {
        return role == 'becometutor' ? 'tutor' : 'student';
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appRootNavigatorKey,
      theme: AppTheme.lightTheme,
      builder: (context, child) =>
          _buildWithFixedTextScale(context, child ?? const SizedBox.shrink()),
      home: forceUpdateRequired
          ? const ForceUpdateScreen()
          : ValueListenableBuilder<AppLanguage>(
              valueListenable: AppLanguageState.current,
              builder: (context, language, _) {
                final token = PrefUtils.getToken();

                if (token.isEmpty) {
                  return HomePage(
                    language: language,
                    onLanguageChanged: (value) {
                      AppLanguageState.setLanguage(value);
                    },
                  );
                }

                final storedUserType = PrefUtils.getUserType();

                final inferredUserType = storedUserType.isNotEmpty
                    ? storedUserType
                    : _inferUserTypeFromToken(token);

                if (inferredUserType == 'tutor') {
                  return const TutorDashboardShell();
                }

                if (inferredUserType == 'student') {
                  return const StudentDashboardShell();
                }

                return HomePage(
                  language: language,
                  onLanguageChanged: (value) {
                    AppLanguageState.setLanguage(value);
                  },
                );
              },
            ),
    );
  }
}

int zegoAppID = 1896143529;
