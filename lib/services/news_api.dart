import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/story.dart';

class NewsApi {
  static final String _defaultBaseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : kIsWeb
          ? Uri.base.origin
          : defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2:8000'
              : 'http://127.0.0.1:8000';
  final http.Client _client;
  final String _baseUrl;

  NewsApi({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _configuredBaseUrl = String.fromEnvironment(
    'MY_NEWS_API_URL',
  );

  Future<List<Story>> getStories() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/stories'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw _serverError(response);
    }

    final body = _decodeJson(response);
    final List<dynamic>? data = body is List
        ? body
        : body is Map<String, dynamic> && body['stories'] is List
            ? body['stories'] as List<dynamic>
            : null;
    if (data == null) {
      throw Exception(
          'The news server returned an unexpected stories response.');
    }

    return data.map((e) => Story.fromJson(e)).toList();
  }

  Future<Story> getStory(String id) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/stories/$id'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw _serverError(response);
    }

    final body = _decodeJson(response);
    if (body is! Map<String, dynamic>) {
      throw Exception('The news server returned an unexpected story response.');
    }
    return Story.fromJson(body);
  }

  Future<AiAnalysis> generateStoryAnalysis(String id) async {
    final response = await _client
        .post(Uri.parse('$_baseUrl/stories/$id/analysis'))
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw _serverError(response);
    }

    final body = _decodeJson(response);
    if (body is! Map<String, dynamic>) {
      throw Exception(
        'The news server returned an unexpected AI analysis response.',
      );
    }
    return AiAnalysis.fromJson(body);
  }

  dynamic _decodeJson(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      final contentType = response.headers['content-type']?.toLowerCase() ?? '';
      final bodyStartsWithHtml = response.body.trimLeft().startsWith('<');
      if (contentType.contains('text/html') || bodyStartsWithHtml) {
        throw Exception(
          'The stories address returned a web page instead of news data. '
          'Open My News from the server URL that also provides its /stories API.',
        );
      }
      throw Exception('The news server returned invalid JSON. Please retry.');
    }
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
