import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/story.dart';
import '../services/news_api.dart';
import 'ai_analysis_screen.dart';

class StoryDetailScreen extends StatefulWidget {
  final String storyId;
  final Story initialStory;

  const StoryDetailScreen({
    super.key,
    required this.storyId,
    required this.initialStory,
  });

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  final NewsApi _api = NewsApi();
  late Future<Story> _storyFuture;
  bool _analysisLoading = false;
  String? _analysisError;

  @override
  void initState() {
    super.initState();
    _storyFuture = _api.getStory(widget.storyId);
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  Future<void> _openAnalysis(Story story) async {
    if (_analysisLoading) return;
    setState(() {
      _analysisLoading = true;
      _analysisError = null;
    });
    try {
      final analysis = story.ai ?? await _api.generateStoryAnalysis(story.id);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiAnalysisScreen(story: story.copyWith(ai: analysis)),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _analysisError = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _analysisLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Story detail')),
      body: FutureBuilder<Story>(
        future: _storyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Could not load the latest story details.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _storyFuture = _api.getStory(widget.storyId);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final story = snapshot.data ?? widget.initialStory;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              Text(
                story.headline,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.menu_book_outlined),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Read the publisher-provided story text below. '
                          'News feeds may include an excerpt rather than the '
                          'full article. Opening the original publisher link '
                          'is optional.',
                          style: TextStyle(height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _Section(
                title: 'Coverage overview',
                child: Text(
                  story.overview?.trim().isNotEmpty == true
                      ? story.overview!
                      : 'No publisher-provided overview is available.',
                  style: const TextStyle(fontSize: 16, height: 1.45),
                ),
              ),
              _Section(
                title: 'Publisher-provided story text',
                child: story.sources.isEmpty
                    ? const Text('No source coverage available.')
                    : Column(
                        children: story.sources.map((source) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.newspaper_rounded,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          source.publisher,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      if (source.publishedAt != null)
                                        Text(
                                          DateFormat('MMM d').format(
                                            source.publishedAt!.toLocal(),
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    source.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (source.summary.trim().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      source.summary,
                                      style: const TextStyle(height: 1.45),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'This publisher did not provide a summary in its news feed.',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (source.url.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _open(source.url),
                                        icon: const Icon(
                                          Icons.open_in_new,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Open original (optional)',
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              _Section(
                title: 'Background',
                child: story.background.isEmpty
                    ? const Text('No background resource available')
                    : Column(
                        children: story.background.map((resource) {
                          return _ActionTile(
                            icon: Icons.menu_book,
                            title: resource.label,
                            onTap: () => _open(resource.url),
                          );
                        }).toList(),
                      ),
              ),
              _Section(
                title: 'AI analysis',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Get a balanced summary of the available coverage, '
                      'what outlets agree on, and what remains unclear.',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _analysisLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                          _analysisLoading
                              ? 'Analyzing coverage...'
                              : story.ai == null
                                  ? 'Generate AI analysis'
                                  : 'View AI analysis',
                        ),
                        onPressed: _analysisLoading
                            ? null
                            : () => _openAnalysis(story),
                      ),
                    ),
                    if (_analysisError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _analysisError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      if (_analysisError!.contains('OPENAI_API_KEY'))
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Ask the server administrator to configure the '
                            'OpenAI key. Do not enter secret keys in the app.',
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Summaries use publisher-provided feed excerpts, not full article text.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 9),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.open_in_new),
      onTap: onTap,
    );
  }
}
