import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:language_learning_app/core/constants/const_api_url.dart';
import 'package:language_learning_app/core/constants/utils.dart';
import 'package:language_learning_app/model/messaging/message_model.dart';
import 'package:web_socket_channel/io.dart';

class MessagingSocketEvent {
  const MessagingSocketEvent({
    required this.type,
    this.message,
    this.conversationId,
    this.unreadCount,
    this.detail,
  });

  final String type;
  final MessageModel? message;
  final String? conversationId;
  final int? unreadCount;
  final String? detail;
}

class MessagingSocketClient {
  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  String? _subscribedConversationId;
  bool _disposed = false;
  bool _connectAttempted = false;

  final StreamController<MessagingSocketEvent> _eventsController =
      StreamController<MessagingSocketEvent>.broadcast();

  Stream<MessagingSocketEvent> get events => _eventsController.stream;

  bool get isConnected => _channel != null;

  /// Tries WebSocket once per client lifetime. Returns false if unavailable.
  Future<bool> connect() async {
    if (_disposed || _channel != null || _connectAttempted) {
      return _channel != null;
    }

    _connectAttempted = true;

    if (!ConstApiUrl.isMessagingWebSocketEnabled) {
      if (kDebugMode) {
        debugPrint('Messaging WS skipped for local API host, using polling');
      }
      return false;
    }

    final token = PrefUtils.getToken().trim();
    if (token.isEmpty) return false;

    final uri = ConstApiUrl.buildMessagesSocketUri(token: token);

    try {
      if (kDebugMode) {
        debugPrint('Messaging WS connecting: $uri');
      }

      final socket = await WebSocket.connect(uri.toString()).timeout(
        const Duration(seconds: 5),
      );

      if (_disposed) {
        await socket.close();
        return false;
      }

      _channel = IOWebSocketChannel(socket);
      _subscription = _channel!.stream.listen(
        _handleRawMessage,
        onError: _handleStreamError,
        onDone: () => unawaited(_handleDisconnect()),
        cancelOnError: true,
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _send({'type': 'ping'});
      });

      if (_subscribedConversationId != null) {
        subscribe(_subscribedConversationId!);
      }

      if (kDebugMode) {
        debugPrint('Messaging WS connected');
      }

      return true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Messaging WS unavailable, using polling: $error');
      }
      await _handleDisconnect();
      return false;
    }
  }

  void _handleStreamError(Object error) {
    if (kDebugMode) {
      debugPrint('Messaging WS stream closed, using polling: $error');
    }
    unawaited(_handleDisconnect());
  }

  void subscribe(String conversationId) {
    if (_disposed) return;
    _subscribedConversationId = conversationId;
    _send({
      'type': 'subscribe',
      'conversation_id': conversationId,
    });
  }

  void unsubscribe(String conversationId) {
    if (_subscribedConversationId == conversationId) {
      _subscribedConversationId = null;
    }
    _send({
      'type': 'unsubscribe',
      'conversation_id': conversationId,
    });
  }

  void _send(Map<String, dynamic> payload) {
    final channel = _channel;
    if (channel == null || _disposed) return;
    try {
      channel.sink.add(jsonEncode(payload));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Messaging WS send failed: $error');
      }
      unawaited(_handleDisconnect());
    }
  }

  void _handleRawMessage(dynamic raw) {
    if (_disposed) return;

    Map<String, dynamic>? decoded;
    try {
      if (raw is String) {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      } else if (raw is Map) {
        decoded = Map<String, dynamic>.from(raw);
      }
    } catch (_) {
      return;
    }

    if (decoded == null) return;

    final type = (decoded['type'] ?? decoded['event'] ?? '').toString();
    if (type == 'pong') return;

    if (type == 'message.new' || type == 'message_new') {
      final messageRaw = _extractMessagePayload(decoded);
      if (messageRaw != null) {
        _eventsController.add(
          MessagingSocketEvent(
            type: 'message.new',
            message: MessageModel.fromJson(messageRaw),
          ),
        );
        return;
      }
    }

    if (type == 'conversation.updated') {
      final data = decoded['data'];
      if (data is Map) {
        _eventsController.add(
          MessagingSocketEvent(
            type: type,
            conversationId: (data['conversation_id'] ?? '').toString(),
            unreadCount: int.tryParse(
              (data['unread_count'] ?? '').toString(),
            ),
          ),
        );
        return;
      }
    }

    if (type == 'error') {
      final data = decoded['data'];
      final detail = data is Map
          ? (data['detail'] ?? '').toString()
          : decoded['detail']?.toString();
      _eventsController.add(
        MessagingSocketEvent(type: type, detail: detail),
      );
      return;
    }

    _eventsController.add(MessagingSocketEvent(type: type));
  }

  Map<String, dynamic>? _extractMessagePayload(Map<String, dynamic> decoded) {
    final direct = decoded['message'];
    if (direct is Map) {
      return Map<String, dynamic>.from(direct);
    }

    final data = decoded['data'];
    if (data is Map) {
      final nested = data['message'];
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
      if (data.containsKey('body') || data.containsKey('id')) {
        return Map<String, dynamic>.from(data);
      }
    }

    if (decoded.containsKey('body') && decoded.containsKey('id')) {
      return decoded;
    }

    return null;
  }

  Future<void> _handleDisconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    final channel = _channel;
    _channel = null;

    _pingTimer?.cancel();
    _pingTimer = null;

    if (channel != null) {
      try {
        await channel.sink.close();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    final conversationId = _subscribedConversationId;
    if (conversationId != null) {
      unsubscribe(conversationId);
    }

    _pingTimer?.cancel();
    _pingTimer = null;
    await _subscription?.cancel();
    _subscription = null;

    final channel = _channel;
    _channel = null;

    if (channel != null) {
      try {
        await channel.sink.close();
      } catch (_) {}
    }

    if (!_eventsController.isClosed) {
      await _eventsController.close();
    }
  }
}
