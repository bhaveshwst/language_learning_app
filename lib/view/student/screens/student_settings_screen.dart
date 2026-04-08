import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/user_role.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/view/auth/app_welcome_screen.dart';
import 'package:language_learning_app/view/student/screens/student_profile_complete_page.dart';
import 'package:language_learning_app/view/student/screens/student_reviews_page.dart';

class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ConstSize.grid * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ConstSize.grid * 2),
            _SectionCard(
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.person_outline,
                    titleKey: 'profile',
                    onTap: () {
                      final language = AppLanguageState.isKorean.value
                          ? AppLanguage.korean
                          : AppLanguage.english;
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
                  const Divider(height: 1, color: ConstColor.border),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    titleKey: 'termsAndConditions',
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: ConstColor.border),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    titleKey: 'privacyPolicy',
                    onTap: () {},
                  ),
                  // const Divider(height: 1, color: ConstColor.border),
                  // _SettingsTile(
                  //   icon: Icons.rate_review_outlined,
                  //   titleKey: 'review',
                  //   onTap: () => Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (_) => const StudentReviewsPage(),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: ConstSize.grid * 2),
            const AppText(
              'language',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: ConstSize.grid),
            ValueListenableBuilder<bool>(
              valueListenable: AppLanguageState.isKorean,
              builder: (context, isKorean, _) {
                return Container(
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
                          labelKey: 'english',
                          active: !isKorean,
                          onTap: () => AppLanguageState.isKorean.value = false,
                        ),
                      ),
                      Expanded(
                        child: _LangButton(
                          labelKey: 'korean',
                          active: isKorean,
                          onTap: () => AppLanguageState.isKorean.value = true,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: ConstSize.grid * 3),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ConstColor.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ConstSize.radiusM),
                  ),
                ),
                onPressed: () async {
                  await PrefUtils.clearPrefs();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AppWelcomeScreen()),
                    (route) => false,
                  );
                },
                child: const AppText(
                  'logout',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: ConstColor.primaryBlue),
      title: AppText(
        titleKey,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ConstSize.grid),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ConstSize.radiusL),
        border: Border.all(color: ConstColor.border),
      ),
      child: child,
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.labelKey,
    required this.active,
    required this.onTap,
  });

  final String labelKey;
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
          child: AppText(
            labelKey,
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
