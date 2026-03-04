import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/landing_model.dart';

part 'landing_state.dart';

class LandingCubit extends Cubit<LandingState> {
  LandingCubit() : super(LandingInitial());

  Future<void> loadStats() async {
    emit(LandingLoading());
    try {
      final stats = await LandingStats.fetch();
      emit(LandingLoaded(stats));
    } catch (e) {
      emit(LandingError('Erreur de chargement des données'));
    }
  }
}
