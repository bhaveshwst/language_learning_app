import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Single load; reflects `version:` in `pubspec.yaml` (e.g. 1.0.0).
abstract final class AppVersionInfo {
  AppVersionInfo._();

  static const String fallback = '1.0.0';

  static Future<String>? _future;

  static Future<String> get versionString =>
      _future ??= PackageInfo.fromPlatform().then((p) => p.version);
}

class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, required this.style, this.textAlign});

  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AppVersionInfo.versionString,
      builder: (context, snapshot) {
        final text = snapshot.data ?? AppVersionInfo.fallback;
        return Text(text, style: style, textAlign: textAlign);
      },
    );
  }
}

class AppVersionWithLogo extends StatelessWidget {
  const AppVersionWithLogo({
    super.key,
    required this.style,
    this.textAlign,
    this.logoSize = 25,
    this.logoBottomSpacing = 2,
  });

  final TextStyle style;
  final TextAlign? textAlign;
  final double logoSize;
  final double logoBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/icon.png',
          width: logoSize,
          height: logoSize,
        ),
        SizedBox(height: logoBottomSpacing),
        AppVersionLabel(style: style, textAlign: textAlign),
      ],
    );
  }
}

/// Right side of [AppBar.actions] (gray, compact).
class AppVersionAppBarAction extends StatelessWidget {
  const AppVersionAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: AppVersionWithLogo(
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
          logoSize: 25,
          logoBottomSpacing: 1,
        ),
      ),
    );
  }
}

/// Aligned with large dashboard titles (no AppBar).
class AppVersionHeaderBadge extends StatelessWidget {
  const AppVersionHeaderBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 8),
      child: AppVersionWithLogo(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}

/// Bottom footer on auth-style screens (welcome, login, signup, etc.).
class AppVersionFooter extends StatelessWidget {
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: AppVersionWithLogo(
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
