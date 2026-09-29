import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../viewmodel/login_viewmodel.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();

}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'e-mail')),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'password')),
              const SizedBox(height: 16),
              if (vm.status == LoginStatus.error)
                Text(vm.failure?.message ?? '', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              vm.status == LoginStatus.loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: () => context.read<LoginViewModel>().login(_emailController.text.trim(), _passwordController.text.trim()),
                  child: const Text('Enter'),
                ),
              TextButton(
                  onPressed: () => context.push('/signup'),
                  child: const Text("Don't have an account already? Sign Up"),
              ),

              TextButton(
                onPressed: () => context.push('/password-reset'),
                child: const Text("I forgot my password"),

              ),
            ],
          )
      )
    );
  }
}