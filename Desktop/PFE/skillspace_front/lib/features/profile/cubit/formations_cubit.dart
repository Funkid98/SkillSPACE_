import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pfe/core/network/api_client.dart';
import 'dart:convert';

part 'formations_state.dart';

// Uses ApiClient (BrowserClient + withCredentials) — no manual token required.
class FormationsCubit extends Cubit<FormationsState> {
  final ApiClient _apiClient = ApiClient();

  FormationsCubit() : super(FormationsInitial());

  Future<void> fetchFormations() async {
    emit(FormationsLoading());
    try {
      final response = await _apiClient.get('/candidat/formations');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        emit(FormationsLoaded(data));
      } else if (response.statusCode == 401) {
        emit(FormationsError('Non authentifié'));
      } else {
        emit(FormationsError('Impossible de charger vos formations'));
      }
    } catch (e) {
      emit(FormationsError('Erreur réseau : $e'));
    }
  }

  Future<void> completeFormation(String formationId) async {
    try {
      final response = await _apiClient.post('/candidat/complete/$formationId', {});
      if (response.statusCode == 200) {
        await fetchFormations();
      }
    } catch (_) {}
  }

  Future<void> leaveFormation(String formationId) async {
    try {
      final response = await _apiClient.post('/candidat/leave/$formationId', {});
      if (response.statusCode == 200) {
        await fetchFormations();
      }
    } catch (_) {}
  }

  Future<bool> submitReview(
      String formationId, int rating, String review) async {
    List<dynamic> previousFormations = [];
    if (state is FormationsLoaded) {
      previousFormations = (state as FormationsLoaded).formations;
      final updatedFormations = previousFormations.map((f) {
        if ((f['_id'] ?? f['id']).toString() == formationId) {
          final updatedF = Map<String, dynamic>.from(f);

          final int oldRating = (f['rating'] ?? 0).toInt();
          final int newRating = rating;

          int reviewCount = (f['reviewCount'] ?? 0).toInt();
          double globalRating = (f['globalRating'] ?? 0.0).toDouble();

          if (oldRating == 0) {
            double totalPoints = globalRating * reviewCount;
            reviewCount++;
            globalRating = (totalPoints + newRating) / reviewCount;
          } else {
            double totalPoints = globalRating * reviewCount;
            globalRating = (totalPoints - oldRating + newRating) / reviewCount;
          }

          updatedF['rating'] = newRating;
          updatedF['review'] = review;
          updatedF['reviewCount'] = reviewCount;
          updatedF['globalRating'] = globalRating;
          return updatedF;
        }
        return f;
      }).toList();
      emit(FormationsLoaded(updatedFormations));
    }

    try {
      final response = await _apiClient.post('/candidat/review/$formationId', {
        'rating': rating,
        'review': review,
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        if (previousFormations.isNotEmpty) emit(FormationsLoaded(previousFormations));
        return false;
      }
    } catch (_) {
      if (previousFormations.isNotEmpty) emit(FormationsLoaded(previousFormations));
      return false;
    }
  }
}
