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

class NotificationListItem {
  final String notificationId;
  final String message;
  final String raw;
  final String readUnread;

  const NotificationListItem({
    required this.notificationId,
    required this.message,
    required this.raw,
    required this.readUnread,
  });

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
      );
    }

    return NotificationListItem(
      notificationId: '',
      message: trimmed,
      raw: trimmed,
      readUnread: '',
    );
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
    };
  }

  NotificationListItem copyWith({
    String? notificationId,
    String? message,
    String? raw,
    String? readUnread,
  }) {
    return NotificationListItem(
      notificationId: notificationId ?? this.notificationId,
      message: message ?? this.message,
      raw: raw ?? this.raw,
      readUnread: readUnread ?? this.readUnread,
    );
  }
}
