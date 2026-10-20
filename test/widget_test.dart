// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:my_news/main.dart';
import 'package:my_news/models/story.dart';

void main() {
  testWidgets('My News home screen displays its app bar', (tester) async {
    await tester.pumpWidget(const MyNewsApp());
    expect(find.text('My News'), findsOneWidget);
  });

  test('story detail reads publisher summaries and retains generated analysis',
      () {
    final story = Story.fromJson({
      'id': 'climate-story',
      'headline': 'Senate passes climate bill',
      'updatedAt': '2026-10-20T12:00:00Z',
      'publisherCount': 1,
      'publishers': ['NPR'],
      'sources': [
        {
          'publisher': 'NPR',
          'title': 'Senate vote',
          'summary': 'The Senate passed a climate bill.',
          'url': 'https://www.npr.org/story',
        },
      ],
    });
    const analysis = AiAnalysis(overview: 'The Senate passed the bill.');

    expect(story.sources.single.summary, 'The Senate passed a climate bill.');
    expect(story.copyWith(ai: analysis).ai, same(analysis));
  });
}
