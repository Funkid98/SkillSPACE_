import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/google_auth_web.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(const AuthState());

  void switchTab(AuthTab tab) =>
      emit(state.copyWith(tab: tab, clearError: true));
  void selectRole(UserRole role) => emit(state.copyWith(role: role));
  void togglePassword() {
    emit(state.copyWith(passwordVisible: !state.passwordVisible));
  }

  void toggleStaySignedIn() {
    emit(state.copyWith(staySignedIn: !state.staySignedIn));
  }

  void clearError() => emit(state.copyWith(clearError: true));
  void clearSuccess() => emit(state.copyWith(isSuccess: false));
  void cancelVerification() =>
      emit(state.copyWith(awaitingVerification: false, clearError: true));

  void restoreSession(Map<String, dynamic> user) {
    UserRole userRole = UserRole.candidat;
    if (user['role'] == 'recruteur' || user['role'] == 'recruiter') {
      userRole = UserRole.recruteur;
    } else if (user['role'] == 'formateur' || user['role'] == 'trainer') {
      userRole = UserRole.formateur;
    }
    emit(state.copyWith(
      isSuccess: true,
      role: userRole,
      loggedInUser: user,
    ));
  }

  Future<void> checkAuthStatus() async {
    // On web, check if we're returning from a Google OAuth redirect first.
    await handleGoogleRedirect();

    final prefs = await SharedPreferences.getInstance();
    final staySignedIn = prefs.getBool('stay_signed_in') ?? true;
    final token = prefs.getString('jwt_token');
    final userDataStr = prefs.getString('user_data');

    if (staySignedIn && token != null && userDataStr != null) {
      try {
        final Map<String, dynamic> user = jsonDecode(userDataStr);
        restoreSession(user);
      } catch (_) {}
    }
  }

  /// Checks if the app was just launched with a Google access token in the URL.
  Future<void> handleGoogleRedirect() async {
    try {
      if (state.loggedInUser == null && hasGoogleRedirectToken()) {
        await signInWithGoogle();
      }
    } catch (e) {}
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(error: 'Veuillez remplir tous les champs.'));
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await authRepository.login(
        email: email.trim(),
        password: password,
        role: state.role.name,
      );
      UserRole userRole = UserRole.candidat;
      if (user.role == 'recruteur' || user.role == 'recruiter') {
        userRole = UserRole.recruteur;
      } else if (user.role == 'formateur' || user.role == 'trainer') {
        userRole = UserRole.formateur;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stay_signed_in', state.staySignedIn);

      String? synchronizedSector;
      if (userRole == UserRole.candidat) {
        final fullProfile = await _fetchFullProfile();
        synchronizedSector = fullProfile?.sector;
      }

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        role: userRole,
        loggedInUser: {
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'role': user.role,
          'entreprise': user.entreprise,
          'sector': synchronizedSector ?? user.sector,
        },
      ));
    } on NeedsVerificationException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        awaitingVerification: true,
        verificationEmail: e.email,
        error: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> register(
      String firstName, String lastName, String email, String password,
      {String? entreprise}) async {
    final isRecruiter = state.role == UserRole.recruteur;

    if (email.isEmpty || password.isEmpty) {
      emit(state.copyWith(error: 'Veuillez remplir email et mot de passe.'));
      return;
    }

    if (isRecruiter && (entreprise == null || entreprise.isEmpty)) {
      emit(state.copyWith(error: 'Veuillez entrer le nom de l\'entreprise.'));
      return;
    }

    if (!isRecruiter && (firstName.trim().isEmpty || lastName.trim().isEmpty)) {
      emit(state.copyWith(error: 'Veuillez entrer votre nom et prénom.'));
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await authRepository.register(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
        role: state.role.name,
        entreprise: entreprise,
      );
      UserRole userRole = UserRole.candidat;
      if (user.role == 'recruteur' || user.role == 'recruiter') {
        userRole = UserRole.recruteur;
      } else if (user.role == 'formateur' || user.role == 'trainer') {
        userRole = UserRole.formateur;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stay_signed_in', state.staySignedIn);

      String? synchronizedSector;
      if (userRole == UserRole.candidat) {
        final fullProfile = await _fetchFullProfile();
        synchronizedSector = fullProfile?.sector;
      }

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        role: userRole,
        loggedInUser: {
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'role': user.role,
          'entreprise': user.entreprise,
          'sector': synchronizedSector ?? user.sector,
        },
      ));
    } on NeedsVerificationException catch (e) {
      emit(state.copyWith(
        isLoading: false,
        awaitingVerification: true,
        verificationEmail: e.email,
        error: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await authRepository.signInWithGoogle(role: state.role.name);
      UserRole userRole = UserRole.candidat;
      if (user.role == 'recruteur' || user.role == 'recruiter') {
        userRole = UserRole.recruteur;
      } else if (user.role == 'formateur' || user.role == 'trainer') {
        userRole = UserRole.formateur;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('stay_signed_in', state.staySignedIn);

      String? synchronizedSector;
      if (userRole == UserRole.candidat) {
        final fullProfile = await _fetchFullProfile();
        synchronizedSector = fullProfile?.sector;
      }

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        role: userRole,
        loggedInUser: {
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'role': user.role,
          'entreprise': user.entreprise,
          'sector': synchronizedSector ?? user.sector,
        },
      ));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('popup_closed') ||
          errorMsg == 'google_redirect' ||
          errorMsg == 'Operation cancelled') {
        emit(state.copyWith(isLoading: false));
        return;
      }
      emit(state.copyWith(isLoading: false, error: errorMsg));
    }
  }

  void completeGithubSignIn(String code) {
    emit(state.copyWith(githubAwaitingCode: false));
    submitGithubCode(code);
  }

  Future<void> signInWithGithub() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await authRepository.signInWithGithub(role: state.role.name);
      emit(state.copyWith(githubAwaitingCode: true));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('popup_closed')) {
        emit(state.copyWith(isLoading: false));
        return;
      }
      emit(state.copyWith(isLoading: false, error: errorMsg));
    }
  }

  Future<void> submitGithubCode(String code) async {
    if (code.trim().isEmpty) {
      emit(state.copyWith(error: 'Veuillez entrer le code GitHub.'));
      return;
    }
    emit(state.copyWith(
        isLoading: true, clearError: true, githubAwaitingCode: false));
    try {
      final user = await authRepository.signInWithGithubCode(code.trim(),
          role: state.role.name);
      UserRole userRole = UserRole.candidat;
      if (user.role == 'recruteur' || user.role == 'recruiter') {
        userRole = UserRole.recruteur;
      } else if (user.role == 'formateur' || user.role == 'trainer') {
        userRole = UserRole.formateur;
      }

      String? synchronizedSector;
      if (userRole == UserRole.candidat) {
        final fullProfile = await _fetchFullProfile();
        synchronizedSector = fullProfile?.sector;
      }

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        role: userRole,
        githubAwaitingCode: false,
        loggedInUser: {
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'role': user.role,
          'entreprise': user.entreprise,
          'sector': synchronizedSector ?? user.sector,
        },
      ));
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains('popup_closed')) {
        emit(state.copyWith(isLoading: false));
        return;
      }
      emit(state.copyWith(isLoading: false, error: errorMsg));
    }
  }

  Future<void> uploadCv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result == null || result.files.single.path == null) return;

      emit(state.copyWith(isUploadingCv: true, clearError: true));

      final cvData = await authRepository.uploadCv(result.files.single.path!);

      emit(state.copyWith(
        isUploadingCv: false,
        cvData: cvData,
      ));
    } catch (e) {
      emit(state.copyWith(
        isUploadingCv: false,
        error: 'Échec de l\'analyse du CV: ${e.toString()}',
      ));
    }
  }

  Future<UserModel?> _fetchFullProfile() async {
    try {
      final fullProfile = await authRepository.getProfile();
      if (state.loggedInUser != null) {
        final updatedUser = Map<String, dynamic>.from(state.loggedInUser!);
        updatedUser['sector'] = fullProfile.sector;
        emit(state.copyWith(loggedInUser: updatedUser));

        // Persist updated user data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(updatedUser));
      }
      return fullProfile;
    } catch (e) {
      print('Error fetching full profile: $e');
      return null;
    }
  }

  Future<void> updateSector(String sector) async {
    try {
      await authRepository.updateProfile({'sector': sector});
      if (state.loggedInUser != null) {
        final updatedUser = Map<String, dynamic>.from(state.loggedInUser!);
        updatedUser['sector'] = sector;
        emit(state.copyWith(loggedInUser: updatedUser));

        // Persist to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(updatedUser));
      }
    } catch (e) {
      print('Error updating sector: $e');
    }
  }

  Future<void> updateUserLocal(Map<String, dynamic> updates) async {
    if (state.loggedInUser != null) {
      final updatedUser = Map<String, dynamic>.from(state.loggedInUser!);
      updates.forEach((key, value) {
        if (value != null) {
          updatedUser[key] = value;
        }
      });
      emit(state.copyWith(loggedInUser: updatedUser));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(updatedUser));
    }
  }

  Future<void> verifySignup(String otp) async {
    final email = state.verificationEmail;
    if (email == null || otp.isEmpty) return;

    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = await authRepository.verifySignup(
          email: email, otp: otp, role: state.role.name);

      UserRole userRole = UserRole.candidat;
      if (user.role == 'recruteur' || user.role == 'recruiter') {
        userRole = UserRole.recruteur;
      } else if (user.role == 'formateur' || user.role == 'trainer') {
        userRole = UserRole.formateur;
      }

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        awaitingVerification: false,
        verificationEmail: null,
        role: userRole,
        loggedInUser: {
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'role': user.role,
          'entreprise': user.entreprise,
          'sector': user.sector,
        },
      ));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    emit(const AuthState()); // Reset to initial state
  }
}
