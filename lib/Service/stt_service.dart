import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SttService {
  // Store alongside your other base URLs in API_service.dart if preferred
  static const String _whisperUrl =
      'https://api.openai.com/v1/audio/transcriptions';
  final String _apiKey;

  SttService({required String apiKey}) : _apiKey = apiKey;

  /// Called on iOS/Android — pass the file path from NativeRecorder
  Future<String?> transcribeFile(String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl))
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = 'whisper-1'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));
    return _send(request);
  }

  /// Called on Web — pass the bytes from WebRecorder
  Future<String?> transcribeBytes(Uint8List bytes) async {
    final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl))
      ..headers['Authorization'] = 'Bearer $_apiKey'
      ..fields['model'] = 'whisper-1'
      ..files.add(http.MultipartFile.fromBytes(
        'file', bytes, filename: 'voice_input.webm',
      ));
    return _send(request);
  }

  Future<String?> _send(http.MultipartRequest request) async {
    try {
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['text'] as String?;
      }
      debugPrint('Whisper error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Whisper request failed: $e');
      return null;
    }
  }
}