import '../../core/authed_api.dart';
import '../../models/meeting.dart';

class MeetingRepository {
  MeetingRepository(this._api);
  final AuthedApi _api;

  /// Crée une réunion et invite des participants.
  Future<Meeting> create({
    required DateTime startTime,
    required int duration,
    String? objet,
    String? room,
    int typeMedia = 1,
    required List<String> participantIds,
  }) async {
    final data = await _api.post("/api/meetings", {
      "startTime": startTime.toIso8601String(),
      "duration": duration,
      "objet": objet,
      "room": room,
      "type_media": typeMedia,
      "participants": participantIds,
    });
    return Meeting.fromJson(data);
  }

  /// Liste les réunions de l'utilisateur.
  Future<List<Meeting>> list() async {
    final data = await _api.get("/api/meetings");
    final raw = data["meetings"] as List?;
    if (raw == null) return [];
    return raw
        .map((m) => Meeting.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Récupère les détails d'une réunion spécifique.
  Future<Meeting> getDetails(String id) async {
    final data = await _api.get("/api/meetings/$id");
    return Meeting.fromJson(data["meeting"] as Map<String, dynamic>);
  }

  /// Modifie le statut d'une invitation (1: Pending, 2: Accepted, 3: Declined).
  Future<void> updateStatus(String id, int status) async {
    await _api.patch("/api/meetings/$id/status", {"status": status});
  }

  /// Clôture la réunion.
  Future<void> endMeeting(String id) async {
    await _api.put("/api/meetings/$id/end");
  }
}
