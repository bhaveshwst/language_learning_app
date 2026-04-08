class LiveSessionAnalyticsModel {
  final String? responseCode;
  final String? detail;
  final LiveSessionAnalyticsData? data;

  const LiveSessionAnalyticsModel({this.responseCode, this.detail, this.data});

  factory LiveSessionAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return LiveSessionAnalyticsModel(
      responseCode: json['response_code']?.toString(),
      detail: json['detail']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? LiveSessionAnalyticsData.fromJson(json['data'])
          : null,
    );
  }
}

class LiveSessionAnalyticsData {
  final String roomId;
  final int bookedCount;
  final int joinedCount;
  final String? sessionEndedAt;
  final List<LiveSessionParticipant> participants;

  const LiveSessionAnalyticsData({
    required this.roomId,
    required this.bookedCount,
    required this.joinedCount,
    required this.sessionEndedAt,
    required this.participants,
  });

  factory LiveSessionAnalyticsData.fromJson(Map<String, dynamic> json) {
    final rawParticipants = json['participants'];
    final participants = <LiveSessionParticipant>[];
    if (rawParticipants is List) {
      for (final p in rawParticipants) {
        if (p is Map<String, dynamic>) {
          participants.add(LiveSessionParticipant.fromJson(p));
        }
      }
    }

    return LiveSessionAnalyticsData(
      roomId: (json['room_id'] ?? '').toString(),
      bookedCount: int.tryParse((json['booked_count'] ?? 0).toString()) ?? 0,
      joinedCount: int.tryParse((json['joined_count'] ?? 0).toString()) ?? 0,
      sessionEndedAt: json['session_ended_at']?.toString(),
      participants: participants,
    );
  }
}

class LiveSessionParticipant {
  final String actorId;
  final String actorType;
  final int totalSeconds;
  final String? firstJoinedAt;
  final String? lastLeftAt;

  const LiveSessionParticipant({
    required this.actorId,
    required this.actorType,
    required this.totalSeconds,
    required this.firstJoinedAt,
    required this.lastLeftAt,
  });

  factory LiveSessionParticipant.fromJson(Map<String, dynamic> json) {
    return LiveSessionParticipant(
      actorId: (json['actor_id'] ?? '').toString(),
      actorType: (json['actor_type'] ?? '').toString(),
      totalSeconds: int.tryParse((json['total_seconds'] ?? 0).toString()) ?? 0,
      firstJoinedAt: json['first_joined_at']?.toString(),
      lastLeftAt: json['last_left_at']?.toString(),
    );
  }
}
