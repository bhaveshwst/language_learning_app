import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';

/// Populated at startup and refreshed from home dashboards before join/login.
String deviceInfo = '';

Future<void> loadAppDeviceInfo() async {
  final appVersion = await AppVersionInfo.versionString;
  final plugin = DeviceInfoPlugin();
  try {
    if (Platform.isIOS) {
      final data = await plugin.iosInfo;
      deviceInfo =
          '${data.model}_${data.name.toString().replaceAll(' ', '_')}_${data.systemName}_${data.systemVersion}_KONNECTED_APP_($appVersion)';
    } else if (Platform.isAndroid) {
      final data = await plugin.androidInfo;
      deviceInfo =
          '${data.brand}_${data.model}_${data.device}_${data.version.release}_KONNECTED_APP_($appVersion)';
    }
  } on PlatformException {
    deviceInfo = 'Error: Failed to get platform data';
  }
  if (kDebugMode) {
    debugPrint('Device Info: $deviceInfo');
  }
}
