import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pfe/features/auth/presentation/cubit/auth_cubit.dart';

import '../cubits/recruiter_profile_cubit.dart';

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
    final password = _passwordController.text;
    if (googleToken == null && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez entrer votre mot de passe'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<RecruiterProfileCubit>().deleteAccount(
            password: password.isNotEmpty ? password : null,
            googleToken: googleToken,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Compte supprimé avec succès'),
          backgroundColor: Colors.green));

      // Log out the user and navigate to landing page
      context.read<AuthCubit>().logout();
      Navigator.pop(context); // Close the dialog
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceAll('Exception: ', ''));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        _showError('Authentification Google annulée');
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null) {
        setState(() => _isLoading = false);
        _showError('Impossible d\'obtenir le token Google');
        return;
      }
      await _deleteAccount(googleToken: googleAuth.idToken);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur Google: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: _verifyWithGoogle,
                icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                    width: 24),
                label: const Text('Vérifier avec Google'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
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
