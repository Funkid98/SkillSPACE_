import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({ApiClient? apiClient, GoogleSignIn? googleSignIn})
      : _apiClient = apiClient ?? ApiClient(),
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: ['email', 'openid']);

  // Helper method to save token and user data
  Future<void> _saveAuthData(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? role,
    String? entreprise,
  }) async {
    final isRecruiter = role == 'recruteur' || role == 'recruiter';
    final endpoint = isRecruiter ? '/recruiter/register' : '/candidat/register';

    final body = isRecruiter
        ? {
            'email': email,
            'password': password,
            'entreprise': entreprise ?? 'A définir',
            'poste': 'Recruteur', // Default value
          }
        : {
            'prenom': firstName,
            'nom': lastName,
            'email': email,
            'password': password,
            'role': role ?? 'candidat',
          };

    final response = await _apiClient.post(endpoint, body);

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      final user = isRecruiter
          ? _mapRecruiterToUserModel(data)
          : UserModel.fromJson(data['user']);
      await _saveAuthData(data['token'], user);
      return user;
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Erreur lors de l\'inscription');
    }
  }

  UserModel _mapRecruiterToUserModel(Map<String, dynamic> data) {
    // Backend returns { _id, email, entreprise, poste, role, token }
    return UserModel(
      id: data['_id'],
      firstName: data['prenom'] ?? '',
      lastName: data['nom'] ?? '',
      email: data['email'],
      role: data['role'],
    );
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    String? role,
  }) async {
    final isRecruiter = role == 'recruteur' || role == 'recruiter';
    final endpoint = isRecruiter ? '/recruiter/login' : '/candidat/login';

    final response = await _apiClient.post(endpoint, {
      'email': email,
      'password': password,
      if (!isRecruiter) 'role': role,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final user = isRecruiter
          ? _mapRecruiterToUserModel(data)
          : UserModel.fromJson(data['user']);
      await _saveAuthData(data['token'], user);
      return user;
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Erreur lors de la connexion');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Connexion Google annulée');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
            'Token Google introuvable. Assurez-vous que le SHA-1 est configuré sur Firebase.');
      }

      final response = await _apiClient.signInWithGoogle(idToken);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = UserModel.fromJson(data['user']);
        await _saveAuthData(data['token'], user);
        return user;
      } else {
        throw Exception(
            data['message'] ?? 'Erreur lors de la connexion Google');
      }
    } catch (e) {
      // Catch all and surface the error message
      throw Exception('Google Sign-In échoué: $e');
    }
  }

  @override
  Future<UserModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    bool isRecruiter = false;
    if (userData != null) {
      final user = UserModel.fromJson(jsonDecode(userData));
      isRecruiter = user.role == 'recruteur' || user.role == 'recruiter';
    }

    final endpoint = isRecruiter ? '/recruiter/profile' : '/candidat/me';
    final response = await _apiClient.get(endpoint);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return isRecruiter
          ? _mapRecruiterToUserModel(data)
          : UserModel.fromJson(data);
    } else {
      throw Exception(data['error'] ??
          data['message'] ??
          'Impossible de récupérer le profil');
    }
  }

  @override
  Future<Map<String, dynamic>> uploadCv(String filePath) async {
    final response = await _apiClient.uploadFile(
      '/cv/upload',
      [], // Placeholder for bytes
      filePath.split('/').last,
      fieldName: 'cv',
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data']; // Returns extracted CV data
    } else {
      throw Exception(data['error'] ?? 'Échec de l\'envoi du CV');
    }
  }

  @override
  Future<UserModel> signInWithGithub() async {
    // 1. Open GitHub OAuth URL in the browser
    const clientId = 'Ov23li2wNjAMnAFvBnyK';
    const redirectUri = 'http://127.0.0.1:5001/api/auth/github/callback';
    const scope = 'user:email';
    const githubAuthUrl =
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&scope=$scope';

    try {
      // Launch the GitHub OAuth page in the browser
      await launchUrl(
        Uri.parse(githubAuthUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      throw Exception('Impossible d\'ouvrir le navigateur: $e');
    }
    // 2. Wait for the server to receive the callback and redirect with the code
    // The app never gets the code directly via redirect on pure Flutter.
    // So we poll the backend for a success signal, or ask the user to enter the code.
    // A simpler approach for local testing: open a dialog for code entry.
    throw Exception('GITHUB_OPEN_BROWSER');
  }

  Future<UserModel> signInWithGithubCode(String code) async {
    final response = await _apiClient.signInWithGithub(code);
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final user = UserModel.fromJson(data['user']);
      await _saveAuthData(data['token'], user);
      return user;
    } else {
      throw Exception(data['message'] ?? 'Erreur lors de la connexion GitHub');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    final response = await _apiClient.post('/api/auth/forgot-password', {
      'email': email,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur lors de la demande OTP');
    }
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    final response = await _apiClient.post('/api/auth/verify-otp', {
      'email': email,
      'otp': otp,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Code OTP invalide');
    }
  }

  @override
  Future<void> resetPassword(
      String email, String otp, String newPassword) async {
    final response = await _apiClient.post('/api/auth/reset-password', {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Erreur lors de la réinitialisation');
    }
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
    await prefs.remove('active_tab_index');
  }

  @override
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('jwt_token');
  }
}
