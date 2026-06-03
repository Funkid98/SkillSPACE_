import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';

import '../cubits/trainer_cubit.dart';

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

  Future<void> _deleteAccount({String? googleToken}) async {
    final password = _passwordController.text.trim();
    if (googleToken == null && password.isEmpty) {
      _showError('Veuillez entrer votre mot de passe');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userId = context.read<AuthCubit>().state.loggedInUser?['id'] ?? '';
      if (userId.isEmpty) throw Exception('User ID introuvable');

      await context.read<TrainerCubit>().deleteAccount(
            userId,
            password: password.isNotEmpty ? password : null,
            googleToken: googleToken,
          );

      if (!mounted) return;
      Fluttertoast.showToast(
          msg: 'Compte supprimé avec succès', backgroundColor: Colors.green);

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
        clientId:
            '1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com',
        scopes: ['email', 'openid'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        _showError('Authentification Google annulée');
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        setState(() => _isLoading = false);
        _showError('Impossible d\'obtenir le token Google');
        return;
      }
      await _deleteAccount(
          googleToken: googleAuth.idToken ?? googleAuth.accessToken);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur Google: $e');
    }
  }

  void _showError(String msg) {
    Fluttertoast.showToast(msg: msg, backgroundColor: Colors.red);
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
                'Êtes-vous sûr de vouloir supprimer définitivement votre compte ? '
                'Cette action est irréversible et supprimera toutes vos données.',
                style: TextStyle(fontSize: 15),
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
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 14),
              const Text('OU',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _verifyWithGoogle,
                icon: Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                  width: 22,
                ),
                label: const Text('Vérifier avec Google'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
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
