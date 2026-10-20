import 'package:flutter/material.dart';
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
              _Section(
                title: 'Story overview',
                child: Text(
                  story.overview?.trim().isNotEmpty == true
                      ? story.overview!
                      : 'No overview is available.',
                  style: const TextStyle(fontSize: 16, height: 1.45),
                ),
              ),
              _Section(
                title: 'Original coverage',
                child: story.sources.isEmpty
                    ? const Text('No source coverage available.')
                    : Column(
                        children: story.sources.map((source) {
                          return _ActionTile(
                            icon: Icons.open_in_new,
                            title: source.publisher,
                            subtitle: source.title,
                            onTap: () => _open(source.url),
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
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('View AI overview & perspectives'),
                    onPressed: story.ai == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AiAnalysisScreen(
                                  story: story,
                                ),
                              ),
                            );
                          },
                  ),
                ),
              ),
              if (story.ai == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'AI analysis is currently unavailable.',
                    textAlign: TextAlign.center,
                  ),
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
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.open_in_new),
      onTap: onTap,
    );
  }
}
