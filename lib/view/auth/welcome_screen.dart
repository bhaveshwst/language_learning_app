import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_image.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/view/auth/login_screen.dart';
import 'package:language_learning_app/view/auth/widgets/auth_screen_shell.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.isKorean,
    required this.onLanguageChanged,
  });

  final bool isKorean;
  final ValueChanged<bool> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final AppLanguage language = isKorean
        ? AppLanguage.korean
        : AppLanguage.english;

    return AuthScreenShell(
      showAppBar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            ConstImage.appLogo,
            fit: BoxFit.contain,
            width: 120,
            height: 120,
          ),
          const SizedBox(height: ConstSize.grid * 1),
          _TutorOptionCard(
            icon: Icons.search,
            iconBackground: const Color(0xFFEAF4FF),
            iconColor: ConstColor.primaryBlue,
            title: ConstString.text(language, 'findTutor'),
            subtitle: ConstString.text(language, 'findTutorSubtitle'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LoginScreen(language: language, role: UserRole.findTutor),
                ),
              );
            },
          ),
          const SizedBox(height: ConstSize.grid * 1.9),
          _TutorOptionCard(
            icon: Icons.school,
            iconBackground: ConstColor.accentTeal.withValues(alpha: 0.14),
            iconColor: ConstColor.accentTeal,
            title: ConstString.text(language, 'becomeTutor'),
            subtitle: ConstString.text(language, 'becomeTutorSubtitle'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(
                    language: language,
                    role: UserRole.becomeTutor,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: ConstSize.grid * 3),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ConstColor.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LangButton(
                    label: ConstString.text(AppLanguage.english, 'english'),
                    active: !isKorean,
                    onTap: () => onLanguageChanged(false),
                  ),
                ),
                Expanded(
                  child: _LangButton(
                    label: ConstString.text(AppLanguage.korean, 'korean'),
                    active: isKorean,
                    onTap: () => onLanguageChanged(true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ConstSize.grid * 2),
        ],
      ),
    );
  }
}

class _TutorOptionCard extends StatelessWidget {
  const _TutorOptionCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: ConstColor.card,
          borderRadius: BorderRadius.circular(ConstSize.radiusL),
          border: Border.all(color: ConstColor.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: ConstColor.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: ConstColor.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? ConstColor.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : ConstColor.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
