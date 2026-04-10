import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Keys must match Firebase Remote Config parameter names.
abstract final class RemoteConfigKeys {
  static const androidMinVersion = 'language_learning_app_android';
  static const iosMinVersion = 'language_learning_app_ios';
  static const forceAppUpdate = 'language_learning_app_force_app_update';
}

class ForceUpdateResult {
  const ForceUpdateResult({required this.mustUpdate});

  final bool mustUpdate;

  static const allow = ForceUpdateResult(mustUpdate: false);
}

/// Fetches Remote Config and decides whether the user must update the app.
class AppRemoteConfig {
  AppRemoteConfig._();

  static final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  static Future<void> initialize() async {
    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );

    await _rc.setDefaults(const {
      RemoteConfigKeys.androidMinVersion: '1.0.0',
      RemoteConfigKeys.iosMinVersion: '1.0.0',
      RemoteConfigKeys.forceAppUpdate: '0',
    });

    try {
      await _rc.fetchAndActivate();
    } catch (e, st) {
      debugPrint('Remote Config fetch failed, using defaults/cache: $e\n$st');
    }
  }

  static Future<ForceUpdateResult> evaluateForceUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final current = packageInfo.version;

    final forceRaw = _rc.getString(RemoteConfigKeys.forceAppUpdate).trim();
    if (_isTruthy(forceRaw)) {
      return const ForceUpdateResult(mustUpdate: true);
    }

    final minVersion = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        _rc.getString(RemoteConfigKeys.androidMinVersion).trim(),
      TargetPlatform.iOS => _rc.getString(RemoteConfigKeys.iosMinVersion).trim(),
      _ => '',
    };

    if (minVersion.isEmpty) {
      return ForceUpdateResult.allow;
    }

    if (_compareVersions(current, minVersion) < 0) {
      return const ForceUpdateResult(mustUpdate: true);
    }

    return ForceUpdateResult.allow;
  }

  static bool _isTruthy(String value) {
    final v = value.toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }

  /// Negative if [a] < [b], zero if equal, positive if [a] > [b].
  static int _compareVersions(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
    final len = pa.length > pb.length ? pa.length : pb.length;
    while (pa.length < len) {
      pa.add(0);
    }
    while (pb.length < len) {
      pb.add(0);
    }
    for (var i = 0; i < len; i++) {
      final c = pa[i].compareTo(pb[i]);
      if (c != 0) {
        return c;
      }
    }
    return 0;
  }
}
