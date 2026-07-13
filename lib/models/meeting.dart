class MeetingParticipant {
  final String id;
  final String meetingId;
  final String userId;
  final String userName;
  final int status; // 1: Pending, 2: Accepted, 3: Declined
  final DateTime? startTime;
  final bool connecte;
  final int? duration;

  MeetingParticipant({
    required this.id,
    required this.meetingId,
    required this.userId,
    required this.userName,
    required this.status,
    this.startTime,
    required this.connecte,
    this.duration,
  });

  factory MeetingParticipant.fromJson(Map<String, dynamic> j) => MeetingParticipant(
        id: j["id"] as String,
        meetingId: j["meetingId"] as String,
        userId: j["userId"] as String,
        userName: (j["user"] as Map<String, dynamic>)["pseudo"] ?? "Inconnu",
        status: (j["status"] as num).toInt(),
        startTime: j["startTime"] != null ? DateTime.tryParse(j["startTime"] as String) : null,
        connecte: (j["connecte"] as bool?) ?? false,
        duration: (j["duration"] as num?)?.toInt(),
      );
}

class Meeting {
  final String id;
  final String organiserId;
  final DateTime startTime;
  final int duration;
  final String? objet;
  final String? room;
  final bool isEnd;
  final int typeMedia; // 1: Audio, 2: Video, 3: Mixed
  final List<MeetingParticipant> participants;

  Meeting({
    required this.id,
    required this.organiserId,
    required this.startTime,
    required this.duration,
    this.objet,
    this.room,
    required this.isEnd,
    required this.typeMedia,
    required this.participants,
  });

  factory Meeting.fromJson(Map<String, dynamic> j) => Meeting(
        id: j["idMeeting"] as String,
        organiserId: j["organiserId"] as String,
        startTime: DateTime.parse(j["startTime"] as String),
        duration: (j["duration"] as num).toInt(),
        objet: j["objet"] as String?,
        room: j["room"] as String?,
        isEnd: (j["isEnd"] as bool?) ?? false,
        typeMedia: (j["type_media"] as num).toInt(),
        participants: ((j["participants"] as List?) ?? [])
            .map((p) => MeetingParticipant.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
