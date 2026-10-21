import 'package:flutter/material.dart';
import 'screens/story_list_screen.dart';

void main() {
  runApp(const MyNewsApp());
}

class MyNewsApp extends StatelessWidget {
  const MyNewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const violet = Color(0xff5b4bdb);
    const teal = Color(0xff00a884);
    const canvas = Color(0xfff4f2ff);
    return MaterialApp(
      title: 'My News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: violet,
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: violet,
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: violet.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xffe5e0ff)),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: teal,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: violet,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: const StoryListScreen(),
    );
  }
}
