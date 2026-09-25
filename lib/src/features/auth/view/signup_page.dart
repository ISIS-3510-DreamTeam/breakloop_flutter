import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/signup_viewmodel.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            const SizedBox(height: 16),
            if (vm.status == SignupStatus.error)
              Text(vm.failure?.message ?? '', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            vm.status == SignupStatus.loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () => context.read<SignupViewModel>().signUp(
                _emailController.text.trim(),
                _passwordController.text.trim(),
                _confirmPasswordController.text.trim(),
              ),
              child: const Text('Register'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Already have an account?'),
            ),
          ],
        ),
      ),
    );
  }
}