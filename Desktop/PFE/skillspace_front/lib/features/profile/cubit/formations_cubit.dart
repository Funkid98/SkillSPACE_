import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/profile_api.dart';

part 'formations_state.dart';

// Uses ApiClient (BrowserClient + withCredentials) — no manual token required.
class FormationsCubit extends Cubit<FormationsState> {
  FormationsCubit() : super(FormationsInitial());

  Future<void> fetchFormations() async {
    emit(FormationsLoading());
    try {
      final data = await ProfileApi.fetchFormations();
      emit(FormationsLoaded(data));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Non authentifié')) {
        emit(FormationsError('Non authentifié'));
      } else if (msg.contains('Impossible de charger')) {
        emit(FormationsError('Impossible de charger vos formations'));
      } else {
        emit(FormationsError('Erreur réseau : $e'));
      }
    }
  }

  Future<void> completeFormation(String formationId) async {
    try {
      await ProfileApi.completeFormation(formationId);
      await fetchFormations();
    } catch (_) {}
  }

  Future<void> leaveFormation(String formationId) async {
    try {
      await ProfileApi.leaveFormation(formationId);
      await fetchFormations();
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
      final success = await ProfileApi.submitReview(formationId, rating, review);
      if (success) {
        return true;
      } else {
        if (previousFormations.isNotEmpty) {
          emit(FormationsLoaded(previousFormations));
        }
        return false;
      }
    } catch (_) {
      if (previousFormations.isNotEmpty) {
        emit(FormationsLoaded(previousFormations));
      }
      return false;
    }
  }
}
