import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../theme/app_theme.dart';
import '../../media/media_repository.dart';
import '../status_repository.dart';

/// Convertit un hex (#RRGGBB) en Color opaque.
Color colorFromHex(String hex) {
  final h = hex.replaceFirst("#", "");
  return Color(int.parse("FF$h", radix: 16));
}

/// Composition d'un statut texte sur fond coloré (style WhatsApp).
class CreateStatusScreen extends StatefulWidget {
  const CreateStatusScreen({super.key});

  @override
  State<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends State<CreateStatusScreen> {
  static const _palette = <String>[
    "#C05A3B", // terracotta
    "#2D5A27", // forest
    "#4B3621", // chocolate
    "#B8860B", // ochre
    "#2C3E50",
    "#8E44AD",
    "#16A085",
    "#C0392B",
  ];

  final _textCtrl = TextEditingController();
  int _colorIndex = 0;
  bool _publishing = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      _snack("Écris quelque chose");
      return;
    }
    setState(() => _publishing = true);
    final repo = context.read<StatusRepository>();
    final nav = Navigator.of(context);
    try {
      await repo.createText(text, _palette[_colorIndex]);
      nav.pop(true);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack("Publication impossible");
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _pickAndPublishMedia() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        withData: true,
      );
    } catch (_) {
      _snack("Sélection de média indisponible sur cette plateforme");
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    final mime = file.name.toLowerCase().endsWith('.mov') ||
            file.name.toLowerCase().endsWith('.mp4')
        ? 'video/mp4'
        : 'image/jpeg';

    final isVideo = mime.startsWith('video/');

    setState(() => _publishing = true);
    final media = context.read<MediaRepository>();
    final repo = context.read<StatusRepository>();
    final nav = Navigator.of(context);
    try {
      final uploaded = await media.upload(
        Uint8List.fromList(bytes),
        file.name,
        mime,
      );
      await repo.createMedia(
        uploaded.id,
        isVideo ? 'VIDEO' : 'IMAGE',
      );
      nav.pop(true);
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack("Publication du média impossible");
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final bg = colorFromHex(_palette[_colorIndex]);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Nouveau statut",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: "Publier une photo ou vidéo",
            icon: const Icon(Icons.photo_camera_rounded),
            onPressed: _publishing ? null : _pickAndPublishMedia,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: TextField(
                  controller: _textCtrl,
                  maxLength: 700,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  cursorColor: Colors.white,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    counterStyle: const TextStyle(color: Colors.white70),
                    hintText: "Quoi de neuf ?",
                    hintStyle: const TextStyle(color: Colors.white60, fontSize: 28, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _palette.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setState(() => _colorIndex = i),
                        child: Container(
                          width: 40,
                          decoration: BoxDecoration(
                            color: colorFromHex(_palette[i]),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: i == _colorIndex ? Colors.white : Colors.white24,
                              width: i == _colorIndex ? 4 : 1,
                            ),
                            boxShadow: i == _colorIndex 
                              ? [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))]
                              : [],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: bg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: _publishing ? null : _publish,
                      child: _publishing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.terracotta),
                            )
                          : const Text(
                              "Publier",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
