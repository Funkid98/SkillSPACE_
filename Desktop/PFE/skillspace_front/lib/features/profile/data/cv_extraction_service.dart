import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class CvExtractionService {
  // Change this to your backend URL
  static const String _baseUrl = 'http://127.0.0.1:5000';

  /// Upload a CV file and return the AI-extracted data as a Map.
  static Future<Map<String, dynamic>> uploadCv({
    required PlatformFile file,
    required String token,
  }) async {
    final uri = Uri.parse('$_baseUrl/cv/upload');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token';

    if (file.bytes != null) {
      // Web / memory
      request.files.add(http.MultipartFile.fromBytes(
        'cv',
        file.bytes!,
        filename: file.name,
      ));
    } else if (file.path != null) {
      // Mobile / desktop
      request.files.add(await http.MultipartFile.fromPath(
        'cv',
        file.path!,
        filename: file.name,
      ));
    } else {
      throw Exception('Cannot read file');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Upload failed');
    }

    final body = jsonDecode(response.body);
    return body['data'] as Map<String, dynamic>;
  }
}
