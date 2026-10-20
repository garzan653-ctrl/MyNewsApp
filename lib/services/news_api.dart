import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/story.dart';

class NewsApi {
  static final String baseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : kIsWeb
          ? Uri.base.origin
          : defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'MY_NEWS_API_URL',
  );

  Future<List<Story>> getStories() async {
    final response = await http
        .get(Uri.parse('$baseUrl/stories'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw _serverError(response);
    }

    final body = jsonDecode(response.body);
    final List<dynamic> data = body is List ? body : (body['stories'] ?? []);

    return data.map((e) => Story.fromJson(e)).toList();
  }

  Future<Story> getStory(String id) async {
    final response = await http
        .get(Uri.parse('$baseUrl/stories/$id'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw _serverError(response);
    }

    return Story.fromJson(jsonDecode(response.body));
  }

  Future<AiAnalysis> generateStoryAnalysis(String id) async {
    final response = await http
        .post(Uri.parse('$baseUrl/stories/$id/analysis'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw _serverError(response);
    }

    return AiAnalysis.fromJson(jsonDecode(response.body));
  }

  Exception _serverError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['detail'] is String) {
        return Exception(body['detail'] as String);
      }
    } on FormatException {
      // Fall through to the status-only message for non-JSON server errors.
    }
    return Exception('Server returned ${response.statusCode}.');
  }
}
