import 'package:go_router/go_router.dart';
import '../core/navigation/auth_refresh_stream.dart';
import '../core/navigation/splash_page.dart';
import '../core/navigation/main_shell.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/signup_page.dart';
import '../features/auth/view/password_reset_page.dart';
//Add here additional routes
import '../core/navigation/home_placeholder_page.dart';


GoRouter buildRouter(AuthRepository authRepository) {
  final authRefresh = GoRouterRefreshStream(authRepository.authStateChange);
  const publicRoutes = ['/login', '/signup', '/password-reset'];

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authRefresh,
    //With this we check if we need to redirect the user elsewhere due to auth issues
    redirect: (context, state) {
      final location = state.matchedLocation;

      //If firebase has not yet confirmed the user session we show a loading view
      if (!authRefresh.initialized){
        return location == '/splash' ? null : '/splash';
      }

      //We check if the user loggedIn
      final loggedIn = authRepository.currentUser != null;

      //Once firebase loads, if the user is logged in, we send him to Home view, else we send him to log in view
      if (location == '/splash') {
        return loggedIn ? '/home' : '/login';
      }

      final isPublicRoute = publicRoutes.contains(location);

      //We check that the user must be logged in to access the full views of the app
      if (!loggedIn && !isPublicRoute) return '/login';
      if (loggedIn && isPublicRoute) return '/home';

      //In case no redirection is needed
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupPage()),
      GoRoute(path: '/password-reset', builder: (_, _) => const PasswordResetPage()),

      StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomePlaceholderPage()),
            ])

            //add here all other branches accessed by the navBar
          ]
      )

    ]);
}