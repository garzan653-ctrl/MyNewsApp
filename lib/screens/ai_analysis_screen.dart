import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/story.dart';
import 'perspective_screen.dart';

class AiAnalysisScreen extends StatelessWidget {
  final Story story;

  const AiAnalysisScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    final ai = story.ai!;

    return Scaffold(
      appBar: AppBar(title: const Text('AI analysis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome),
              const SizedBox(width: 8),
              const Text(
                'AI-generated',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (ai.generatedAt != null)
                Text(
                  DateFormat('MMM d, h:mm a')
                      .format(ai.generatedAt!.toLocal()),
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _Box(
            title: 'Overview',
            child: Text(ai.overview, style: const TextStyle(height: 1.45)),
          ),
          if (ai.agreement != null)
            _Box(
              title: 'Agreement',
              child: Text(ai.agreement!, style: const TextStyle(height: 1.45)),
            ),
          if (ai.uncertainty != null)
            _Box(
              title: 'Uncertainty',
              child: Text(
                ai.uncertainty!,
                style: const TextStyle(height: 1.45),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Explore perspectives',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (ai.perspectives.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Insufficient evidence for distinct perspectives.',
                ),
              ),
            )
          else
            ...ai.perspectives.map(
              (p) => Card(
                child: ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(p.name),
                  subtitle: Text(
                    p.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PerspectiveScreen(
                          story: story,
                          perspective: p,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          if (ai.inputScope != null) ...[
            const SizedBox(height: 16),
            Text(
              'Input scope: ${ai.inputScope}',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Read original coverage for full context.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String title;
  final Widget child;

  const _Box({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
