import 'package:flutter/material.dart';
import 'package:flutter_geo_poc/screens/home_page_screen.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(MaterialApp.router(
    routerConfig: router, 
    title: 'Flutter Demo', 
    theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),));
}

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const HomePageScreen(),
      routes: const [],
    ),
  ],
);