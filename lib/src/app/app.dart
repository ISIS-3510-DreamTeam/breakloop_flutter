
//DEPRECATED

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'router.dart';


import '../features/auth/data/auth_repository.dart';
import '../features/auth/viewmodel/login_viewmodel.dart';
import '../features/auth/viewmodel/signup_viewmodel.dart';
import '../features/auth/viewmodel/password_reset_viewmodel.dart';

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
      child: const _RouterApp(),
    );
  }
}

class _RouterApp extends StatefulWidget {
  const _RouterApp();

  @override
  State<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends State<_RouterApp> {
  late final GoRouter _router;

  @override
  void initState(){
    super.initState();
    _router = buildRouter(context.read<AuthRepository>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'BreakLoop App',
      //TODO: Configure the app theme
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple)
    );
  }

}