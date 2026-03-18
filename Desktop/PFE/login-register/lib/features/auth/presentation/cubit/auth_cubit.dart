import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(const AuthState());

  void switchTab(AuthTab tab) =>
      emit(state.copyWith(tab: tab, clearError: true));
  void selectRole(UserRole role) => emit(state.copyWith(role: role));
  void togglePassword() =>
      emit(state.copyWith(passwordVisible: !state.passwordVisible));
  void clearError() => emit(state.copyWith(clearError: true));

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
      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        loggedInUser: {
          'firstName': user.firstName,
          'lastName': user.lastName,
          'email': user.email,
          'role': user.role,
        },
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
      await authRepository.register(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
        password: password,
        role: state.role.name,
        entreprise: entreprise,
      );
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await authRepository.signInWithGoogle();
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> signInWithGithub() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await authRepository.signInWithGithub();
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (msg == 'GITHUB_OPEN_BROWSER') {
        emit(state.copyWith(isLoading: false, githubAwaitingCode: true));
      } else {
        emit(state.copyWith(isLoading: false, error: msg));
      }
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
      await (authRepository as dynamic).signInWithGithubCode(code.trim());
      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
          isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
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

  Future<void> logout() async {
    await authRepository.logout();
    emit(const AuthState()); // Reset to initial state
  }
}
