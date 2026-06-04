import 'package:flutter/material.dart';
import '../../data/profile_api.dart';
import '../../../../core/app_colors.dart';
import '../../../../core/utils/app_toast.dart';

class ChangePasswordDialog extends StatefulWidget {
  final String email;
  final String apiUrl; // e.g. '/api/auth'

  const ChangePasswordDialog({
    super.key,
    required this.email,
    this.apiUrl = '/api/auth',
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  int _step = 0; // 0: sending OTP, 1: enter OTP, 2: enter new password
  bool _isLoading = true;
  String _otp = '';
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final res = await ProfileApi.requestPasswordReset(widget.email);
      if (res['success'] == true || res['message']?.contains('envoyé') == true) {
        setState(() {
          _step = 1;
          _isLoading = false;
        });
      } else {
        _showError(res['message'] ?? 'Erreur lors de l\'envoi du code');
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Erreur de connexion');
      Navigator.pop(context);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 4) {
      _showError('Le code doit contenir 4 chiffres');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final res = await ProfileApi.verifyOtp(widget.email, _otp);
      if (res['success'] == true || res['message']?.contains('vérifié') == true) {
        setState(() {
          _step = 2;
          _isLoading = false;
        });
      } else {
        _showError(res['message'] ?? 'Code invalide ou expiré');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Erreur de connexion');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final pass = _passwordController.text;
    if (pass.length < 6) {
      _showError('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }
    if (pass != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ProfileApi.updatePassword(widget.email, pass);
      if (res['success'] == true || res['message']?.contains('succès') == true) {
        AppToast.showSuccess(context, 'Mot de passe mis à jour avec succès');
        Navigator.pop(context);
      } else {
        _showError(res['message'] ?? 'Erreur lors de la mise à jour');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Erreur de connexion');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    AppToast.showError(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        _step == 0
            ? 'Envoi du code...'
            : _step == 1
                ? 'Vérification'
                : 'Nouveau mot de passe',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.orange)),
              ),
            if (!_isLoading && _step == 1) ...[
              const Text(
                  'Un code de vérification a été envoyé à votre adresse email.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '0000',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  _otp = val;
                  if (val.length == 4) {
                    _verifyOtp();
                  }
                },
              ),
            ],
            if (!_isLoading && _step == 2) ...[
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        if (!_isLoading && _step == 2)
          ElevatedButton(
            onPressed: _resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Mettre à jour',
                style: TextStyle(color: Colors.white)),
          ),
      ],
    );
  }
}
