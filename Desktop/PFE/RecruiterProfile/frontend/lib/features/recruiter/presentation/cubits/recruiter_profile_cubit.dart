import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/company_profile_model.dart';
import '../../data/repositories/recruiter_repository.dart';
abstract class RecruiterProfileState {}

class RecruiterProfileInitial extends RecruiterProfileState {}

class RecruiterProfileLoading extends RecruiterProfileState {}

class RecruiterProfileLoaded extends RecruiterProfileState {
  final CompanyProfile profile;
  RecruiterProfileLoaded(this.profile);
}

class RecruiterProfileError extends RecruiterProfileState {
  final String message;
  RecruiterProfileError(this.message);
}

class RecruiterProfileCubit extends Cubit<RecruiterProfileState> {
  final RecruiterRepository repository;

  RecruiterProfileCubit({required this.repository}) : super(RecruiterProfileInitial());

  void loadProfile() async {
    emit(RecruiterProfileLoading());
    try {
      final profile = await repository.getProfile();
      emit(RecruiterProfileLoaded(profile));
    } catch (e) {
      emit(RecruiterProfileError('Failed to load profile: ${e.toString()}'));
    }
  }

  void updateProfile(CompanyProfile updatedProfile) async {
    emit(RecruiterProfileLoading());
    try {
      final profile = await repository.updateProfile(updatedProfile);
      emit(RecruiterProfileLoaded(profile));
    } catch (e) {
      emit(RecruiterProfileError('Failed to update profile: ${e.toString()}'));
    }
  }

  Future<String> uploadLogo(List<int> bytes, String filename) async {
    return await repository.uploadLogo(bytes, filename);
  }
}
