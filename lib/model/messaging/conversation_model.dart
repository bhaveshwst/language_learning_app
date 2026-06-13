class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.studentId,
    required this.tutorId,
    required this.peerId,
    required this.peerName,
    this.peerImageUrl,
    this.lastMessageText,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  final String id;
  final String studentId;
  final String tutorId;
  final String peerId;
  final String peerName;
  final String? peerImageUrl;
  final String? lastMessageText;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['id'] ?? '').toString(),
      studentId: (json['student_id'] ?? '').toString(),
      tutorId: (json['tutor_id'] ?? '').toString(),
      peerId: (json['other_party_id'] ?? '').toString(),
      peerName: (json['other_party_name'] ?? '').toString(),
      peerImageUrl: (json['other_party_image'] ?? '').toString().trim().isEmpty
          ? null
          : (json['other_party_image'] ?? '').toString(),
      lastMessageText: (json['last_message_text'] ?? '').toString().trim().isEmpty
          ? null
          : (json['last_message_text'] ?? '').toString(),
      lastMessageAt: _parseDate(json['last_message_at']),
      unreadCount: int.tryParse((json['unread_count'] ?? '0').toString()) ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  ConversationModel copyWith({
    String? id,
    String? studentId,
    String? tutorId,
    String? peerId,
    String? peerName,
    String? peerImageUrl,
    String? lastMessageText,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      tutorId: tutorId ?? this.tutorId,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerImageUrl: peerImageUrl ?? this.peerImageUrl,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
