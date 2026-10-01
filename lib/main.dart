import 'package:flutter/material.dart';
import 'src/features/deep_stats/view/deep_stats_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BreakLoop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC86D3B)),
        useMaterial3: true,
      ),
      home: const DeepStatsPage(),
    );
  }
}