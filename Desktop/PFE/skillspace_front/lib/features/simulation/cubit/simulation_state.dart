import 'package:equatable/equatable.dart';

abstract class SimulationState extends Equatable {
  const SimulationState();

  @override
  List<Object> get props => [];
}

class SimulationInitial extends SimulationState {}

class SimulationLoading extends SimulationState {}

class SimulationLoaded extends SimulationState {
  final List<dynamic> acceptedOffers;

  const SimulationLoaded(this.acceptedOffers);

  @override
  List<Object> get props => [acceptedOffers];
}

class SimulationError extends SimulationState {
  final String message;

  const SimulationError(this.message);

  @override
  List<Object> get props => [message];
}
