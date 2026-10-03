import 'package:flutter/material.dart';

//TODO: Important! Remove this file once the Focus, Offline and Social sections are implemented
class SectionPlaceholderPage extends StatelessWidget {
  final String title;
  const SectionPlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title is coming soon')),
    );
  }

}
