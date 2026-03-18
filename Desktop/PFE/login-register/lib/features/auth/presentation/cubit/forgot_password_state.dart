part of 'forgot_password_cubit.dart';

enum ForgotStep { email, otp, newPassword, success }

class ForgotPasswordState {
  final ForgotStep step;
  final bool isLoading;
  final String? error;
  final String? email; // saved after step 1
  final String? otp;   // saved after step 2
  final bool passwordVisible;
  final bool confirmPasswordVisible;

  const ForgotPasswordState({
    this.step = ForgotStep.email,
    this.isLoading = false,
    this.error,
    this.email,
    this.otp,
    this.passwordVisible = false,
    this.confirmPasswordVisible = false,
  });

  ForgotPasswordState copyWith({
    ForgotStep? step,
    bool? isLoading,
    String? error,
    String? email,
    String? otp,
    bool? passwordVisible,
    bool? confirmPasswordVisible,
    bool clearError = false,
  }) {
    return ForgotPasswordState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      email: email ?? this.email,
      otp: otp ?? this.otp,
      passwordVisible: passwordVisible ?? this.passwordVisible,
      confirmPasswordVisible: confirmPasswordVisible ?? this.confirmPasswordVisible,
    );
  }
}