import 'package:flutter/material.dart';
import 'screens/story_list_screen.dart';

void main() {
  runApp(const MyNewsApp());
}

class MyNewsApp extends StatelessWidget {
  const MyNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff7f8fb),
        cardTheme: const CardThemeData(
          margin: EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        ),
      ),
      home: const StoryListScreen(),
    );
  }
}
