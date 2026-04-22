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
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId:
                  '1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com',
              scopes: ['email', 'openid'],
            );

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
    final isFormateur = role == 'formateur' || role == 'trainer';
    
    final String endpoint;
    if (isRecruiter) {
      endpoint = '/recruiter/register';
    } else if (isFormateur) {
      endpoint = '/api/formateur/register';
    } else {
      endpoint = '/api/auth/register';
    }


    final body = isRecruiter
        ? {
            'email': email,
            'password': password,
            'entreprise': entreprise ?? 'A définir',
            'poste': 'Recruteur', // Default value
          }
        : {
            'firstName': firstName,
            'lastName': lastName,
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
      entreprise: data['entreprise'],
    );
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
    String? role,
  }) async {
    final isRecruiter = role == 'recruteur' || role == 'recruiter';
    final isFormateur = role == 'formateur' || role == 'trainer';
    
    final String endpoint;
    if (isRecruiter) {
      endpoint = '/recruiter/login';
    } else if (isFormateur) {
      endpoint = '/api/formateur/login';
    } else {
      endpoint = '/api/auth/login';
    }


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
  Future<UserModel> signInWithGoogle({String? role}) async {
    try {
      // Force library initialization on web by attempting a silent sign-in first
      try {
        await _googleSignIn.signInSilently();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Connexion Google annulée');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw Exception(
            'Token Google introuvable. Assurez-vous que le SHA-1 est correctement configuré.');
      }

      final isRecruiter = role == 'recruteur' || role == 'recruiter';
      final endpoint = isRecruiter ? '/recruiter/google' : '/api/auth/google';
      final body = {
        'idToken': idToken,
        'accessToken': accessToken,
        'role': role ?? 'candidat'
      };

      final response = await _apiClient.post(endpoint, body);
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
      if (e.toString().contains('popup_closed')) {
        // Do nothing or rethrow something that the Bloc can handle silently
        throw Exception('Operation cancelled');
      }
      throw Exception('Google Sign-In échoué: $e');
    }
  }

  @override
  Future<UserModel> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    bool isRecruiter = false;
    bool isFormateur = false;
    String? userId;

    if (userData != null) {
      final user = UserModel.fromJson(jsonDecode(userData));
      isRecruiter = user.role == 'recruteur' || user.role == 'recruiter';
      isFormateur = user.role == 'formateur' || user.role == 'trainer';
      userId = user.id;
    }

    final endpoint = isRecruiter
        ? '/recruiter/profile'
        : (isFormateur ? '/api/formateur/profile/$userId' : '/candidat/me');

    final response = await _apiClient.get(endpoint);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (isRecruiter) {
        return _mapRecruiterToUserModel(data);
      } else if (isFormateur) {
        // Map Formateur database model to UserModel
        return UserModel(
          id: data['userId'] ?? userId ?? '',
          firstName: data['firstName'] ?? '',
          lastName: data['lastName'] ?? '',
          email: data['email'] ?? '',
          role: 'formateur',
        );
      } else {
        return UserModel.fromJson(data);
      }
    } else {
      throw Exception(data['error'] ??
          data['message'] ??
          'Impossible de récupérer le profil');
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    final response = await _apiClient.put('/candidat/me', updates);
    final data = jsonDecode(response.body);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(data['message'] ?? data['error'] ?? 'Erreur lors de la mise à jour du profil');
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
  Future<void> signInWithGithub({String? role}) async {
    // 1. Open GitHub OAuth URL in the browser
    const clientId = 'Ov23li9VlgIH94DHCcgx';
    const redirectUri = 'http://localhost:5001/api/auth/github/callback';
    const scope = 'user:email';
    const githubAuthUrl =
        'https://github.com/login/oauth/authorize?client_id=$clientId&redirect_uri=$redirectUri&scope=$scope';

    try {
      // Launch the GitHub OAuth page in the browser
      final launched = await launchUrl(
        Uri.parse(githubAuthUrl),
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        throw Exception('Impossible d\'ouvrir le navigateur.');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ouverture du navigateur: $e');
    }
  }

  @override
  Future<UserModel> signInWithGithubCode(String code, {String? role}) async {
    final isRecruiter = role == 'recruteur' || role == 'recruiter';
    final endpoint = isRecruiter ? '/recruiter/github' : '/api/auth/github';
    final body = {'code': code.trim(), 'role': role ?? 'candidat'};

    final response = await _apiClient.post(endpoint, body);
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
