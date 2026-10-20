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

  Widget _buildStoryCard(Story story) {
    final colors = Theme.of(context).colorScheme;
    final hasMultiplePublishers = story.publisherCount > 1;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    hasMultiplePublishers
                        ? Icons.hub_rounded
                        : Icons.article_rounded,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    hasMultiplePublishers
                        ? 'COVERED BY MULTIPLE OUTLETS'
                        : 'LATEST',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(story.updatedAt),
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                story.headline,
                style: const TextStyle(
                  fontSize: 19,
                  height: 1.25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.35,
                ),
              ),
              if (story.publishers.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: story.publishers.map((publisher) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        publisher,
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 15),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 16,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${story.publisherCount} '
                      'outlet${story.publisherCount == 1 ? '' : 's'} · '
                      'Read the coverage & analysis',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: colors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

            final publisherTotal =
                stories.expand((story) => story.publishers).toSet().length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 14, bottom: 28),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff17243a), Color(0xff29475b)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.public_rounded,
                              color: Color(0xff93ded0),
                              size: 19,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('EEEE, MMMM d').format(DateTime.now()),
                              style: const TextStyle(
                                color: Color(0xffdce6ed),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffa8ddc1).withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: Color(0xff81e1b0),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 23),
                        const Text(
                          'The news,\nin perspective.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'See how different outlets cover the stories shaping today.',
                          style: TextStyle(
                            color: Color(0xffdce6ed),
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 19),
                        Wrap(
                          spacing: 9,
                          runSpacing: 8,
                          children: [
                            _HeroStat(
                              icon: Icons.view_headline_rounded,
                              label: '${stories.length} current stories',
                            ),
                            _HeroStat(
                              icon: Icons.newspaper_rounded,
                              label: '$publisherTotal news outlets',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(21, 2, 20, 5),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Today’s headlines',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      Text(
                        'Updated live',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ...stories.map(_buildStoryCard),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xffb4d8d1)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
