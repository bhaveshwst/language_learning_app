class NotificationListingModel {
  String? responseCode;
  String? detail;
  List<NotificationListItem>? data;

  NotificationListingModel({this.responseCode, this.detail, this.data});

  NotificationListingModel.fromJson(Map<String, dynamic> json) {
    responseCode = json['response_code']?.toString();
    detail = json['detail']?.toString();
    if (json['data'] is List) {
      data = (json['data'] as List)
          .map(NotificationListItem.fromDynamic)
          .where((item) => item.displayMessage.isNotEmpty)
          .toList();
    } else {
      data = <NotificationListItem>[];
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['response_code'] = responseCode;
    map['detail'] = detail;
    map['data'] = (data ?? const <NotificationListItem>[])
        .map((e) => e.toJson())
        .toList();
    return map;
  }

  NotificationListingModel copyWith({
    String? responseCode,
    String? detail,
    List<NotificationListItem>? data,
  }) {
    return NotificationListingModel(
      responseCode: responseCode ?? this.responseCode,
      detail: detail ?? this.detail,
      data: data ?? this.data,
    );
  }
}

enum NotificationKind {
  sessionStart,
  sessionCancel,
  general,
}

class NotificationListItem {
  final String notificationId;
  final String message;
  final String raw;
  final String readUnread;
  final String notificationType;

  const NotificationListItem({
    required this.notificationId,
    required this.message,
    required this.raw,
    required this.readUnread,
    this.notificationType = '',
  });

  NotificationKind get kind {
    final type = notificationType.toLowerCase();
    final text = displayMessage.toLowerCase();
    if (_matchesCancel(type) || _matchesCancel(text)) {
      return NotificationKind.sessionCancel;
    }
    if (_matchesStart(type) || _matchesStart(text)) {
      return NotificationKind.sessionStart;
    }
    return NotificationKind.general;
  }

  static bool _matchesCancel(String value) {
    return value.contains('cancel') || value.contains('cancelled');
  }

  static bool _matchesStart(String value) {
    if (value.contains('cancel')) return false;
    return value.contains('start') || value.contains('started');
  }

  String get displayMessage {
    final msg = message.trim();
    if (msg.isNotEmpty) return msg;
    return raw.trim();
  }

  static NotificationListItem fromDynamic(dynamic input) {
    if (input is Map<String, dynamic>) {
      return NotificationListItem(
        notificationId: (input['notification_id'] ?? input['id'] ?? '')
            .toString()
            .trim(),
        message: (input['message'] ?? '').toString().trim(),
        raw: input.toString(),
        readUnread: (input['read_unread'] ?? '').toString().trim(),
        notificationType: _parseNotificationType(input),
      );
    }
    if (input is Map) {
      final map = Map<String, dynamic>.from(input);
      return fromDynamic(map);
    }

    final raw = input?.toString() ?? '';
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const NotificationListItem(
        notificationId: '',
        message: '',
        raw: '',
        readUnread: '',
        notificationType: '',
      );
    }

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      final id = _extractMapLikeValue(trimmed, 'notification_id');
      final msg = _extractMessageFromMapLikeString(trimmed);
      return NotificationListItem(
        notificationId: id,
        message: msg,
        raw: trimmed,
        readUnread: _extractMapLikeValue(trimmed, 'read_unread'),
        notificationType: _extractMapLikeValue(trimmed, 'notification_type').isNotEmpty
            ? _extractMapLikeValue(trimmed, 'notification_type')
            : _extractMapLikeValue(trimmed, 'type'),
      );
    }

    return NotificationListItem(
      notificationId: '',
      message: trimmed,
      raw: trimmed,
      readUnread: '',
      notificationType: '',
    );
  }

  static String _parseNotificationType(Map<String, dynamic> input) {
    for (final key in [
      'notification_type',
      'notificationType',
      'type',
      'title',
    ]) {
      final value = (input[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _extractMapLikeValue(String source, String key) {
    final escapedKey = RegExp.escape(key);
    final match = RegExp('$escapedKey\\s*:\\s*([^,}]+)').firstMatch(source);
    return (match?.group(1) ?? '').trim();
  }

  static String _extractMessageFromMapLikeString(String source) {
    final msgMatch = RegExp(r'message\s*:\s*(.*)\}$').firstMatch(source);
    return (msgMatch?.group(1) ?? '').trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'message': message,
      'raw': raw,
      'read_unread': readUnread,
      'notification_type': notificationType,
    };
  }

  NotificationListItem copyWith({
    String? notificationId,
    String? message,
    String? raw,
    String? readUnread,
    String? notificationType,
  }) {
    return NotificationListItem(
      notificationId: notificationId ?? this.notificationId,
      message: message ?? this.message,
      raw: raw ?? this.raw,
      readUnread: readUnread ?? this.readUnread,
      notificationType: notificationType ?? this.notificationType,
    );
  }
}
