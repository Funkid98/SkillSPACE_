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

  RecruiterDashboardCubit({RecruiterService? recruiterService})
      : _recruiterService = recruiterService ?? RecruiterService(),
        super(RecruiterDashboardInitial());

  void loadDashboard() async {
    emit(RecruiterDashboardLoading());
    try {
      final data = await _recruiterService.getDashboardData();
      emit(RecruiterDashboardLoaded(data));
    } catch (e) {
      emit(
          RecruiterDashboardError('Failed to load dashboard: ${e.toString()}'));
    }
  }
}
