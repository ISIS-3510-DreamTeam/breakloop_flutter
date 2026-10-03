
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/data/auth_repository.dart';

import '../../features/goals/view/goal_progress_card.dart';

//TODO: Important! Remove this file once the actual home is implemented
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  void _incrementCounter() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthRepository>().currentUser;
    final String? email = currentUser?.email.toString();
    final userName = email?.substring(0, email.indexOf('@')) ?? 'User';
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome Back, $userName'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoalProgressCard(),
            Text('Logged in as: $userName'),
            const Text('You have pushed the button this many times:'),
            Text('$_counter', style: Theme.of(context).textTheme.headlineMedium),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        child: const Icon(Icons.add),
      ),
    );
  }
}
