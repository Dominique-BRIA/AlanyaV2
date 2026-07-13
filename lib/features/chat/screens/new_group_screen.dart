import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../models/contact.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/back_app_bar.dart';
import '../../auth/auth_controller.dart';
import '../../contacts/contacts_repository.dart';
import '../chat_repository.dart';
import 'chat_screen.dart';

/// Création d'un groupe : nom + sélection de contacts du répertoire.
class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final _nameCtrl = TextEditingController();
  List<Contact> _contacts = [];
  final Set<String> _selected = {}; // numéros publics sélectionnés
  bool _loading = true;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    try {
      final list = await context.read<ContactsRepository>().list();
      if (!mounted) return;
      setState(() {
        _contacts = list.where((c) => !c.isBlocked).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      setState(() => _error = "Donne un nom au groupe (2 caractères min.)");
      return;
    }
    if (_selected.isEmpty) {
      setState(() => _error = "Sélectionne au moins un contact");
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    final chat = context.read<ChatRepository>();
    try {
      final convId = await chat.createGroup(name, _selected.toList());
      if (!mounted) return;
      final me = context.read<AuthController>().user;
      final names = <String, String>{
        for (final c in _contacts.where((c) => _selected.contains(c.publicNumber)))
          c.userId: c.displayName,
      };
      if (me != null) names[me.id] = me.pseudo ?? me.publicNumber;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(convId: convId, title: name, isGroup: true, memberNames: names),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Création impossible");
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: backAppBar(context, "Nouveau groupe"),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terracotta))
          : Column(
              children: [
                // Section Nom du Groupe
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nom du groupe",
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.chocolate,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: "ex: Famille, Travail...",
                          prefixIcon: const Icon(Icons.groups_outlined, color: AppColors.terracotta),
                          filled: true,
                          fillColor: AppColors.surface,
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                // Section Sélection Contacts
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sélectionner des contacts",
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_selected.length} sélectionné${_selected.length > 1 ? "s" : ""}",
                          style: const TextStyle(
                            color: AppColors.terracotta,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _contacts.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_search_outlined, size: 64, color: AppColors.outline),
                                const SizedBox(height: 16),
                                Text(
                                  "Aucun contact disponible.\nAjoutez des contacts pour créer un groupe.",
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _contacts.length,
                          itemBuilder: (_, i) {
                            final c = _contacts[i];
                            final checked = _selected.contains(c.publicNumber);
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: checked ? AppColors.terracotta.withOpacity(0.05) : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: checked ? AppColors.terracotta : AppColors.outline,
                                  width: checked ? 1.5 : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: checked ? AppColors.terracotta : AppColors.clay,
                                  child: Text(
                                    c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : "?",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  c.displayName,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(c.publicNumber, style: const TextStyle(fontSize: 12)),
                                trailing: Transform.scale(
                                  scale: 0.9,
                                  child: Checkbox(
                                    value: checked,
                                    activeColor: AppColors.terracotta,
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (v) {
                                      setState(() {
                                        if (v == true) {
                                          _selected.add(c.publicNumber);
                                        } else {
                                          _selected.remove(c.publicNumber);
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Bouton Action Flottant / Fixe
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _creating ? null : _create,
                        icon: _creating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.group_add_rounded),
                        label: const Text("Créer le groupe", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
