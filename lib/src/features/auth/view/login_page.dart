import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/login_viewmodel.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Logo
              Image.asset('assets/images/logo_name.png', width: 240, height: 180, fit: BoxFit.contain),
              const SizedBox(height: 24),

              // Title
              Text('LOG IN', style: textTheme.headlineMedium),
              const SizedBox(height: 24),

              // Form
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field: e-mail
                    Text('E-MAIL', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'you@mail.com',
                        prefixIcon: const Icon(Icons.mail_outline, size: 20),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Field: password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PASSWORD', style: textTheme.labelLarge),
                        GestureDetector(
                          onTap: () => context.push('/password-reset'),
                          child: Text(
                            'Forgot your password?',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.spicyPaprika,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    if (vm.status == LoginStatus.error) ...[
                      const SizedBox(height: 12),
                      Text(vm.failure?.message ?? '', style: textTheme.bodyMedium?.copyWith(color: AppColors.spicyPaprika)),
                    ],

                    // Enter Button
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'ENTER',
                      icon: Icons.login,
                      loading: vm.status == LoginStatus.loading,
                      onPressed: () => context.read<LoginViewModel>().login(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign up
              GestureDetector(
                onTap: () => context.push('/signup'),
                child: RichText(
                  text: TextSpan(
                    style: textTheme.bodyLarge?.copyWith(color: AppColors.darkCoffee),
                    children: [
                      const TextSpan(text: "Don't have an account yet? "),
                      TextSpan(text: 'SIGN UP', style: textTheme.labelLarge?.copyWith(color: AppColors.spicyPaprika, fontSize: 19)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}