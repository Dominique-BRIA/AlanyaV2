import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/api_client.dart';
import '../../../core/app_snackbar.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/back_app_bar.dart';
import '../auth_controller.dart';
import '../auth_repository.dart';
import 'countries_repository.dart';

/// Étape 3 : choix du nom, pseudo, pays + mot de passe. 
/// C'est ici que l'utilisateur forge son identité Alanya.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.setupToken, required this.publicNumber});
  final String setupToken;
  final String publicNumber;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _pseudoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  int? _selectedCountryId;
  List<Country> _countries = [];
  bool _loading = false;
  bool _obscure = true;
  double _opacity = 0.0;
  double _slideOffset = 20.0;

  @override
  void initState() {
    super.initState();
    _loadCountries();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _slideOffset = 0.0;
        });
      }
    });
  }

  Future<void> _loadCountries() async {
    try {
      final repo = CountryRepository(context.read<ApiClient>());
      final list = await repo.fetchCountries();
      setState(() {
        _countries = list;
        if (list.isNotEmpty) _selectedCountryId = list[0].id;
      });
    } catch (e) {
      debugPrint("Error loading countries: $e");
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _pseudoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final session = await context.read<AuthRepository>().setup(
            setupToken: widget.setupToken,
            pseudo: _pseudoCtrl.text.trim(),
            nom: _nomCtrl.text.trim(),
            password: _passwordCtrl.text,
            idPays: _selectedCountryId,
          );
      if (!mounted) return;
      await context.read<AuthController>().completeSetup(session);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      showAppSnackBar(e.message);
    } catch (_) {
      showAppSnackBar(tr(context, 'server_unreachable'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: backAppBar(context, tr(context, 'profile_setup')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // Section 1 : L'Identité Alanya (La Célébration)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _opacity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(0, _slideOffset, 0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: AppColors.outline, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.chocolate.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            tr(context, 'your_alanya_id') ?? "Votre identité Alanya",
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.publicNumber,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.chocolate,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr(context, 'id_description') ?? "Ce numéro unique est désormais votre clé d'accès à la communauté.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Section 2 : Informations Personnelles
                _buildSectionTitle(context, tr(context, 'personal_info') ?? "Informations personnelles"),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: _opacity,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nomCtrl,
                        decoration: InputDecoration(
                          labelText: tr(context, 'full_name'),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v ?? "").trim().isEmpty ? "Le nom est requis" : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pseudoCtrl,
                        decoration: InputDecoration(
                          labelText: tr(//- Translation handled by l10n
                            context, 'pseudo'),
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                        ),
                        validator: (v) => (v ?? "").trim().length < 2 ? "Pseudo trop court" : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedCountryId,
                        items: _countries.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text("${c.prefix} ${c.libelle}"),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedCountryId = v),
                        decoration: InputDecoration(
                          labelText: tr(context, 'country'),
                          prefixIcon: const Icon(Icons.public_rounded),
                        ),
                        validator: (v) => v == null ? "Veuillez choisir un pays" : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Section 3 : Sécurité
                _buildSectionTitle(context, tr(context, 'security') ?? "Sécurité"),
                const SizedBox(height: 16),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1200),
                  opacity: _opacity,
                  child: TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: tr(context, 'password'),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v ?? "").length < 8 ? tr(context, 'password_min_8') : null,
                  ),
                ),

                const SizedBox(height: 48),

                // Bouton Final
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1400),
                  opacity: _opacity,
                  child: _PremiumButton(
                    text: tr(context, 'finish') ?? "Terminer l'inscription",
                    onPressed: _loading ? null : _submit,
                    loading: _loading,
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.chocolate,
        ),
      ),
    );
  }
}

/// Bouton Premium réutilisable avec effet de scale et gradient
class _PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  const _PremiumButton({
    required this.text, 
    required this.onPressed, 
    this.loading = false
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        if (widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppColors.terracotta,
                AppColors.terracotta.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.terracotta.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
