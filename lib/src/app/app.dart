import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'router.dart';

import 'theme.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/viewmodel/login_viewmodel.dart';
import '../features/auth/viewmodel/signup_viewmodel.dart';
import '../features/auth/viewmodel/password_reset_viewmodel.dart';
import '../features/screen_time_progress/data/screen_time_repository.dart';
import '../features/screen_time_progress/data/mock_screen_time_repository.dart';
import '../features/screen_time_progress/data/usage_stats_screen_time_repository.dart';
import '../features/screen_time_progress/viewmodel/screen_time_progress_viewmodel.dart';

//Source of the screen-time data:
//false -> mock data (works on any device or emulator)
//true  -> real usage of the phone (asks the user for the PACKAGE_USAGE_STATS permission)
const bool useRealScreenTime = true;

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
        //Screen-time source, chosen with useRealScreenTime
        Provider<ScreenTimeRepository>(create: (_) {
          if (useRealScreenTime) {
            return UsageStatsScreenTimeRepository();
          } else {
            return MockScreenTimeRepository();
          }
        }),
        ChangeNotifierProvider(create: (ctx) => ScreenTimeProgressViewModel(ctx.read<ScreenTimeRepository>())..load()),
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
      theme: appTheme
    );
  }

}