import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/token_storage.dart';
import '../../../models/status.dart';
import '../../../widgets/auth_network_image.dart';
import '../../../theme/app_theme.dart';
import '../status_repository.dart';
import 'create_status_screen.dart' show colorFromHex;

/// Visionneuse plein écran des statuts d'un utilisateur (tap pour avancer).
class StatusViewerScreen extends StatefulWidget {
  const StatusViewerScreen({super.key, required this.group, required this.isMine});
  final StatusGroup group;
  final bool isMine;

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  int _index = 0;
  String _baseUrl = "";
  String? _token;
  Map<String, bool> _localLikes = {};
  Map<String, int> _localLikeCounts = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _markViewed();
    _initLikes();
  }

  void _initLikes() {
    for (var s in widget.group.statuses) {
      _localLikes[s.id] = s.isLiked;
      _localLikeCounts[s.id] = s.likedBy;
    }
  }

  Future<void> _loadConfig() async {
    _baseUrl = context.read<ApiClient>().baseUrl;
    _token = await context.read<TokenStorage>().accessToken;
    if (mounted) setState(() {});
  }

  String _mediaUrl(String path) {
    return "$_baseUrl$path?token=${_token ?? ''}";
  }

  void _markViewed() {
    if (widget.isMine) return;
    final s = widget.group.statuses[_index];
    if (!s.viewed) {
      context.read<StatusRepository>().markViewed(s.id);
    }
  }

  void _next() {
    if (_index < widget.group.statuses.length - 1) {
      setState(() => _index++);
      _markViewed();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prev() {
    if (_index > 0) setState(() => _index--);
  }

  Future<void> _toggleLike() async {
    final s = widget.group.statuses[_index];
    final currentLike = _localLikes[s.id] ?? s.isLiked;
    final currentCount = _localLikeCounts[s.id] ?? s.likedBy;

    setState(() {
      _localLikes[s.id] = !currentLike;
      _localLikeCounts[s.id] = currentLike ? currentCount - 1 : currentCount + 1;
    });

    try {
      final res = await context.read<StatusRepository>().toggleLike(s.id);
      setState(() {
        _localLikes[s.id] = res["liked"];
        _localLikeCounts[s.id] = res["likedBy"];
      });
    } catch (e) {
      setState(() {
        _localLikes[s.id] = currentLike;
        _localLikeCounts[s.id] = currentCount;
      });
    }
  }

  Future<void> _delete() async {
    final s = widget.group.statuses[_index];
    final repo = context.read<StatusRepository>();
    final nav = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer ce statut ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await repo.delete(s.id);
    } catch (_) {}
    nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.group.statuses[_index];
    final bg = s.bgColor != null ? colorFromHex(s.bgColor!) : Colors.black;
    final isLiked = _localLikes[s.id] ?? s.isLiked;
    final likeCount = _localLikeCounts[s.id] ?? s.likedBy;

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          if (d.localPosition.dx < w / 3) {
            _prev();
          } else {
            _next();
          }
        },
        child: Stack(
          children: [
            // Contenu Principal
            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: _buildContent(s),
                ),
              ),
            ),
            
            // Overlay UI
            SafeArea(
              child: Column(
                children: [
                  // Barre de progression Premium
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: List.generate(widget.group.statuses.length, (i) {
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: i <= _index ? Colors.white : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  
                  // Header Utilisateur
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white24,
                            child: Text(
                              widget.group.displayName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.group.displayName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                _ago(s.createdAt),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        if (widget.isMine)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            onPressed: _delete,
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // Zone d'interaction bas de page (Glassmorphism)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: isLiked ? Colors.redAccent : Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$likeCount",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          if (widget.isMine) ...[
                            const SizedBox(width: 20),
                            Row(
                              children: [
                                const Icon(Icons.visibility, color: Colors.white70, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "${s.viewsCount} vues",
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Status s) {
    if (s.type == "TEXT") {
      return Text(
        s.text ?? "",
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.2,
        ),
      );
    } else if (s.type == "IMAGE" && s.mediaUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _token == null
            ? const CircularProgressIndicator(color: Colors.white)
            : AuthNetworkImage(
                url: "$_baseUrl${s.mediaUrl}",
                token: _token,
                fit: BoxFit.contain,
              ),
      );
    } else if (s.type == "VIDEO" && s.mediaUrl != null) {
      return _videoPlaceholder(s.mediaUrl!);
    } else {
      return const Text(
        "[Média non disponible]",
        style: TextStyle(color: Colors.white70),
      );
    }
  }

  Widget _videoPlaceholder(String mediaUrl) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white10,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.play_circle_fill, size: 80, color: Colors.white70),
        ),
        const SizedBox(height: 16),
        const Text(
          "Vidéo",
          style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return "il y a ${diff.inMinutes} min";
    if (diff.inHours < 24) return "il y a ${diff.inHours} h";
    return "il y a ${diff.inDays} j";
  }
}
