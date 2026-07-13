import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../auth/auth_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Contrôleurs pour les animations d'entrée
  double _opacity = 0.0;
  double _slideOffset = 30.0;

  @override
  void initState() {
    super.initState();
    // Lancement de l'animation après un court délai pour un effet fluide
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _slideOffset = 0.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: Stack(
        children: [
          // 1. Background Decor (Subtile touche de design)
          Positioned(
            top: -100,
            right: -100,
            child: CircleAvatar(
              radius: 150,
              backgroundColor: AppColors.terracotta.withValues(alpha: 0.05),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: AppColors.forest.withValues(alpha: 0.05),
            ),
          ),

          // 2. Contenu Principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Image Hero avec animation
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: _opacity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(0, _slideOffset, 0),
                      child: Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.chocolate.withValues(alpha: 0.1),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/images/logo.png', // Assure-toi que le chemin est correct
                            fit: BoxFit.cover,
                            // On ajoute un léger dégradé par-dessus l'image pour l'intégration
                            color: AppColors.terracotta.withValues(alpha: 0.05),
                            colorBlendMode: BlendMode.softLight,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Texte de Bienvenue
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
                            tr(context, 'welcome_title') ?? "Bienvenue sur Alanya",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.chocolate,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr(context, 'welcome_subtitle') ?? "L'expérience de communication moderne, inspirée par nos racines.",
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

                  const Spacer(flex: 2),

                  // Bouton d'action Premium
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 1200),
                    opacity: _opacity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds up: 1200),
                      curve: Curves.easeOutCubic,
                      transform: Matrix4.translationValues(0, _slideOffset, 0),
                      child: _PremiumButton(
                        text: tr(context, 'get_started') ?? "Commencer l'aventure",
                        onPressed: () {
                          // Logique de navigation vers Register ou Login
                          // Pour l'exemple, on redirige vers Register
                          Navigator.of(context).pushReplacementNamed('/register');
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Lien vers le Login
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
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
                  constHedge: const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton Premium avec animation de scale et ripple subtil
class _PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _PremiumButton({required this.text, required this.onPressed});

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
        widget.onPressed();
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
            child: Text(
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
