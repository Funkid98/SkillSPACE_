import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pfe/core/network/api_client.dart';
import '../../../../core/api_constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SimulationApi {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> fetchAcceptedOffers() async {
    final response = await _apiClient.get('/candidat/accepted-offers');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Non authentifié');
    } else {
      throw Exception('Impossible de charger vos offres acceptées');
    }
  }

  Future<Map<String, dynamic>> finishInterview({
    required List<Map<String, dynamic>> history,
    required String roleTitle,
    required String language,
    String? candidateId,
  }) async {
    final body = {
      'history': history,
      'roleTitle': roleTitle,
      'language': language,
      if (candidateId != null) 'candidateId': candidateId,
    };

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/interview/finish'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return data;
      }
    }
    throw Exception("Failed to fetch evaluation");
  }

  Future<Map<String, dynamic>> startInterview(String role, String language) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/interview/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'role': role,
        'language': language,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to start interview");
    }
  }

  Future<Map<String, dynamic>> sendInterviewChat({
    required String audioPath,
    required String language,
    required String roleTitle,
    required List<Map<String, dynamic>> history,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/api/interview/chat'),
    );

    if (kIsWeb) {
      final audioResponse = await http.get(Uri.parse(audioPath));
      request.files.add(http.MultipartFile.fromBytes(
        'audio',
        audioResponse.bodyBytes,
        filename: 'audio.ogg',
        contentType: MediaType('audio', 'ogg'),
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioPath,
        contentType: MediaType('audio', 'ogg'),
      ));
    }

    request.fields['language'] = language;
    request.fields['roleTitle'] = roleTitle;
    request.fields['history'] = jsonEncode(history);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Chat error: ${response.body}");
    }
  }

  /// Fetch raw audio bytes for playback from a relative server path.
  Future<List<int>> fetchAudioBytes(String relativePath) async {
    final fullUrl = '${ApiConstants.baseUrl}$relativePath';
    final response = await http.get(Uri.parse(fullUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to fetch audio recording');
  }
}
