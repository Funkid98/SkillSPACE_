import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:pfe/core/network/cookie_service.dart';
import 'simulation_state.dart';

class SimulationCubit extends Cubit<SimulationState> {
  SimulationCubit() : super(SimulationInitial());

  Future<void> fetchAcceptedOffers() async {
    emit(SimulationLoading());
    try {
      final token = CookieService.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        emit(const SimulationError('Non authentifié'));
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/candidat/accepted-offers'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        emit(SimulationLoaded(data));
      } else {
        emit(const SimulationError('Impossible de charger vos offres acceptées'));
      }
    } catch (e) {
      emit(SimulationError('Erreur réseau : $e'));
    }
  }
}
