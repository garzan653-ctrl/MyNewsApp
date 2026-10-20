import 'package:flutter/material.dart';
import '../models/story.dart';
import 'package:url_launcher/url_launcher.dart';

class PerspectiveScreen extends StatelessWidget {
  final Story story;
  final AiPerspective perspective;

  const PerspectiveScreen({
    super.key,
    required this.story,
    required this.perspective,
  });

  Future<void> _open(String url, BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null || url.isEmpty) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open source.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final indexes = perspective.supportingArticleIndexes;

    return Scaffold(
      appBar: AppBar(title: const Text('Selected perspective')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome),
              SizedBox(width: 8),
              Text(
                'AI-generated',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            perspective.name,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                perspective.text,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Supporting coverage',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (indexes.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No supporting article references were provided.'),
              ),
            )
          else
            ...indexes.map((i) {
              if (i < 0 || i >= story.sources.length) {
                return const SizedBox.shrink();
              }

              final source = story.sources[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text(source.publisher),
                  subtitle: Text(source.title),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _open(source.url, context),
                ),
              );
            }),
        ],
      ),
    );
  }
}
