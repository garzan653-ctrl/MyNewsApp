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
      throw Exception('Server returned ${response.statusCode}.');
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
      throw Exception('Server returned ${response.statusCode}.');
    }

    return Story.fromJson(jsonDecode(response.body));
  }
}
