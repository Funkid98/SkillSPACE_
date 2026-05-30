import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/dashboard_model.dart';

part 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  Timer? _pollingTimer;

  DashboardCubit() : super(DashboardInitial());

  Future<void> loadDashboard() async {
    emit(DashboardLoading());
    try {
      final data = await DashboardData.fetch();
      if (!isClosed) {
        emit(DashboardLoaded(data));
        _triggerPollingIfNeeded(data);
      }
    } catch (e) {
      if (!isClosed) emit(DashboardError('Failed to load dashboard: $e'));
    }
  }

  void _triggerPollingIfNeeded(DashboardData data) {
    if (data.profileViewsCount == -1) {
      _startPolling();
    } else {
      _pollingTimer?.cancel();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (isClosed) {
        _pollingTimer?.cancel();
        return;
      }
      try {
        final freshData = await DashboardData.fetch();
        if (isClosed) return;

        // Preserve un-saved skill changes logically if in Loaded state
        // For simplicity, we just completely update the dashboard data
        emit(DashboardLoaded(freshData));

        if (freshData.profileViewsCount != -1) {
          _pollingTimer?.cancel();
        }
      } catch (_) {}
    });
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
        final freshData = await DashboardData.fetch();
        if (!isClosed) {
          emit(DashboardLoaded(freshData));
          _triggerPollingIfNeeded(freshData);
        }
      } catch (e) {
        if (!isClosed) emit(DashboardLoaded(data));
      }
    }
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
