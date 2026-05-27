import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:language_learning_app/core/constants/store_config.dart';
import 'package:language_learning_app/core/theme/app_theme.dart';

/// Blocks the app until the user opens the store listing (non-dismissible).
class ForceUpdateScreen extends StatefulWidget {
  const ForceUpdateScreen({super.key});

  @override
  State<ForceUpdateScreen> createState() => _ForceUpdateScreenState();
}

class _ForceUpdateScreenState extends State<ForceUpdateScreen> {
  bool _opening = false;

  Future<void> _openStore() async {
    setState(() => _opening = true);
    try {
      final info = await PackageInfo.fromPlatform();
      final uri = _storeUri(info);
      if (uri == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not build store link for this platform.'),
            ),
          );
        }
        return;
      }

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the store.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _opening = false);
      }
    }
  }

  Uri? _storeUri(PackageInfo info) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final id = info.packageName;
        return Uri.parse('https://play.google.com/store/apps/details?id=$id');
      case TargetPlatform.iOS:
        if (kIosAppStoreId.isNotEmpty) {
          return Uri.parse(
            '$kIosAppStoreScheme://apps.apple.com/app/id$kIosAppStoreId',
          );
        }
        return Uri.parse('$kIosAppStoreScheme://apps.apple.com/');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.system_update_rounded,
                    size: 72,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Update required',
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'A new version of the app is required to continue. '
                    'Please update from the store.',
                    textAlign: TextAlign.center,
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _opening ? null : _openStore,
                      child: _opening
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update in store'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
