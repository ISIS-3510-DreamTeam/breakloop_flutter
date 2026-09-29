import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/password_reset_viewmodel.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  State<PasswordResetPage> createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PasswordResetViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recover password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (vm.status == ResetStatus.success) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              const Text('Check your e-mail to recover your password.'),
            ] else ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              if (vm.status == ResetStatus.error)
                Text(vm.failure?.message ?? '', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              vm.status == ResetStatus.loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: () => context
                    .read<PasswordResetViewModel>()
                    .sendResetEmail(_emailController.text.trim()),
                child: const Text('Send link'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}