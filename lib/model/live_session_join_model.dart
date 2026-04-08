class LiveSessionJoinModel {
  final String roomId;
  final String token;
  final String userId;
  final String userName;
  final String role;
  final String tutorId;
  final String slotId;
  final bool canEnterRoom;
  final bool hostJoined;
  final String? waitingMessage;
  final String? expiresAt;

  const LiveSessionJoinModel({
    required this.roomId,
    required this.token,
    required this.userId,
    required this.userName,
    required this.role,
    required this.tutorId,
    required this.slotId,
    required this.canEnterRoom,
    required this.hostJoined,
    this.waitingMessage,
    this.expiresAt,
  });

  factory LiveSessionJoinModel.fromJson(Map<String, dynamic> json) {
    return LiveSessionJoinModel(
      roomId: (json['room_id'] ?? json['roomId'] ?? '').toString().trim(),
      token: (json['token'] ?? '').toString().trim(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString().trim(),
      userName: (json['user_name'] ?? json['userName'] ?? '').toString(),
      role: (json['role'] ?? '').toString().toLowerCase(),
      tutorId: (json['tutor_id'] ?? json['tutorId'] ?? '').toString(),
      slotId: (json['slot_id'] ?? json['slotId'] ?? '').toString(),
      canEnterRoom:
          (json['can_enter_room'] ?? json['canEnterRoom'] ?? true) == true,
      hostJoined: (json['host_joined'] ?? json['hostJoined'] ?? false) == true,
      waitingMessage:
          (json['waiting_message'] ?? json['waitingMessage'])?.toString(),
      expiresAt: (json['expires_at'] ?? json['expiresAt'])?.toString(),
    );
  }
}
