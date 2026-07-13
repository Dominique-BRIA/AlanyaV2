/// Résultat d'une recherche d'utilisateur par numéro Alanya.
class UserSearchResult {
  final String id;
  final String alanyaPhone;
  final String? pseudo;
  final String? avatarUrl;
  final String? statusMsg;
  final bool alreadyContact;

  UserSearchResult({
    required this.id,
    required this.alanyaPhone,
    required this.pseudo,
    required this.avatarUrl,
    required this.statusMsg,
    required this.alreadyContact,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> j) => UserSearchResult(
        id: j["id"] as String,
        alanyaPhone: j["alanyaPhone"] as String,
        pseudo: j["pseudo"] as String?,
        avatarUrl: j["avatarUrl"] as String?,
        statusMsg: j["statusMsg"] as String?,
        alreadyContact: (j["alreadyContact"] as bool?) ?? false,
      );
}

/// Un contact du répertoire.
class Contact {
  final String id;
  final String? alias;
  final bool isBlocked;
  final String userId;
  final String alanyaPhone;
  final String? pseudo;
  final String? avatarUrl;

  Contact({
    required this.id,
    required this.alias,
    required this.isBlocked,
    required this.userId,
    required this.alanyaPhone,
    required this.pseudo,
    required this.avatarUrl,
  });

  String get displayName => alias ?? pseudo ?? alanyaPhone;

  factory Contact.fromJson(Map<String, dynamic> j) {
    final user = j["user"] as Map<String, dynamic>;
    return Contact(
      id: j["id"] as String,
      alias: j["alias"] as String?,
      isBlocked: (j["isBlocked"] as bool?) ?? false,
      userId: user["id"] as String,
      alanyaPhone: user["alanyaPhone"] as String,
      pseudo: user["pseudo"] as String?,
      avatarUrl: user["avatarUrl"] as String?,
    );
  }
}
