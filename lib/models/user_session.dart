class UserSession {
  final String id;
  final String device;
  final String osSystem;
  final String ipAddress;
  final DateTime dateLogin;

  UserSession({
    required this.id,
    required this.device,
    required this.osSystem,
    required this.ipAddress,
    required this.dateLogin,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        id: json["idLogin"] as String,
        device: json["device"] as String? ?? "Inconnu",
        osSystem: json["os_system"] as String? ?? "Inconnu",
        ipAddress: json["ipAdress"] as String? ?? "Inconnue",
        dateLogin: DateTime.parse(json["dateLogin"] as String),
      );
}
