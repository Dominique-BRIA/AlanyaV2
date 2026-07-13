class LastMessage {
  final String id;
  final String? content;
  final int type;
  final String senderId;
  final DateTime createdAt;

  LastMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.senderId,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> j) => LastMessage(
        id: j["id"] as String,
        content: j["content"] as String?,
        type: (j["type"] as num).toInt(),
        senderId: j["senderId"] as String,
        createdAt: DateTime.parse(j["createdAt"] as String),
      );
}

class ConvMember {
  final String id;
  final String? pseudo;
  final String alanyaPhone;

  ConvMember({required this.id, required this.pseudo, required this.alanyaPhone});

  String get displayName => pseudo ?? alanyaPhone;

  factory ConvMember.fromJson(Map<String, dynamic> j) => ConvMember(
        id: j["id"] as String,
        pseudo: j["pseudo"] as String?,
        alanyaPhone: j["alanyaPhone"] as String,
      );
}

class Conversation {
  final String id;
  final bool isGroup;
  final String? title;
  final String? avatarUrl;
  final List<ConvMember> members;
  final LastMessage? lastMessage;
  final int unread;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.isGroup,
    required this.title,
    required this.avatarUrl,
    required this.members,
    required this.lastMessage,
    required this.unread,
    required this.updatedAt,
  });

  Map<String, String> get memberNames => {
        for (final m in members) m.id: m.displayName,
      };

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j["id"] as String,
        isGroup: j["isGroup"] as bool,
        title: j["title"] as String?,
        avatarUrl: j["avatarUrl"] as String?,
        members: ((j["members"] as List?) ?? [])
            .map((m) => ConvMember.fromJson(m as Map<String, dynamic>))
            .toList(),
        lastMessage: j["lastMessage"] == null
            ? null
            : LastMessage.fromJson(j["lastMessage"] as Map<String, dynamic>),
        unread: (j["unread"] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.parse(j["updatedAt"] as String),
      );
}
