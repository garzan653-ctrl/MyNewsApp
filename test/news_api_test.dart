import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_news/services/news_api.dart';

void main() {
  test('stories endpoint returns parsed stories from JSON', () async {
    final api = NewsApi(
      baseUrl: 'https://news.example',
      client: MockClient((request) async {
        expect(request.url.path, '/stories');
        return http.Response('{"stories":[]}', 200);
      }),
    );

    expect(await api.getStories(), isEmpty);
  });

  test('HTML from stories endpoint gives a useful server URL error', () async {
    final api = NewsApi(
      baseUrl: 'https://news.example',
      client: MockClient((_) async {
        return http.Response(
          '<!DOCTYPE html><html><body>Not found</body></html>',
          200,
          headers: {'content-type': 'text/html'},
        );
      }),
    );

    await expectLater(
      api.getStories(),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('returned a web page instead of news data'),
        ),
      ),
    );
  });
}
