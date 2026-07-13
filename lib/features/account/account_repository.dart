import '../../core/authed_api.dart';
import '../../models/user_session.dart';

/// Champs de profil renvoyés après mise à jour.
class ProfileUpdate {
  final String? pseudo;
  final String? avatarUrl;
  final String? statusMsg;
  final String? nom;
  ProfileUpdate({this.pseudo, this.avatarUrl, this.statusMsg, this.nom});
}

class AccountRepository {
  AccountRepository(this._api);
  final AuthedApi _api;

  Future<ProfileUpdate> updateProfile({String? pseudo, String? statusMsg, String? avatarUrl, String? nom}) async {
    final body = <String, dynamic>{};
    if (pseudo != null) body["pseudo"] = pseudo;
    if (statusMsg != null) body["statusMsg"] = statusMsg;
    if (avatarUrl != null) body["avatarUrl"] = avatarUrl;
    if (nom != null) body["nom"] = nom;
    final data = await _api.patch("/api/account/profile", body);
    return ProfileUpdate(
      pseudo: data["pseudo"] as String?,
      avatarUrl: data["avatarUrl"] as String?,
      statusMsg: data["statusMsg"] as String?,
      nom: data["nom"] as String?,
    );
  }

  /// Récupère l'historique des connexions de l'utilisateur.
  Future<List<UserSession>> getSessions() async {
    final data = await _api.get("/api/account/sessions");
    final raw = data["sessions"] as List?;
    if (raw == null) return [];
    return raw
        .map((s) => UserSession.fromJson(s as Map<String, dynamic>))
        .toList();
  }
}
