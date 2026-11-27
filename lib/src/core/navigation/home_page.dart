
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/model/app_user.dart';

import '../../features/goals/view/goal_progress_card.dart';
import '../../features/pet/view/pet_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    return Scaffold(
      appBar: AppBar(
        //Rebuilds when the user changes the name in the profile
        title: StreamBuilder<AppUser?>(
          stream: authRepository.userChanges,
          initialData: authRepository.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            final String? email = user?.email;
            final userName = user?.displayName ?? email?.substring(0, email.indexOf('@')) ?? 'User';
            return Text('Welcome Back, $userName');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GoalProgressCard(),
              const SizedBox(height: 50),
              const PetCard()
            ],
          )
        ),
      ),
    );
  }
}
