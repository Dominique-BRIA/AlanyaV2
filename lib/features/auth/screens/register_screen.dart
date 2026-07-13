import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/api_client.dart';
import '../../../core/app_snackbar.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/back_app_bar.dart';
import '../auth_repository.dart';
import 'otp_screen.dart';

/// Étape 1 : saisie de l'email pour recevoir le code de confirmation.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  double _opacity = 0.0;
  double _slideOffset = 20.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _slideOffset = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    try {
      await context.read<AuthRepository>().register(email);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OtpScreen(email: email)),
      );
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
      appBar: backAppBar(context, tr(context, 'register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icône d'en-tête stylisée
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _opacity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(0, _slideOffset, 0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.terracotta.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.alternate_email_rounded,
                          size: 64,
                          color: AppColors.terracotta,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Titre et Sous-titre
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1000),
                  opacity: _opacity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(0, _slideOffset, 0),
                    child: Column(
                      children: [
                        Text(
                          tr(context, 'register_question') ?? "Créer un compte",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.chocolate,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tr(context, 'register_hint') ?? "Saisissez votre email pour commencer l'aventure Alanya.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Champ Email Premium
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1200),
                  opacity: _opacity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(0, _slideOffset, 0),
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: tr(context, 'email'),
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                        hintText: "exemple@mail.com",
                      ),
                      validator: (v) {
                        final value = (v ?? "").trim();
                        if (value.isEmpty) return tr(context, 'email_required');
                        if (!value.contains("@") || !value.contains(".")) {
                          return tr(context, 'email_invalid');
                        }
                        return null;
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Bouton Premium
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 1400),
                  opacity: _opacity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1400),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(0, _slideOffset, 0),
                    child: _PremiumButton(
                      text: tr(context, 'receive_code') ?? "Recevoir le code",
                      onPressed: _loading ? null : _submit,
                      loading: _loading,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Lien vers Login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium,
                        children: [
                          TextSpan(text: "Vous avez déjà un compte ? "),
                          TextSpan(
                            text: "Se connecter",
                            style: TextStyle(
                              color: AppColors.terracotta,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                ? constHedge: const SizedBox(
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
