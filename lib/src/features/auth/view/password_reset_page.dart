import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/password_reset_viewmodel.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Stack(
            children: [
              // Back button
              Positioned(
                left: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.darkCoffee),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Column(
                children: [
                  // Logo
                  Image.asset('assets/images/logo_name.png', width: 240, height: 180, fit: BoxFit.contain),
                  const SizedBox(height: 20),

                  // Title
                  Text('RECOVER PASSWORD', style: textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 20),

                  // Card
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: vm.status == ResetStatus.success
                        ? _SuccessContent(textTheme: textTheme)
                        : _FormContent(
                      emailController: _emailController,
                      vm: vm,
                      textTheme: textTheme,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _FormContent extends StatelessWidget {
  final TextEditingController emailController;
  final PasswordResetViewModel vm;
  final TextTheme textTheme;

  const _FormContent({
    required this.emailController,
    required this.vm,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Enter your email and we'll send you a link to reset your password.",
          style: textTheme.bodyMedium?.copyWith(color: AppColors.darkCoffee.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 20),

        Text('EMAIL', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
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

        if (vm.status == ResetStatus.error) ...[
          const SizedBox(height: 12),
          Text(vm.failure?.message ?? '', style: textTheme.bodyMedium?.copyWith(color: AppColors.spicyPaprika)),
        ],

        const SizedBox(height: 24),
        AppButton(
          label: 'SEND LINK',
          icon: Icons.send_outlined,
          loading: vm.status == ResetStatus.loading,
          onPressed: () => context
              .read<PasswordResetViewModel>()
              .sendResetEmail(emailController.text.trim()),
        ),
      ],
    );
  }
}

class _SuccessContent extends StatelessWidget {
  final TextTheme textTheme;
  const _SuccessContent({required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, color: AppColors.fern, size: 48),
        const SizedBox(height: 16),
        Text('CHECK YOUR EMAIL', style: textTheme.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          "We've sent a link to recover your password.",
          style: textTheme.bodyMedium?.copyWith(color: AppColors.darkCoffee.withValues(alpha: 0.7)),
          textAlign: TextAlign.center,
        ),
        // Refresh the page on demand in case there was any error on the email input, otherwise it is preserved.
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => context.read<PasswordResetViewModel>().reset(),
          child: Text(
            'Use a different e-mail',
            style: textTheme.labelLarge?.copyWith(color: AppColors.spicyPaprika)
          )
        )
      ],
    );
  }
}