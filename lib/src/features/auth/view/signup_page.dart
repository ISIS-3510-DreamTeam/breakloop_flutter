import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodel/signup_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SignupViewModel>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              //  Logo
              Image.asset('assets/images/logo_name.png', width: 240, height: 180, fit: BoxFit.contain),
              const SizedBox(height: 20),

              // Title
              Text('SIGN UP', style: textTheme.headlineMedium),
              const SizedBox(height: 20),

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

                    // Fiel: password
                    Text('PASSWORD', style: textTheme.labelLarge),
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
                    const SizedBox(height: 20),

                    // Field: Confirm password
                    Text('CONFIRM PASSWORD', style: textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        filled: true,
                        fillColor: AppColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    if (vm.status == SignupStatus.error) ...[
                      const SizedBox(height: 12),
                      Text(vm.failure?.message ?? '', style: textTheme.bodyMedium?.copyWith(color: AppColors.spicyPaprika)),
                    ],

                    const SizedBox(height: 24),
                    AppButton(
                      label: 'REGISTER',
                      icon: Icons.person_add_alt,
                      loading: vm.status == SignupStatus.loading,
                      onPressed: () => context.read<SignupViewModel>().signUp(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                        _confirmPasswordController.text.trim(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Return to login
              GestureDetector(
                onTap: () => context.pop(),
                child: RichText(
                  text: TextSpan(
                    style: textTheme.bodyLarge?.copyWith(color: AppColors.darkCoffee),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(text: 'LOG IN', style: textTheme.labelLarge?.copyWith(color: AppColors.spicyPaprika, fontSize: 19)),
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