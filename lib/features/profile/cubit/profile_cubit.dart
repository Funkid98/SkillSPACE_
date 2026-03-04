import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/profile_model.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  Future<void> loadProfile() async {
    emit(ProfileLoading());
    try {
      final data = await ProfileData.fetch();
      emit(ProfileLoaded(data));
    } catch (e) {
      emit(ProfileError('Erreur de chargement du profil'));
    }
  }

  void updateField(ProfileData updated) {
    if (state is ProfileLoaded) {
      emit(ProfileLoaded(updated));
    }
  }

  void markCvUploaded() {
    if (state is ProfileLoaded) {
      final current = (state as ProfileLoaded).data;
      emit(
          ProfileLoaded(current.copyWith(hasCv: true, completionPercent: 100)));
    }
  }
}
