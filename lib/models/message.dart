class MessageMedia {
  final String id;
  final String url; // chemin servi par /api/media/:id
  final String? filename;
  final String mimeType;
  final int? sizeBytes;
  final int? durationMs;

  MessageMedia({
    required this.id,
    required this.url,
    required this.mimeType,
    this.filename,
    this.sizeBytes,
    this.durationMs,
  });

  bool get isImage => mimeType.startsWith("image/");

  factory MessageMedia.fromJson(Map<String, dynamic> j) => MessageMedia(
        id: j["id"] as String,
        url: j["url"] as String,
        filename: j["filename"] as String?,
        mimeType: j["mimeType"] as String,
        sizeBytes: (j["sizeBytes"] as num?)?.toInt(),
        durationMs: (j["durationMs"] as num?)?.toInt(),
      );
}

/// Snapshot d'un message cité (réponse). Permet d'afficher l'aperçu du message
/// original côté UI sans dépendre du chargement local de l'historique.
class ReplyPreview {
  final String id;
  final String senderId;
  final int type;
  final String? content;
  final bool isDeleted;

  ReplyPreview({
    required this.id,
    required this.senderId,
    required this.type,
    this.content,
    this.isDeleted = false,
  });

  factory ReplyPreview.fromJson(Map<String, dynamic> j) => ReplyPreview(
        id: j["id"] as String,
        senderId: j["senderId"] as String,
        type: (j["type"] as num).toInt(),
        content: j["content"] as String?,
        isDeleted: j["isDeleted"] as bool? ?? false,
      );
}

class Message {
  final String id;
  final String convId;
  final String senderId;
  final String? content;
  final int type; // 1: TEXT, 2: IMAGE, 3: AUDIO, 4: VIDEO, 5: FILE
  final int status; // 1: SENT, 2: DELIVERED, 3: READ
  final String? replyToId;
  final ReplyPreview? replyTo; // snapshot du message cité (venant du backend)
  final bool isDeleted; // Vrai si supprimé pour l'utilisateur courant
  final String? mediaUrl;
  final String? mediaName;
  final int? mediaDuration;
  final DateTime sendAt;

  Message({
    required this.id,
    required this.convId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.replyToId,
    required this.isDeleted,
    required this.sendAt,
    this.replyTo,
    this.mediaUrl,
    this.mediaName,
    this.mediaDuration,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j["id"] as String,
        convId: j["convId"] as String,
        senderId: j["senderId"] as String,
        content: j["content"] as String?,
        type: (j["type"] as num).toInt(),
        status: (j["status"] as num).toInt(),
        replyToId: j["replyToId"] as String?,
        replyTo: j["replyTo"] != null
            ? ReplyPreview.fromJson(j["replyTo"] as Map<String, dynamic>)
            : null,
        isDeleted: (j["isDeleted"] as bool?) ?? false,
        mediaUrl: j["mediaUrl"] as String?,
        mediaName: j["mediaName"] as String?,
        mediaDuration: (j["mediaDuration"] as num?)?.toInt(),
        sendAt: DateTime.parse(j["sendAt"] as String),
      );
}
