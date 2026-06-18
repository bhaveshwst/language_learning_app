import 'package:language_learning_app/core/messaging/messaging_media_url.dart';
import 'package:language_learning_app/model/messaging/message_type.dart';
import 'package:language_learning_app/model/messaging/messaging_user_role.dart';

class MessageModel {
  const MessageModel({
    required this.id,
    required this.body,
    required this.senderRole,
    required this.createdAt,
    this.conversationId,
    this.senderId,
    this.messageType = MessageType.text,
    this.imageUrl,
    this.localImagePath,
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
  final MessageType messageType;
  final String? imageUrl;
  final String? localImagePath;
  final bool isRead;
  final bool isPending;
  final bool isFailed;

  bool get isImageMessage => messageType == MessageType.image;

  bool get hasImageContent =>
      (imageUrl ?? '').trim().isNotEmpty || (localImagePath ?? '').trim().isNotEmpty;

  bool get hasTextBody {
    final text = body.trim();
    if (text.isEmpty) return false;
    if (!isImageMessage) return true;
    return !_isPhotoPlaceholder(text);
  }

  static bool _isPhotoPlaceholder(String text) {
    final normalized = text.trim().toLowerCase();
    return normalized == 'photo' ||
        normalized == '📷 photo' ||
        normalized == '사진' ||
        normalized == 'foto';
  }

  bool isMine(MessagingUserRole viewerRole) => senderRole == viewerRole;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final roleRaw = (json['sender_role'] ?? '').toString().toLowerCase();
    final imageUrl = _readImageUrl(json);
    final messageType = MessageType.fromApi(
      (json['message_type'] ?? json['type'] ?? '').toString(),
    );

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
      messageType: imageUrl != null ? MessageType.image : messageType,
      imageUrl: imageUrl,
      isRead: json['is_read'] == true || json['is_read']?.toString() == '1',
    );
  }

  static String? _readImageUrl(Map<String, dynamic> json) {
    for (final key in ['image_url', 'photo_url', 'upload_image', 'image']) {
      final resolved = MessagingMediaUrl.resolve((json[key] ?? '').toString());
      if (resolved != null) return resolved;
    }
    return null;
  }

  MessageModel copyWith({
    String? id,
    String? body,
    MessagingUserRole? senderRole,
    DateTime? createdAt,
    String? conversationId,
    String? senderId,
    MessageType? messageType,
    String? imageUrl,
    String? localImagePath,
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
      messageType: messageType ?? this.messageType,
      imageUrl: imageUrl ?? this.imageUrl,
      localImagePath: localImagePath ?? this.localImagePath,
      isRead: isRead ?? this.isRead,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
    );
  }
}
