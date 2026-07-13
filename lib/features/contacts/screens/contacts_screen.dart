import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/app_snackbar.dart';
import '../../../core/contact_cache.dart';
import '../../../models/contact.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/avatar_circle.dart';
import '../../../widgets/back_app_bar.dart';
import '../../../widgets/motif_background.dart';
import '../../chat/chat_repository.dart';
import '../../chat/screens/chat_screen.dart';
import '../../chat/screens/new_group_screen.dart';
import '../contacts_repository.dart';
import 'new_chat_screen.dart';
import 'phone_sync_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact>? _contacts;
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    // 1) Cache local d'abord (offline-first).
    final cached = await ContactCache.getAll();
    if (cached.isNotEmpty && mounted) {
      setState(() {
        _contacts = cached;
        _loading = false;
        _errorMsg = null;
      });
    }

    // 2) Rafraîchit depuis le serveur.
    try {
      final list = await context.read<ContactsRepository>().list();
      if (!mounted) return;
      setState(() {
        _contacts = list;
        _loading = false;
        _errorMsg = null;
      });
      await ContactCache.putAll(list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Ne montre l'erreur que si le cache était vide (aucun contenu à afficher).
        _errorMsg = (_contacts?.isEmpty ?? true)
            ? "Erreur ${e.statusCode} : ${e.message}"
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = (_contacts?.isEmpty ?? true)
            ? "Impossible de charger les contacts.\nVérifie ta connexion."
            : null;
      });
    }
  }

  Future<void> _startChat(Contact c) async {
    final chat = context.read<ChatRepository>();
    try {
      final convId = await chat.createDirect(c.publicNumber);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            convId: convId,
            title: c.displayName,
            avatarUrl: c.avatarUrl,
            otherUserId: c.userId,
            otherPublicNumber: c.publicNumber,
            contactId: c.id,
            isBlocked: c.isBlocked,
          ),
        ),
      );
    } on ApiException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack("Impossible d'ouvrir la discussion");
    }
  }

  Future<void> _toggleBlock(Contact c) async {
    try {
      await context.read<ContactsRepository>().setBlocked(c.id, !c.isBlocked);
      await _load();
    } catch (_) {
      _snack("Action impossible");
    }
  }

  Future<void> _remove(Contact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer le contact ?"),
        content: Text("${c.displayName} sera retiré de ton répertoire."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer")),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<ContactsRepository>().remove(c.id);
      await _load();
    } catch (_) {
      _snack("Suppression impossible");
    }
  }

  void _snack(String m) => showAppSnackBar(m);


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.chocolate,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "Contacts",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.chocolate,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Importer depuis le téléphone",
            icon: const Icon(Icons.contacts_outlined, color: AppColors.textSecondary),
            onPressed: () async {
              final added = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const PhoneSyncScreen()),
              );
              if (added == true) _load();
            },
          ),
          IconButton(
            tooltip: "Actualiser",
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: MotifBackground(
        overlayOpacity: 0.92,
        child: RefreshIndicator(
          onRefresh: _load, 
          color: AppColors.terracotta,
          child: _body(theme),
        ),
      ),
    );
  }

  Widget _body(ThemeData theme) {
    if (_contacts == null && _loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
    }

    if (_errorMsg != null) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.outline),
                  const SizedBox(height: 16),
                  Text(
                    _errorMsg!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Réessayer"),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final contacts = _contacts ?? [];
    
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _buildActionSection(theme),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                "Mon Répertoire",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.chocolate,
                ),
              ),
            ),
            if (contacts.isEmpty)
              _buildEmptyState(theme)
            else
              ...contacts.map((c) => _tile(c, theme)),
          ],
        ),
        if (_loading)
          const Positioned(
            top: 0, left: 0, right: 0,
            child: LinearProgressIndicator(color: AppColors.terracotta, backgroundColor: Colors.transparent),
          ),
      ],
    );
  }

  Widget _buildActionSection(ThemeData theme) {
    return Column(
      children: [
        _actionTile(
          theme,
          icon: Icons.group_add_rounded,
          color: AppColors.forest,
          title: "Nouveau groupe",
          subtitle: "Réunir vos contacts",
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NewGroupScreen()),
            );
            _load();
          },
        ),
        const SizedBox(height: 12),
        _actionTile(
          theme,
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.terracotta,
          title: "Ajouter un contact",
          subtitle: "Rechercher par numéro Alanya",
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NewChatScreen()),
            );
            _load();
          },
        ),
      ],
    );
  }

  Widget _actionTile(ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outline.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded, size: 64, color: AppColors.outline),
          const SizedBox(height: 16),
          Text(
            "Aucun contact pour l'instant",
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            "Commencez par ajouter des amis\nvia leur numéro Alanya.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _tile(Contact c, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: AvatarCircle(
          name: c.displayName,
          avatarUrl: c.avatarUrl,
          radius: 24,
          backgroundColor: c.isBlocked ? Colors.grey : AppColors.clay,
        ),
        title: Text(c.displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          "${c.publicNumber}${c.isBlocked ? " · Bloqué" : ""}",
          style: theme.textTheme.bodySmall,
        ),
        onTap: c.isBlocked ? null : () => _startChat(c),
        trailing: PopupMenuButton<String>(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (v) {
            if (v == "chat") _startChat(c);
            if (v == "block") _toggleBlock(c);
            if (v == "delete") _remove(c);
          },
          itemBuilder: (_) => [
            if (!c.isBlocked)
              const PopupMenuItem(value: "chat", child: Row(
                children: [Icon(Icons.chat_bubble_outline, size: 20), SizedBox(width: 8), Text("Discuter")],
              )),
            PopupMenuItem(value: "block", child: Row(
              children: [Icon(c.isBlocked ? Icons.lock_open : Icons.block, size: 20), SizedBox(width: 8), Text(c.isBlocked ? "Débloquer" : "Bloquer")],
            )),
            const PopupMenuItem(value: "delete", child: Row(
              children: [Icon(Icons.delete_outline, size: 20, color: Colors.red), SizedBox(width: 8), Text("Supprimer", style: TextStyle(color: Colors.red))],
            )),
          ],
        ),
      ),
    );
  }
