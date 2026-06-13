import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:language_learning_app/core/constants/client_cookie.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/model/messaging/conversation_model.dart';
import 'package:language_learning_app/model/messaging/message_model.dart';

class MessagingApiException implements Exception {
  MessagingApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MessagingApiHelper {
  MessagingApiHelper._();

  static Future<Map<String, dynamic>> _decodeResponse(
    Future<http.Response> responseFuture,
  ) async {
    final response = await responseFuture;
    Map<String, dynamic>? decoded;
    try {
      final raw = jsonDecode(response.body);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      }
    } catch (_) {}

    if (response.statusCode != 200 || decoded == null) {
      throw MessagingApiException(
        decoded?['detail']?.toString() ?? 'Request failed',
      );
    }

    final code = decoded['response_code']?.toString() ?? '';
    if (code != '1') {
      throw MessagingApiException(
        decoded['detail']?.toString() ?? 'Request failed',
      );
    }

    return decoded;
  }

  static Map<String, dynamic> _data(Map<String, dynamic> decoded) {
    final data = decoded['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  static Future<List<ConversationModel>> fetchConversations({
    required String? studentId,
    required String? tutorId,
  }) async {
    final decoded = await _decodeResponse(
      AppHttpClient.post(
        ConstApiUrl.messagesConversationsUrl,
        body: {
          'student_id': studentId,
          'tutor_id': tutorId,
        },
      ),
    );

    final data = _data(decoded);
    final rawList = data['conversations'];
    if (rawList is! List) return const [];

    return rawList
        .whereType<Map>()
        .map((item) => ConversationModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static Future<ConversationModel> getOrCreateConversation({
    required String studentId,
    required String tutorId,
  }) async {
    final decoded = await _decodeResponse(
      AppHttpClient.post(
        ConstApiUrl.messagesGetOrCreateConversationUrl,
        body: {
          'student_id': studentId,
          'tutor_id': tutorId,
        },
      ),
    );

    final conversation = _data(decoded)['conversation'];
    if (conversation is! Map) {
      throw MessagingApiException('Conversation not found');
    }

    return ConversationModel.fromJson(Map<String, dynamic>.from(conversation));
  }

  static Future<List<MessageModel>> fetchMessages({
    required String conversationId,
    required String studentId,
    required String tutorId,
    int limit = 50,
    String? beforeMessageId,
    String? sinceMessageId,
  }) async {
    final decoded = await _decodeResponse(
      AppHttpClient.post(
        ConstApiUrl.messagesListUrl,
        body: {
          'conversation_id': conversationId,
          'student_id': studentId,
          'tutor_id': tutorId,
          'limit': limit,
          'before_message_id': beforeMessageId,
          'since_message_id': sinceMessageId,
        },
      ),
    );

    final rawList = _data(decoded)['messages'];
    if (rawList is! List) return const [];

    return rawList
        .whereType<Map>()
        .map((item) => MessageModel.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  static Future<MessageModel> sendMessage({
    required String conversationId,
    required String studentId,
    required String tutorId,
    required String senderRole,
    required String body,
  }) async {
    final decoded = await _decodeResponse(
      AppHttpClient.post(
        ConstApiUrl.messagesSendUrl,
        body: {
          'conversation_id': conversationId,
          'student_id': studentId,
          'tutor_id': tutorId,
          'sender_role': senderRole,
          'body': body,
        },
      ),
    );

    final message = _data(decoded)['message'];
    if (message is! Map) {
      throw MessagingApiException('Message not returned');
    }

    return MessageModel.fromJson(Map<String, dynamic>.from(message));
  }

  static Future<Map<String, int>> unreadCountsByPeerId({
    required String? studentId,
    required String? tutorId,
  }) async {
    final conversations = await fetchConversations(
      studentId: studentId,
      tutorId: tutorId,
    );

    return {
      for (final conversation in conversations)
        if (conversation.peerId.isNotEmpty)
          conversation.peerId: conversation.unreadCount,
    };
  }

  static Future<void> markConversationRead({
    required String conversationId,
    required String studentId,
    required String tutorId,
    required String readerRole,
  }) async {
    await _decodeResponse(
      AppHttpClient.post(
        ConstApiUrl.messagesMarkReadUrl,
        body: {
          'conversation_id': conversationId,
          'student_id': studentId,
          'tutor_id': tutorId,
          'reader_role': readerRole,
        },
      ),
    );
  }
}
