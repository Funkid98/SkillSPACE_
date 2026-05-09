import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
// Conditional import: dart:html on web, no-op stub on mobile.
import '../datasources/google_auth_web.dart'
    if (dart.library.io) '../datasources/google_auth_stub.dart';

/// Public module-level singleton — GoogleSignIn must only be instantiated ONCE.
/// Multiple instantiations cause google.accounts.id.initialize() to fire
/// repeatedly and break FedCM / One-Tap on web.
final sharedGoogleSignIn = GoogleSignIn(
  clientId:
      '1028943448620-vrcc3vji772h8uhenve1uht69i51qvij.apps.googleusercontent.com',
  scopes: ['email', 'openid'],
);


class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({ApiClient? apiClient, GoogleSignIn? googleSignIn})
      : _apiClient = apiClient ?? ApiClient(),
        // Always falls back to the module-level singleton — never creates a new instance.
        _googleSignIn = googleSignIn ?? sharedGoogleSignIn;


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
      if (data['requiresVerification'] == true) {
        throw NeedsVerificationException(
            data['email'] ?? email, data['message'] ?? 'Vérification requise');
      }
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

  @override
  Future<UserModel> verifySignup({
    required String email,
    required String otp,
    String? role,
  }) async {
    final isRecruiter = role == 'recruteur' || role == 'recruiter';
    final isFormateur = role == 'formateur' || role == 'trainer';

    final String endpoint;
    if (isRecruiter) {
      endpoint = '/recruiter/verify-signup';
    } else if (isFormateur) {
      endpoint = '/api/formateur/verify-signup';
    } else {
      endpoint = '/api/auth/verify-signup';
    }

    final response = await _apiClient.post(endpoint, {
      'email': email,
      'otp': otp,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final user = isRecruiter
          ? _mapRecruiterToUserModel(data)
          : UserModel.fromJson(data['user']);
      await _saveAuthData(data['token'], user);
      return user;
    } else {
      String errorMessage = 'Code de vérification invalide';
      if (data is Map) {
        errorMessage = data['message'] ?? data['error'] ?? errorMessage;
      } else if (data is String) {
        errorMessage = data;
      }
      throw Exception(errorMessage);
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
    } else if ((response.statusCode == 403 || response.statusCode == 401) && 
               data['requiresVerification'] == true) {
      print('Triggering NeedsVerificationException for ${data['email'] ?? email}');
      throw NeedsVerificationException(
          data['email'] ?? email, data['message'] ?? 'Vérification requise');
    } else {
      throw Exception(
          data['message'] ?? data['error'] ?? 'Erreur lors de la connexion');
    }
  }

  @override
  Future<UserModel> signInWithGoogle({String? role}) async {
    // ── WEB ──────────────────────────────────────────────────────────────────
    if (kIsWeb) {
      // Check if we are returning from a Google OAuth redirect.
      // consumeOAuthToken() reads the #access_token fragment and clears the URL.
      final webToken = consumeOAuthToken();
      final webRole = consumePendingRole() ?? role ?? 'candidat';

      if (webToken != null) {
        // We have an access token from the redirect — authenticate with backend.
        final isRecruiter =
            webRole == 'recruteur' || webRole == 'recruiter';
        final endpoint =
            isRecruiter ? '/recruiter/google' : '/api/auth/google';
        final response = await _apiClient
            .post(endpoint, {'accessToken': webToken, 'role': webRole});
        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success'] == true) {
          final user = UserModel.fromJson(data['user']);
          await _saveAuthData(data['token'], user);
          return user;
        }
        throw Exception(
            data['message'] ?? 'Erreur lors de la connexion Google');
      } else {
        // No token yet — redirect the browser to Google OAuth.
        // Google will redirect back to http://localhost:3000 with #access_token.
        startGoogleRedirectFlow(role ?? 'candidat');
        // Throwing this specific string lets the AuthCubit show a loading
        // indicator rather than an error while the redirect is happening.
        throw Exception('google_redirect');
      }
    }

    // ── MOBILE ───────────────────────────────────────────────────────────────
    try {
      GoogleSignInAccount? googleUser;
      try {
        await _googleSignIn.signInSilently();
      } catch (_) {}
      googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception(
            'Connexion Google annulée. Si le problème persiste, essayez de vous connecter via email.');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null && accessToken == null) {
        throw Exception(
            'Token Google introuvable. Vérifiez que localhost est autorisé dans Google Cloud Console.');
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
      final msg = e.toString();
      if (msg.contains('popup_closed') ||
          msg.contains('Operation cancelled') ||
          msg.contains('unknown_reason') ||
          msg.contains('network_error') ||
          msg.contains('NetworkError')) {
        throw Exception('Operation cancelled');
      }
      rethrow;
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

    if (response.statusCode != 200 || (data is Map && data['success'] != true)) {
      String errorMessage = 'Erreur lors de la demande OTP';
      if (data is Map) {
        errorMessage = data['message'] ?? errorMessage;
      } else if (data is String) {
        errorMessage = data;
      }
      throw Exception(errorMessage);
    }
  }

  @override
  Future<void> verifyOtp(String email, String otp) async {
    final response = await _apiClient.post('/api/auth/verify-otp', {
      'email': email,
      'otp': otp,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || (data is Map && data['success'] != true)) {
      String errorMessage = 'Code OTP invalide';
      if (data is Map) {
        errorMessage = data['message'] ?? errorMessage;
      } else if (data is String) {
        errorMessage = data;
      }
      throw Exception(errorMessage);
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

    if (response.statusCode != 200 || (data is Map && data['success'] != true)) {
      String errorMessage = 'Erreur lors de la réinitialisation';
      if (data is Map) {
        errorMessage = data['message'] ?? errorMessage;
      } else if (data is String) {
        errorMessage = data;
      }
      throw Exception(errorMessage);
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
