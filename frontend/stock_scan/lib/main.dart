import 'package:flutter/material.dart';
import 'pages/home_pages.dart'; // si tu l’as mis dans lib/pages/
import 'pages/history_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Stock Scanner',
          theme: ThemeData(primarySwatch: Colors.brown),
          home: const HomePage(),
          routes: {
            '/history': (_) => const HistoryPage(),
          },
      );
  }
}