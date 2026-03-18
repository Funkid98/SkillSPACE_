import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? role,
    String? entreprise,
  });

  Future<UserModel> login({
    required String email,
    required String password,
    String? role,
  });

  Future<UserModel> signInWithGoogle();

  Future<UserModel> signInWithGithub();

  Future<void> forgotPassword(String email);

  Future<void> verifyOtp(String email, String otp);

  Future<void> resetPassword(String email, String otp, String newPassword);

  Future<UserModel> getProfile();

  Future<Map<String, dynamic>> uploadCv(String filePath);

  Future<void> logout();

  Future<bool> isLoggedIn();
}
