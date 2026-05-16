import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/recruiter_dashboard_model.dart';
import '../../data/recruiter_service.dart';

abstract class RecruiterDashboardState {}

class RecruiterDashboardInitial extends RecruiterDashboardState {}

class RecruiterDashboardLoading extends RecruiterDashboardState {}

class RecruiterDashboardLoaded extends RecruiterDashboardState {
  final RecruiterDashboardData data;
  RecruiterDashboardLoaded(this.data);
}

class RecruiterDashboardError extends RecruiterDashboardState {
  final String message;
  RecruiterDashboardError(this.message);
}

class RecruiterDashboardCubit extends Cubit<RecruiterDashboardState> {
  final RecruiterService _recruiterService;
  Timer? _pollingTimer;

  RecruiterDashboardCubit({RecruiterService? recruiterService})
      : _recruiterService = recruiterService ?? RecruiterService(),
        super(RecruiterDashboardInitial());

  void loadDashboard({bool isBackground = false}) async {
    if (isClosed) return;
    if (!isBackground) emit(RecruiterDashboardLoading());
    try {
      final data = await _recruiterService.getDashboardData();
      if (isClosed) return;
      emit(RecruiterDashboardLoaded(data));
      _startPolling();
    } catch (e) {
      if (isClosed) return;
      if (!isBackground) {
        emit(RecruiterDashboardError(
            'Failed to load dashboard: ${e.toString()}'));
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (isClosed) {
        timer.cancel();
        return;
      }
      try {
        final data = await _recruiterService.getDashboardData();
        if (!isClosed) emit(RecruiterDashboardLoaded(data));
      } catch (_) {}
    });
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
