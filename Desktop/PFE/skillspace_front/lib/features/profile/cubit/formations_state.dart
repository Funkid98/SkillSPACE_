part of 'formations_cubit.dart';

abstract class FormationsState {}

class FormationsInitial extends FormationsState {}

class FormationsLoading extends FormationsState {}

class FormationsLoaded extends FormationsState {
  final List<dynamic> formations;
  FormationsLoaded(this.formations);
}

class FormationsError extends FormationsState {
  final String message;
  FormationsError(this.message);
}
