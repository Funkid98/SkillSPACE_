import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/formateur_model.dart';
import '../models/formation_model.dart';

class DashboardData {
  final FormateurModel formateur;
  final List<FormationModel> formations;
  final Map<String, dynamic> stats;

  DashboardData({
    required this.formateur,
    required this.formations,
    required this.stats,
  });
}

class DashboardService {
  final String baseUrl = 'http://localhost:5004/api/formateur';

  Future<DashboardData?> getDashboardData(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DashboardData(
          formateur: FormateurModel.fromJson(data['formateur']),
          formations: (data['formations'] as List)
              .map((f) => FormationModel.fromJson(f))
              .toList(),
          stats: data['stats'],
        );
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching dashboard: $e');
      return null;
    }
  }

  Future<bool> seedData(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/seed/$userId'),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error seeding data: $e');
      return false;
    }
  }
}
