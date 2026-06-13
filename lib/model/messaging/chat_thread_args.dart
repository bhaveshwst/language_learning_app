import 'package:language_learning_app/model/messaging/messaging_user_role.dart';

/// Navigation arguments for opening a 1:1 chat thread.
class ChatThreadArgs {
  const ChatThreadArgs({
    required this.viewerRole,
    required this.selfId,
    required this.peerId,
    required this.peerName,
    this.peerImageUrl,
    this.conversationId,
  });

  final MessagingUserRole viewerRole;
  final String selfId;
  final String peerId;
  final String peerName;
  final String? peerImageUrl;
  final String? conversationId;

  String get studentId =>
      viewerRole.isStudent ? selfId.trim() : peerId.trim();

  String get tutorId => viewerRole.isTutor ? selfId.trim() : peerId.trim();

  String get senderRole => viewerRole.isStudent ? 'student' : 'tutor';

  String get readerRole => senderRole;
}
