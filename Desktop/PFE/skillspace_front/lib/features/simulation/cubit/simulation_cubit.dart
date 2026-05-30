import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/core/network/api_client.dart';
import 'simulation_state.dart';

// Uses ApiClient (BrowserClient + withCredentials) — no manual token required.
class SimulationCubit extends Cubit<SimulationState> {
  final ApiClient _apiClient = ApiClient();

  SimulationCubit() : super(SimulationInitial());

  Future<void> fetchAcceptedOffers() async {
    if (isClosed) return;
    emit(SimulationLoading());
    try {
      final response = await _apiClient.get('/candidat/accepted-offers');

      if (isClosed) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        emit(SimulationLoaded(data));
      } else if (response.statusCode == 401) {
        emit(const SimulationError('Non authentifié'));
      } else {
        emit(const SimulationError(
            'Impossible de charger vos offres acceptées'));
      }
    } catch (e) {
      if (isClosed) return;
      emit(SimulationError('Erreur réseau : $e'));
    }
  }
}
