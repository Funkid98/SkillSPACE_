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
  final String baseUrl = 'http://localhost:8088/api/formateur';

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

  Future<FormationModel?> createFormation(
      String userId, FormationModel formation) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/formations/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formation.toJson()),
      );
      if (response.statusCode == 201) {
        return FormationModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error creating formation: $e');
      return null;
    }
  }

  Future<FormationModel?> updateFormation(
      String id, FormationModel formation) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/formations/item/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formation.toJson()),
      );
      if (response.statusCode == 200) {
        return FormationModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error updating formation: $e');
      return null;
    }
  }

  Future<bool> deleteFormation(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/formations/item/$id'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting formation: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> enhanceFormation(String title) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/enhance-formation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': title}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error enhancing formation: $e');
      return null;
    }
  }

  Future<FormationModel?> terminateFormation(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/formations/item/$id/terminate'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FormationModel.fromJson(data['formation']);
      }
      return null;
    } catch (e) {
      print('Error terminating formation: $e');
      return null;
    }
  }

  Future<FormationModel?> closeFormation(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/formations/item/$id/close'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FormationModel.fromJson(data['formation']);
      }
      return null;
    } catch (e) {
      print('Error closing formation: $e');
      return null;
    }
  }

  Future<FormationModel?> rateStudent(
      String formationId, String studentId, double rating) async {
    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl/formations/item/$formationId/student/$studentId/rate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'rating': rating}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FormationModel.fromJson(data['formation']);
      }
      return null;
    } catch (e) {
      print('Error rating student: $e');
      return null;
    }
  }
}
