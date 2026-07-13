/// Utilisateur authentifié tel que renvoyé par l'API.
class AuthUser {
  final String id;
  final String email;
  final String alanyaPhone; // numéro Alanya généré par le backend
  final String? nom;
  final String? pseudo;
  final String? avatarUrl;
  final String? statusMsg;
  final int? idPays;

  AuthUser({
    required this.id,
    required this.email,
    required this.alanyaPhone,
    this.nom,
    this.pseudo,
    this.avatarUrl,
    this.statusMsg,
    this.idPays,
  });

  AuthUser copyWith({
    String? nom,
    String? pseudo,
    String? avatarUrl,
    String? statusMsg,
    int? idPays,
  }) => AuthUser(
        id: id,
        email: email,
        alanyaPhone: alanyaPhone,
        nom: nom ?? this.nom,
        pseudo: pseudo ?? this.pseudo,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        statusMsg: statusMsg ?? this.statusMsg,
        idPays: idPays ?? this.idPays,
      );

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json["id"] as String,
        email: json["email"] as String,
        alanyaPhone: json["alanyaPhone"] as String,
        nom: json["nom"] as String?,
        pseudo: json["pseudo"] as String?,
        avatarUrl: json["avatarUrl"] as String?,
        statusMsg: json["statusMsg"] as String?,
        idPays: json["idPays"] as int?,
      );
}
