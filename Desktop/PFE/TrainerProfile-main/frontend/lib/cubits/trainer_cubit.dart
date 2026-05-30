import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/formation_model.dart';
import '../services/dashboard_service.dart';
import '../services/formateur_service.dart';
import '../models/formateur_model.dart';
import 'trainer_state.dart';

class TrainerCubit extends Cubit<TrainerState> {
  final DashboardService _dashboardService;
  final FormateurService _formateurService;

  TrainerCubit(this._dashboardService, this._formateurService)
      : super(TrainerState());

  Future<void> fetchAllData(String userId) async {
    if (userId.isEmpty) return;

    if (isClosed) return;
    emit(state.copyWith(status: TrainerStatus.loading));

    try {
      // Optimized: getDashboardData already returns the formateur (profile) info
      // We don't need to fetch getProfile separately
      final dashboardData = await _dashboardService.getDashboardData(userId);

      if (isClosed) return;
      if (dashboardData == null) {
        emit(state.copyWith(
          status: TrainerStatus.failure,
          errorMessage: 'Impossible de charger les données du dashboard.',
        ));
      } else {
        emit(state.copyWith(
          status: TrainerStatus.success,
          dashboardData: dashboardData,
          profileData:
              dashboardData.formateur, // Use the profile from the same response
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        status: TrainerStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  void updateProfile(FormateurModel newProfile) {
    emit(state.copyWith(profileData: newProfile));
  }

  Future<void> seedData(String userId) async {
    if (isClosed) return;
    emit(state.copyWith(status: TrainerStatus.loading));
    final success = await _dashboardService.seedData(userId);
    if (isClosed) return;
    if (success) {
      await fetchAllData(userId);
      if (isClosed) return;
      Fluttertoast.showToast(msg: "Données de démo initialisées !");
    } else {
      if (isClosed) return;
      emit(state.copyWith(
        status: TrainerStatus.failure,
        errorMessage: 'Échec de l\'initialisation des données.',
      ));
    }
  }

  // Optimize: also update the dashboard's formateur info when profile changes
  void syncProfileWithDashboard(FormateurModel newProfile) {
    if (state.dashboardData != null) {
      final updatedDashboard = DashboardData(
        formateur: newProfile,
        formations: state.dashboardData!.formations,
        stats: state.dashboardData!.stats,
      );
      emit(state.copyWith(
        profileData: newProfile,
        dashboardData: updatedDashboard,
      ));
    } else {
      emit(state.copyWith(profileData: newProfile));
    }
  }

  Future<bool> addFormation(String userId, FormationModel formation) async {
    final newFormation =
        await _dashboardService.createFormation(userId, formation);
    if (newFormation != null && state.dashboardData != null) {
      final updatedList = [newFormation, ...state.dashboardData!.formations];

      // Update local stats card
      final updatedStats =
          Map<String, dynamic>.from(state.dashboardData!.stats);
      updatedStats['totalFormations'] =
          (updatedStats['totalFormations'] ?? 0) + 1;

      final updatedDashboard = DashboardData(
        formateur: state.dashboardData!.formateur,
        formations: updatedList,
        stats: updatedStats,
      );
      if (isClosed) return true; // Still return success since backend worked
      emit(state.copyWith(dashboardData: updatedDashboard));

      // Refresh everything from backend to keep charts and other stats in sync
      fetchAllData(userId);

      return true;
    }
    return false;
  }

  Future<bool> editFormation(String id, FormationModel formation) async {
    final updated = await _dashboardService.updateFormation(id, formation);
    if (updated != null && state.dashboardData != null) {
      final updatedList = state.dashboardData!.formations.map((f) {
        return f.id == id ? updated : f;
      }).toList();

      final updatedDashboard = DashboardData(
        formateur: state.dashboardData!.formateur,
        formations: updatedList,
        stats: state.dashboardData!.stats,
      );
      if (isClosed) return true;
      emit(state.copyWith(dashboardData: updatedDashboard));

      // Refresh to update rankings and stats
      if (state.profileData != null) {
        fetchAllData(state.profileData!.id);
      }

      return true;
    }
    return false;
  }

  Future<bool> removeFormation(String id) async {
    final success = await _dashboardService.deleteFormation(id);
    if (success && state.dashboardData != null) {
      final updatedList =
          state.dashboardData!.formations.where((f) => f.id != id).toList();

      // Update local stats card
      final updatedStats =
          Map<String, dynamic>.from(state.dashboardData!.stats);
      updatedStats['totalFormations'] =
          (updatedStats['totalFormations'] ?? 0) - 1;

      final updatedDashboard = DashboardData(
        formateur: state.dashboardData!.formateur,
        formations: updatedList,
        stats: updatedStats,
      );
      if (isClosed) return true;
      emit(state.copyWith(dashboardData: updatedDashboard));

      // Trigger a full fetch to update rankings, students count, and charts
      if (state.profileData != null) {
        fetchAllData(state.profileData!.id);
      }

      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> generateFormationContent(String title) async {
    return await _dashboardService.enhanceFormation(title);
  }

  Future<void> terminateFormation(String id) async {
    final updated = await _dashboardService.terminateFormation(id);
    if (updated != null && state.dashboardData != null) {
      final updatedList = state.dashboardData!.formations.map((f) {
        return f.id == id ? updated : f;
      }).toList();

      final updatedDashboard = DashboardData(
        formateur: state.dashboardData!.formateur,
        formations: updatedList,
        stats: state.dashboardData!.stats,
      );
      emit(state.copyWith(dashboardData: updatedDashboard));
      Fluttertoast.showToast(msg: "Formation terminée !");
    }
  }

  Future<void> closeFormation(String id) async {
    final updated = await _dashboardService.closeFormation(id);
    if (updated != null && state.dashboardData != null) {
      final updatedList = state.dashboardData!.formations.map((f) {
        return f.id == id ? updated : f;
      }).toList();

      final updatedDashboard = DashboardData(
        formateur: state.dashboardData!.formateur,
        formations: updatedList,
        stats: state.dashboardData!.stats,
      );
      emit(state.copyWith(dashboardData: updatedDashboard));
      Fluttertoast.showToast(msg: "Formation fermée !");
    }
  }

  Future<void> rateStudent(
      String formationId, String studentId, double rating) async {
    final updated =
        await _dashboardService.rateStudent(formationId, studentId, rating);
    if (updated != null && state.dashboardData != null) {
      final updatedList = state.dashboardData!.formations.map((f) {
        return f.id == formationId ? updated : f;
      }).toList();

      final updatedDashboard = DashboardData(
        formateur: state.dashboardData!.formateur,
        formations: updatedList,
        stats: state.dashboardData!.stats,
      );
      emit(state.copyWith(dashboardData: updatedDashboard));
    }
  }

  Future<void> deleteAccount(String userId,
      {String? password, String? googleToken}) async {
    if (isClosed) return;
    emit(state.copyWith(status: TrainerStatus.loading));
    try {
      await _formateurService.deleteAccount(userId,
          password: password, googleToken: googleToken);
    } catch (e) {
      emit(state.copyWith(
        status: TrainerStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
      rethrow;
    }
  }
}
