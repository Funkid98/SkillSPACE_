part of 'profile_cubit.dart';

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final ProfileData data;
  ProfileLoaded(this.data);
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}
