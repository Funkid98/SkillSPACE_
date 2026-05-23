import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/utils/app_toast.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../cubit/profile_cubit.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _isLoading = false;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount({
    String? googleToken,
    String? googleAccessToken,
  }) async {
    final password = _passwordController.text;

    if (googleToken == null && googleAccessToken == null && password.isEmpty) {
      AppToast.showError(context, 'Veuillez entrer votre mot de passe');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<ProfileCubit>().deleteAccount(
            password: password.isNotEmpty ? password : null,
            googleToken: googleToken, // mobile
            googleAccessToken: googleAccessToken, // web
          );

      if (!mounted) return;
      AppToast.showSuccess(context, 'Compte supprimé avec succès');
      context.read<AuthCubit>().logout();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      GoogleSignInAccount? googleUser = await googleSignIn.signInSilently();
      googleUser ??= await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        AppToast.showError(
            context, 'Authentification Google annulée ou échouée');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ✅ FedCM now gives idToken on web too — no more platform split needed
      final String? token = googleAuth.idToken ?? googleAuth.accessToken;

      if (token == null) {
        setState(() => _isLoading = false);
        AppToast.showError(
            context, 'Authentification Google annulée ou échouée');
        return;
      }

      // ✅ Always send as googleToken — backend handles it uniformly
      await _deleteAccount(googleToken: token);
    } catch (e) {
      setState(() => _isLoading = false);
      AppToast.showError(context, 'Erreur Google: $e');
    }
  }

  void _showError(String msg) {
    AppToast.showError(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Supprimer le compte',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child:
                    Center(child: CircularProgressIndicator(color: Colors.red)),
              )
            else ...[
              const Text(
                'Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible et supprimera toutes vos données.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 15),
              const Text('OU',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _verifyWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                          width: 24,
                          height: 24,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.g_mobiledata),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Vérifier avec Google',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
        if (!_isLoading)
          ElevatedButton(
            onPressed: () => _deleteAccount(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
