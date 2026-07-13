import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import '../../../l10n/app_localizations.dart';

import '../../../core/api_client.dart';
import '../../../core/app_snackbar.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/back_app_bar.dart';
import '../auth_repository.dart';
import 'setup_screen.dart';

/// Étape 2 : saisie du code OTP à 6 chiffres reçu par email.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email});
  final String email;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _code = "";
  bool _loading = false;
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimer = 60;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
          Future.delayed(const Duration(seconds: 1), (_) => _startResendTimer());
        } else {
          _canResend = true;
        }
      });
    });
  }

  Future<void> _verify() async {
    if (_code.length != 6) {
      showAppSnackBar(tr(context, 'enter_6_digits'));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await context.read<AuthRepository>().verify(widget.email, _code);
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SetupScreen(
            setupToken: result.setupToken,
            publicNumber: result.publicNumber,
          ),
        ),
      );
    } on ApiException catch (e) {
      showAppSnackBar(e.message);
    } catch (_) {
      showAppSnackBar(tr(context, 'server_unreachable'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    try {
      await context.read<AuthRepository>().register(widget.email);
      showAppSnackBar(tr(context, 'new_code_sent'));
      _startResendTimer();
    } on ApiException catch (e) {
      showAppSnackBar(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: backAppBar(context, tr(context, 'confirmation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // En-tête avec icône
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.terracotta.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mark_email_read_rounded,
                    size: 56,
                    color: AppColors.terracotta,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                tr(context, 'enter_code') ?? "Vérifiez votre email",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.chocolate,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Un code à 6 chiffres a été envoyé à ${widget.email}.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // Champ OTP Premium
              Center(
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  onChanged: (v) => _code = v,
                  onCompleted: (v) {
                    _code = v;
                    _verify();
                  },
                  // Style des cases
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(16),
                    fieldHeight: 60,
                    fieldWidth: 50,
                    activeColor: AppColors.terracotta,
                    selectedColor: AppColors.terracotta,
                    inactiveColor: AppColors.outline,
                    activeFillColor: Colors.white,
                    selectedFillColor: Colors.white,
                    inactiveFillColor: AppColors.surface,
                  ),
                  enableActiveFill: true,
                ),
              ),

              constHedge: const SizedBox(height: 32),

              // Bouton de validation Premium
              _PremiumButton(
                text: tr(context, 'verify') ?? "Vérifier le code",
                onPressed: _loading ? null : _verify,
                loading: _loading,
              ),

              const SizedBox(height: 24),

              // Section renvoi de code avec timer
              Center(
                child: TextButton(
                  onPressed: _loading || !_canResend ? null : _resend,
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: _canResend 
                            ? "Vous n'avez pas reçu le code ? " 
                            : "Renvoyer dans ${_resendTimer}s... ",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        if (_canResend)
                          TextSpan(
                            text: "Renvoyer",
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
