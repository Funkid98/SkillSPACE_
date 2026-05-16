import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

part 'formations_state.dart';

class FormationsCubit extends Cubit<FormationsState> {
  FormationsCubit() : super(FormationsInitial());

  Future<void> fetchFormations() async {
    emit(FormationsLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      if (token.isEmpty) {
        emit(FormationsError('Non authentifié'));
        return;
      }

      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/candidat/formations'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        emit(FormationsLoaded(data));
      } else {
        emit(FormationsError('Impossible de charger vos formations'));
      }
    } catch (e) {
      emit(FormationsError('Erreur réseau : $e'));
    }
  }

  Future<void> completeFormation(String formationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/candidat/complete/$formationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Refresh list to show updated status
        await fetchFormations();
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<void> leaveFormation(String formationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/candidat/leave/$formationId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Refresh list to remove the formation
        await fetchFormations();
      }
    } catch (e) {
      // Handle error if needed
    }
  }

  Future<bool> submitReview(
      String formationId, int rating, String review) async {
    // Optimistic Update: Update local state immediately
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
            // First time rating: increment count and add to average
            double totalPoints = globalRating * reviewCount;
            reviewCount++;
            globalRating = (totalPoints + newRating) / reviewCount;
          } else {
            // Updating existing rating: swap old points with new points
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/candidat/review/$formationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': rating,
          'review': review,
        }),
      );

      if (response.statusCode == 200) {
        // Optionally fetch again to ensure sync with server-side calculations
        // await fetchFormations(); 
        return true;
      } else {
        // Rollback on failure
        if (previousFormations.isNotEmpty) emit(FormationsLoaded(previousFormations));
        return false;
      }
    } catch (e) {
      // Rollback on error
      if (previousFormations.isNotEmpty) emit(FormationsLoaded(previousFormations));
      return false;
    }
  }
}
