import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/api_client.dart';
import '../../../core/app_snackbar.dart';
import '../../../models/contact.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/back_app_bar.dart';
import '../../chat/chat_repository.dart';
import '../../chat/screens/chat_screen.dart';
import '../contacts_repository.dart';

/// Recherche par numéro Alanya (8 chiffres) puis ajout au répertoire.
class AddContactScreen extends StatefulWidget {

  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _numberCtrl = TextEditingController();
  final _aliasCtrl = TextEditingController();
  bool _loading = false;
  UserSearchResult? _result;
  String? _error;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _aliasCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final number = _numberCtrl.text.trim();
    final isValid = number.length == 8 && RegExp(r'^\d{8}$').hasMatch(number);
    if (!isValid) {
      setState(() => _error = "Entre un numéro Alanya valide (8 chiffres)");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await context.read<ContactsRepository>().searchByNumber(number);
      if (!mounted) return;
      setState(() => _result = res);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.statusCode == 404
          ? "Aucun utilisateur avec ce numéro Alanya"
          : "Erreur ${e.statusCode} : ${e.message}");
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = "Recherche impossible. Vérifie ta connexion.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(UserSearchResult user) async {
    if (user.alreadyContact) {
      showAppSnackBar("${user.pseudo ?? user.publicNumber} est déjà dans tes contacts");
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final alias = _aliasCtrl.text.trim();
      await context.read<ContactsRepository>().add(
            user.publicNumber,
            alias: alias.isEmpty ? null : alias,
          );
      if (!mounted) return;
      showAppSnackBar("Contact ajouté ✓");
      Navigator.of(context).pop(true); // signale que la liste doit se recharger
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      showAppSnackBar(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Impossible d'ajouter ce contact. Vérifie ta connexion.");
      showAppSnackBar("Erreur inattendue");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addAndChat(UserSearchResult user) async {
    setState(() => _loading = true);
    try {
      final contacts = context.read<ContactsRepository>();
      final alias = _aliasCtrl.text.trim();
      if (!user.alreadyContact) {
        await contacts.add(user.publicNumber, alias: alias.isEmpty ? null : alias);
      }
      final convId = await context.read<ChatRepository>().createDirect(user.publicNumber);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            convId: convId,
            title: alias.isNotEmpty ? alias : (user.pseudo ?? user.publicNumber),
            avatarUrl: user.avatarUrl,
            otherUserId: user.id,
            otherPublicNumber: user.publicNumber,
            otherStatusMsg: user.statusMsg,
          ),
        ),
      );
    } on ApiException catch (e) {
      showAppSnackBar(e.message);
    } catch (_) {
      showAppSnackBar("Impossible d'ouvrir la discussion");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.chocolate,
        elevation: 0,
        title: Text(
          "Ajouter un contact",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Introduction
              Row(
                children: [
                  const Icon(Icons.person_add_alt_1, color: AppColors.terracotta, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Trouvez un utilisateur",
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Saisissez le numéro public Alanya (8 chiffres) pour ajouter un ami à votre répertoire.",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              // Champ Numéro
              TextField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                maxLength: 8,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: "Numéro Alanya",
                  hintText: "ex: 12345678",
                  counterText: "",
                  prefixIcon: const Icon(Icons.tag, color: AppColors.terracotta),
                ),
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _search,
                  icon: _loading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search),
                  label: Text(_loading ? "Recherche..." : "Rechercher"),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
              ],
              
              if (_result != null) ...[
                const SizedBox(height: 32),
                _buildResultCard(theme, _result!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme, UserSearchResult user) {
    final name = user.pseudo ?? "Utilisateur ${user.publicNumber}";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: AppColors.chocolate.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AvatarCircle(
                name: name,
                radius: 28,
                backgroundColor: AppColors.clay,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text("Numéro : ${user.publicNumber}", style: theme.textTheme.bodySmall),
                    if (user.alreadyContact)
                      Text(
                        "Déjà dans vos contacts",
                        style: const TextStyle(color: AppColors.forest, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!user.alreadyContact) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _aliasCtrl,
              decoration: InputDecoration(
                labelText: "Nom personnalisé",
                hintText: "ex: Marc Bureau",
                prefixIcon: const Icon(Icons.edit_note, color: AppColors.terracotta),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : () => user.alreadyContact ? _addAndChat(user) : _add(user),
              child: Text(user.alreadyContact ? "Ouvrir la discussion" : "Ajouter au répertoire", style: const TextStyle(fontSize: 16)),
            ),
          ),
          if (!user.alreadyContact) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _loading ? null : () => _addAndChat(user),
                child: const Text("Ajouter et discuter"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(UserSearchResult user) {
    return _buildResultCard(Theme.of(context), user);
  }
