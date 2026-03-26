part of 'dashboard_cubit.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardData data;
  DashboardLoaded(this.data);
}

class DashboardSaving extends DashboardState {
  final DashboardData data;
  DashboardSaving(this.data);
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
