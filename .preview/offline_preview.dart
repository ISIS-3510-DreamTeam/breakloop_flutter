//Temporary entry point to preview the Offline views without signing in. It is deleted after the check
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:breakloop_flutter/src/app/theme.dart';
import 'package:breakloop_flutter/src/features/context_aware/view/offline_page.dart';
import 'package:breakloop_flutter/src/features/context_aware/view/activity_detail_page.dart';

void main() {
  final router = GoRouter(initialLocation: '/offline', routes: [
    GoRoute(path: '/offline', builder: (_, _) => const OfflinePage(), routes: [
      GoRoute(
        path: 'activity/:id',
        builder: (_, state) => ActivityDetailPage(
          activityId: state.pathParameters['id']!,
          fromSuggestion: state.uri.queryParameters['fromSuggestion'] == 'true',
        ),
      ),
    ]),
  ]);
  runApp(MaterialApp.router(routerConfig: router, theme: appTheme));
}
