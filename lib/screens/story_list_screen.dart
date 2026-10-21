import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/story.dart';
import '../services/news_api.dart';
import 'story_detail_screen.dart';

class StoryListScreen extends StatefulWidget {
  const StoryListScreen({super.key});

  @override
  State<StoryListScreen> createState() => _StoryListScreenState();
}

class _StoryListScreenState extends State<StoryListScreen> {
  final NewsApi _api = NewsApi();
  late Future<List<Story>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _storiesFuture = _api.getStories();
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, h:mm a').format(date.toLocal());
  }

  Color _publisherColor(String publisher) {
    const colors = [
      Color(0xff6254dc),
      Color(0xff008f83),
      Color(0xffe45b72),
      Color(0xffdc8a20),
    ];
    return colors[publisher.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My News',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh();
          try {
            await _storiesFuture;
          } catch (_) {}
        },
        child: FutureBuilder<List<Story>>(
          future: _storiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _StatusView(
                icon: Icons.cloud_off,
                title: 'Unable to load stories',
                message: snapshot.error.toString(),
                action: ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              );
            }

            final stories = snapshot.data ?? [];

            if (stories.isEmpty) {
              return _StatusView(
                icon: Icons.newspaper,
                title: 'No stories available',
                message: 'Your server returned no current stories.',
                action: ElevatedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xff7667ed), Color(0xff39c6ae)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 11),
                      const Text(
                        'Top stories',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(69, 0, 20, 8),
                  child: Text(
                    'Grouped coverage from multiple publishers',
                    style: TextStyle(color: Color(0xff66637b)),
                  ),
                ),
                ...stories.map(
                  (story) => Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StoryDetailScreen(
                              storyId: story.id,
                              initialStory: story,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.headline,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff25223a),
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfffff0e4),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bolt_rounded,
                                        size: 15,
                                        color: Color(0xffd97919),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${story.publisherCount} outlet'
                                        '${story.publisherCount == 1 ? '' : 's'}',
                                        style: const TextStyle(
                                          color: Color(0xffa95312),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffe8f7f3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatDate(story.updatedAt),
                                    style: const TextStyle(
                                      color: Color(0xff16796b),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (story.publishers.isNotEmpty) ...[
                              const SizedBox(height: 11),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: story.publishers.map((publisher) {
                                  final color = _publisherColor(publisher);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      publisher,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Color(0xffefedfa)),
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                Icon(
                                  Icons.compare_arrows_rounded,
                                  size: 17,
                                  color: Color(0xff5b4bdb),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Select to compare coverage',
                                  style: TextStyle(
                                    color: Color(0xff5b4bdb),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Spacer(),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 19,
                                  color: Color(0xff5b4bdb),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget action;

  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            action,
          ],
        ),
      ),
    );
  }
}
