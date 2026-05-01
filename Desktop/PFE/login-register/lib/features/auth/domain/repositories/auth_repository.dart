import '../../data/models/user_model.dart';

class NeedsVerificationException implements Exception {
  final String email;
  final String message;
  NeedsVerificationException(this.email, this.message);
  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? role,
    String? entreprise,
  });
  
  Future<UserModel> verifySignup({
    required String email,
    required String otp,
    String? role,
  });

  Future<UserModel> login({
    required String email,
    required String password,
    String? role,
  });

  Future<UserModel> signInWithGoogle({String? role});

  Future<void> signInWithGithub({String? role});
  
  Future<UserModel> signInWithGithubCode(String code, {String? role});

  Future<void> forgotPassword(String email);

  Future<void> verifyOtp(String email, String otp);

  Future<void> resetPassword(String email, String otp, String newPassword);

  Future<UserModel> getProfile();
  Future<void> updateProfile(Map<String, dynamic> updates);

  Future<Map<String, dynamic>> uploadCv(String filePath);

  Future<void> logout();

  Future<bool> isLoggedIn();
}
