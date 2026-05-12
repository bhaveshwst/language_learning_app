import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/services/logout_service.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/core/widgets/app_version_widgets.dart';
import 'package:language_learning_app/view/auth/app_welcome_screen.dart';
import 'package:language_learning_app/view/student/screens/student_profile_complete_page.dart';
import 'package:language_learning_app/view/student/screens/student_report_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await LogoutService.logout(
        studentId: PrefUtils.getstudentid(),
        tutorId: PrefUtils.gettutorid(),
        fcmToken: PrefUtils.getFCMToken(),
      );

      if (context.mounted) {
        Navigator.pop(context);
      }
      await PrefUtils.clearPrefs();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppWelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        commonAlertDialog(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ConstColor.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            ConstSize.grid * 2,
            ConstSize.grid * 1,
            ConstSize.grid * 2,
            ConstSize.grid * 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: AppText(
                      'settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.35,
                        color: ConstColor.textPrimary,
                      ),
                    ),
                  ),
                  const AppVersionHeaderBadge(),
                ],
              ),
              const SizedBox(height: ConstSize.grid * 2),
              _SectionCard(
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_rounded,
                      titleKey: 'profile',
                      onTap: () {
                        final language = AppLanguageState.currentLanguage;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentProfileCompletePage(
                              language: language,
                              role: UserRole.findTutor,
                            ),
                          ),
                        );
                      },
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.description_outlined,
                      titleKey: 'termsAndConditions',
                      onTap: () {
                        launchUrl(
                          Uri.parse('https://konnected.wisdomsquare.net/terms'),
                        );
                      },
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      titleKey: 'privacyPolicy',
                      onTap: () {
                        launchUrl(
                          Uri.parse(
                            'https://konnected.wisdomsquare.net/privacy',
                          ),
                        );
                      },
                    ),
                    const _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.flag_outlined,
                      titleKey: 'reportList',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentReportListScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ConstSize.grid * 2.5),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: AppText(
                  'language',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: ConstColor.textSecondary,
                  ),
                ),
              ),
              ValueListenableBuilder<AppLanguage>(
                valueListenable: AppLanguageState.current,
                builder: (context, language, _) {
                  return _SectionCard(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LangButton(
                            label: ConstString.text(
                              AppLanguage.english,
                              'english',
                            ),
                            active: language == AppLanguage.english,
                            onTap: () => AppLanguageState.setLanguage(
                              AppLanguage.english,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _LangButton(
                            label: ConstString.text(
                              AppLanguage.korean,
                              'korean',
                            ),
                            active: language == AppLanguage.korean,
                            onTap: () => AppLanguageState.setLanguage(
                              AppLanguage.korean,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _LangButton(
                            label: ConstString.text(
                              AppLanguage.spanish,
                              'spanish',
                            ),
                            active: language == AppLanguage.spanish,
                            onTap: () => AppLanguageState.setLanguage(
                              AppLanguage.spanish,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: ConstSize.grid * 3),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: FilledButton(
                  onPressed: () async {
                    await _handleLogout(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: ConstColor.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 22),
                      SizedBox(width: 10),
                      AppText(
                        'logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      endIndent: 12,
      color: ConstColor.border.withValues(alpha: 0.75),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.titleKey,
    required this.onTap,
  });

  final IconData icon;
  final String titleKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: ConstColor.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ConstColor.primaryBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppText(
                  titleKey,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: ConstColor.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ConstColor.textSecondary.withValues(alpha: 0.55),
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ConstColor.border.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: ConstColor.primaryBlue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? ConstColor.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white : ConstColor.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: active ? 0.2 : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
