part of 'landing_cubit.dart';

abstract class LandingState {}

class LandingInitial extends LandingState {}

class LandingLoading extends LandingState {}

class LandingLoaded extends LandingState {
  final LandingStats stats;
  LandingLoaded(this.stats);
}

class LandingError extends LandingState {
  final String message;
  LandingError(this.message);
}
