import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_strings.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_outline),
            activeIcon: Icon(Icons.favorite),
            label: AppStrings.home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: AppStrings.names,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: AppStrings.journal,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/names')) return 1;
    if (location.startsWith('/journal')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/');
      case 1:
        context.go('/names');
      case 2:
        context.go('/journal');
      case 3:
        context.go('/settings');
    }
  }
}
