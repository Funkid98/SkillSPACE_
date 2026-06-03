import 'package:flutter_bloc/flutter_bloc.dart';
import 'simulation_state.dart';
import '../data/simulation_api.dart';

// Uses ApiClient (BrowserClient + withCredentials) — no manual token required.
class SimulationCubit extends Cubit<SimulationState> {
  SimulationCubit() : super(SimulationInitial());

  Future<void> fetchAcceptedOffers() async {
    if (isClosed) return;
    emit(SimulationLoading());
    try {
      final data = await SimulationApi().fetchAcceptedOffers();
      if (isClosed) return;
      emit(SimulationLoaded(data));
    } catch (e) {
      if (isClosed) return;
      final msg = e.toString();
      if (msg.contains('Non authentifié')) {
        emit(const SimulationError('Non authentifié'));
      } else if (msg.contains('Impossible de charger')) {
        emit(const SimulationError(
            'Impossible de charger vos offres acceptées'));
      } else {
        emit(SimulationError('Erreur réseau : $e'));
      }
    }
  }
}
