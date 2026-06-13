import 'package:language_learning_app/model/messaging/messaging_user_role.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.body,
    required this.senderRole,
    required this.createdAt,
    this.conversationId,
    this.senderId,
    this.isRead = false,
    this.isPending = false,
    this.isFailed = false,
  });

  final String id;
  final String body;
  final MessagingUserRole senderRole;
  final DateTime createdAt;
  final String? conversationId;
  final String? senderId;
  final bool isRead;
  final bool isPending;
  final bool isFailed;

  bool isMine(MessagingUserRole viewerRole) => senderRole == viewerRole;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final roleRaw = (json['sender_role'] ?? '').toString().toLowerCase();
    return MessageModel(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      senderId: (json['sender_id'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      senderRole: roleRaw == 'tutor'
          ? MessagingUserRole.tutor
          : MessagingUserRole.student,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      isRead: json['is_read'] == true || json['is_read']?.toString() == '1',
    );
  }

  MessageModel copyWith({
    String? id,
    String? body,
    MessagingUserRole? senderRole,
    DateTime? createdAt,
    String? conversationId,
    String? senderId,
    bool? isRead,
    bool? isPending,
    bool? isFailed,
  }) {
    return MessageModel(
      id: id ?? this.id,
      body: body ?? this.body,
      senderRole: senderRole ?? this.senderRole,
      createdAt: createdAt ?? this.createdAt,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      isRead: isRead ?? this.isRead,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
    );
  }
}
