// features/auth/view/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/auth_repository.dart';
import '../model/app_user.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: context.read<AuthRepository>().authStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // TODO: replace with real Home once it exists
          return const _PlaceholderHome();
        }

        return const LoginPage();
      },
    );
  }
}

// Temporary placeholder.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home (placeholder)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthRepository>().signOut(),
          )
        ],
      ),
      body: const Center(child: Text('Logged in')),
    );
  }
}