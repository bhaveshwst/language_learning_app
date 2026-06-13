import 'package:flutter/material.dart';
import 'package:language_learning_app/core/auth/student_auth_gate.dart';
import 'package:language_learning_app/core/constants/const_dialog.dart';
import 'package:language_learning_app/core/constants/const_string.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/core/state/app_language_state.dart';
import 'package:language_learning_app/model/messaging/chat_thread_args.dart';
import 'package:language_learning_app/model/messaging/messaging_user_role.dart';
import 'package:language_learning_app/view/messaging/chat_screen.dart';
import 'package:language_learning_app/view/messaging/conversations_screen.dart';

class MessagingNavigation {
  MessagingNavigation._();

  static Future<void> openTutorChatInbox(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConversationsScreen()),
    );
  }

  static String _t(String key) =>
      ConstString.text(AppLanguageState.currentLanguage, key);

  static Future<void> openStudentChatWithTutor(
    BuildContext context, {
    required String tutorId,
    required String tutorName,
    String? tutorImageUrl,
    bool requireLogin = true,
  }) async {
    if (requireLogin && !StudentAuthGate.isLoggedIn) {
      final allowed = await StudentAuthGate.ensureLoggedInForBooking(
        context,
        messageKey: 'signInRequiredMessageChat',
      );
      if (!allowed || !context.mounted) return;
    }

    await PrefUtils.cacheResolvedStudentId();
    final studentId = PrefUtils.getResolvedStudentId();
    final normalizedTutorId = tutorId.trim();
    if (studentId.isEmpty || normalizedTutorId.isEmpty) {
      if (context.mounted) {
        commonAlertDialog(context, _t('chatUnableToOpen'));
      }
      return;
    }

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          args: ChatThreadArgs(
            viewerRole: MessagingUserRole.student,
            selfId: studentId,
            peerId: normalizedTutorId,
            peerName: tutorName.trim().isEmpty ? 'Tutor' : tutorName.trim(),
            peerImageUrl: tutorImageUrl,
          ),
        ),
      ),
    );
  }

  static Future<void> openTutorChatWithStudent(
    BuildContext context, {
    required String studentId,
    required String studentName,
    String? studentImageUrl,
    String? conversationId,
  }) async {
    final tutorId = PrefUtils.gettutorid().trim();
    final normalizedStudentId = studentId.trim();
    if (tutorId.isEmpty || normalizedStudentId.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          args: ChatThreadArgs(
            viewerRole: MessagingUserRole.tutor,
            selfId: tutorId,
            peerId: normalizedStudentId,
            peerName:
                studentName.trim().isEmpty ? 'Student' : studentName.trim(),
            peerImageUrl: studentImageUrl,
            conversationId: conversationId,
          ),
        ),
      ),
    );
  }
}
