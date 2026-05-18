import 'package:flutter/material.dart';
import 'package:language_learning_app/core/constants/const_color.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_size.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/services/delete_account_service.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/core/widgets/app_text.dart';
import 'package:language_learning_app/view/auth/app_welcome_screen.dart';
import 'package:language_learning_app/view/auth/widgets/auth_text_field.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _showReasonError = false;
  bool _isLoading = false;

  String t(String key) =>
      ConstString.text(AppLanguageState.currentLanguage, key);

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      if (_showReasonError && _reasonController.text.trim().isNotEmpty) {
        setState(() => _showReasonError = false);
      }
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _onDeletePressed() async {
    final reason = _reasonController.text.trim();
    setState(() => _showReasonError = true);
    if (reason.isEmpty) {
      commonAlertDialog(context, t('enterDeleteReasonError'));
      return;
    }
    if (reason.length < 10) {
      commonAlertDialog(context, t('enterDeleteReasonErrorLength'));
      return;
    }

    final language = AppLanguageState.currentLanguage;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(ConstString.text(language, 'deleteAccountConfirmTitle')),
          content: Text(
            ConstString.text(language, 'deleteAccountConfirmMessage'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(ConstString.text(language, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                ConstString.text(language, 'delete'),
                style: const TextStyle(color: ConstColor.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await DeleteAccountService.deleteAuthenticatedAccount(
        studentId: PrefUtils.getstudentid(),
        tutorId: PrefUtils.gettutorid(),
        fcmToken: PrefUtils.getFCMToken(),
        reason: reason,
      );

      // HTTP 200 from delete-account: go straight to first screen.
      if (mounted) Navigator.pop(context);
      await PrefUtils.clearPrefs();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppWelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() => _isLoading = false);
        commonAlertDialog(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: ConstColor.background,
      appBar: AppBar(
        backgroundColor: ConstColor.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: AppText(
          'deleteAccountTitle',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ConstColor.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            ConstSize.grid * 2,
            ConstSize.grid,
            ConstSize.grid * 2,
            ConstSize.grid * 3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WarningBanner(text: t('deleteAccountWarning')),
              const SizedBox(height: ConstSize.grid * 2.5),
              Text(
                t('deleteAccountReasonLabel'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ConstColor.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: ConstColor.border.withValues(alpha: 0.75),
                  ),
                ),
                child: AuthTextField(
                  hint: t('deleteAccountReasonHint'),
                  controller: _reasonController,
                  maxLines: 5,
                  // errorText: _showReasonError && reason.isEmpty
                  //     ? t('enterDeleteReasonError')
                  //     : null,
                ),
              ),
              const SizedBox(height: ConstSize.grid * 3),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _onDeletePressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: ConstColor.error,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: ConstColor.error.withValues(
                      alpha: 0.45,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: AppText(
                    'deleteAccount',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
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

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ConstColor.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ConstColor.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: ConstColor.error.withValues(alpha: 0.9),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ConstColor.error.withValues(alpha: 0.95),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
