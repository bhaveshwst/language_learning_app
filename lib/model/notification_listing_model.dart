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
}

class NotificationListItem {
  final String notificationId;
  final String message;
  final String raw;

  const NotificationListItem({
    required this.notificationId,
    required this.message,
    required this.raw,
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
      );
    }

    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      final id = _extractMapLikeValue(trimmed, 'notification_id');
      final msg = _extractMessageFromMapLikeString(trimmed);
      return NotificationListItem(
        notificationId: id,
        message: msg,
        raw: trimmed,
      );
    }

    return NotificationListItem(
      notificationId: '',
      message: trimmed,
      raw: trimmed,
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
    };
  }
}
