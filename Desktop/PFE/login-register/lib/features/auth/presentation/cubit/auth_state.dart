part of 'auth_cubit.dart';

enum AuthTab { login, register }

enum UserRole { candidat, recruteur, formateur }

class AuthState {
  final AuthTab tab;
  final UserRole role;
  final bool passwordVisible;
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final bool githubAwaitingCode;
  final bool isUploadingCv;
  final Map<String, dynamic>? cvData;
  final Map<String, dynamic>? loggedInUser; // Holds user data after login
  final bool staySignedIn;
  final bool awaitingVerification;
  final String? verificationEmail;

  const AuthState({
    this.tab = AuthTab.login,
    this.role = UserRole.candidat,
    this.passwordVisible = false,
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.githubAwaitingCode = false,
    this.isUploadingCv = false,
    this.cvData,
    this.loggedInUser,
    this.staySignedIn = true,
    this.awaitingVerification = false,
    this.verificationEmail,
  });

  AuthState copyWith({
    AuthTab? tab,
    UserRole? role,
    bool? passwordVisible,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSuccess,
    bool? githubAwaitingCode,
    bool? isUploadingCv,
    Map<String, dynamic>? cvData,
    Map<String, dynamic>? loggedInUser,
    bool? staySignedIn,
    bool? awaitingVerification,
    String? verificationEmail,
  }) {
    return AuthState(
      tab: tab ?? this.tab,
      role: role ?? this.role,
      passwordVisible: passwordVisible ?? this.passwordVisible,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
      githubAwaitingCode: githubAwaitingCode ?? this.githubAwaitingCode,
      isUploadingCv: isUploadingCv ?? this.isUploadingCv,
      cvData: cvData ?? this.cvData,
      loggedInUser: loggedInUser ?? this.loggedInUser,
      staySignedIn: staySignedIn ?? this.staySignedIn,
      awaitingVerification: awaitingVerification ?? this.awaitingVerification,
      verificationEmail: verificationEmail ?? this.verificationEmail,
    );
  }
}
