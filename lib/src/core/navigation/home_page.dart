
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/data/auth_repository.dart';

import '../../features/goals/view/goal_progress_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;
    final String? email = currentUser?.email.toString();
    final userName = email?.substring(0, email.indexOf('@')) ?? 'User';
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome Back, $userName'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GoalProgressCard(),
              const SizedBox(height: 50),
              Text("Pets and badges are coming soon")
            ],
          )
        ),
      ),
    );
  }
}
