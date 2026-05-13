import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';

/// Soft surface for a single field or dropdown (no full-page card).
class AuthInputShell extends StatelessWidget {
  const AuthInputShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(14), child: child);
  }
}

/// Title + optional subtitle with a small brand accent (no card).
class AuthScreenHeading extends StatelessWidget {
  const AuthScreenHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ConstColor.primaryBlue,
                ConstColor.accentTeal.withValues(alpha: 0.85),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.65,
                  height: 1.12,
                  color: ConstColor.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: ConstColor.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Spacing after the heading block before the first field.
class AuthHeadingSpacer extends StatelessWidget {
  const AuthHeadingSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: ConstSize.grid * 3);
  }
}
