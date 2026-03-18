import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';

part 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository authRepository;

  ForgotPasswordCubit({required this.authRepository}) : super(const ForgotPasswordState());

  void clearError() => emit(state.copyWith(clearError: true));
  void togglePassword() =>
      emit(state.copyWith(passwordVisible: !state.passwordVisible));
  void toggleConfirmPassword() =>
      emit(state.copyWith(confirmPasswordVisible: !state.confirmPasswordVisible));

  // STEP 1 — Send OTP to email
  Future<void> sendOtp(String email) async {
    if (email.trim().isEmpty) {
      emit(state.copyWith(error: 'Veuillez entrer votre email.'));
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await authRepository.forgotPassword(email.trim());
      emit(state.copyWith(isLoading: false, step: ForgotStep.otp, email: email.trim()));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // STEP 2 — Verify OTP
  Future<void> verifyOtp(String otp) async {
    if (otp.trim().length < 4) {
      emit(state.copyWith(error: 'Code invalide.'));
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await authRepository.verifyOtp(state.email!, otp.trim());
      emit(state.copyWith(isLoading: false, step: ForgotStep.newPassword, otp: otp.trim()));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // STEP 3 — Reset password
  Future<void> resetPassword(String password, String confirm) async {
    if (password.length < 6) {
      emit(state.copyWith(error: 'Le mot de passe doit contenir au moins 6 caractères.'));
      return;
    }
    if (password != confirm) {
      emit(state.copyWith(error: 'Les mots de passe ne correspondent pas.'));
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await authRepository.resetPassword(state.email!, state.otp!, password);
      emit(state.copyWith(isLoading: false, step: ForgotStep.success));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Resend OTP
  Future<void> resendOtp() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await authRepository.forgotPassword(state.email!);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  void reset() => emit(const ForgotPasswordState());
}