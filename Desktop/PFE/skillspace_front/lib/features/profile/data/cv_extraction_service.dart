import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:pfe/core/network/api_client.dart';

class CvExtractionService {
  static final ApiClient _apiClient = ApiClient();

  /// Upload a CV file and return the AI-extracted data as a Map.
  /// Uses ApiClient which sends the HttpOnly cookie automatically.
  static Future<Map<String, dynamic>> uploadCv({
    required PlatformFile file,
  }) async {
    if (file.bytes == null) {
      throw Exception('Cannot read file');
    }

    final response = await _apiClient.uploadFile(
      '/cv/upload',
      file.bytes!,
      file.name,
      fieldName: 'cv',
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Upload failed');
    }

    final body = jsonDecode(response.body);
    return body['data'] as Map<String, dynamic>;
  }
}
