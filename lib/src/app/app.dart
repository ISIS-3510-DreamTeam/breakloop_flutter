// app/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/viewmodel/login_viewmodel.dart';
import '../features/auth/viewmodel/signup_viewmodel.dart';
import '../features/auth/viewmodel/password_reset_viewmodel.dart';
import '../features/auth/view/auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthRepository()),
        ChangeNotifierProvider(create: (ctx) => LoginViewModel(ctx.read<AuthRepository>())),
        ChangeNotifierProvider(create: (ctx) => SignupViewModel(ctx.read<AuthRepository>())),
        ChangeNotifierProvider(create: (ctx) => PasswordResetViewModel(ctx.read<AuthRepository>())),
      ],
      child: MaterialApp(
        title: 'Screen Time App',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
        home: const AuthGate(),
      ),
    );
  }
}