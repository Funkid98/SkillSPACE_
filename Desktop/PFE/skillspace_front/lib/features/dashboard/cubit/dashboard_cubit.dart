import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/dashboard_model.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(DashboardInitial());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final data = await DashboardData.fetch();
      emit(DashboardLoaded(data));
    } catch (e) {
      emit(DashboardError('Failed to load dashboard: $e'));
    }
  }

  void updateSkillPercent(int index, int percent) {
    if (state is DashboardLoaded) {
      final data = (state as DashboardLoaded).data;
      if (index >= 0 && index < data.skills.length) {
        data.skills[index].percent = percent.clamp(0, 100);
        emit(DashboardLoaded(data));
      }
    }
  }

  Future<void> saveSkills() async {
    if (state is DashboardLoaded) {
      final data = (state as DashboardLoaded).data;
      emit(DashboardSaving(data));
      try {
        await DashboardData.saveSkills(data.skills);
        emit(DashboardLoaded(data));
      } catch (e) {
        emit(DashboardLoaded(data));
      }
    }
  }
}
