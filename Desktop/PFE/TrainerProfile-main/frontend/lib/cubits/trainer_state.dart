import '../models/formateur_model.dart';
import '../services/dashboard_service.dart';

enum TrainerStatus { initial, loading, success, failure }

class TrainerState {
  final TrainerStatus status;
  final DashboardData? dashboardData;
  final FormateurModel? profileData;
  final String? errorMessage;

  TrainerState({
    this.status = TrainerStatus.initial,
    this.dashboardData,
    this.profileData,
    this.errorMessage,
  });

  TrainerState copyWith({
    TrainerStatus? status,
    DashboardData? dashboardData,
    FormateurModel? profileData,
    String? errorMessage,
  }) {
    return TrainerState(
      status: status ?? this.status,
      dashboardData: dashboardData ?? this.dashboardData,
      profileData: profileData ?? this.profileData,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
