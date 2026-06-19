// lib/presentation/screens/worker/worker_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class WorkerShell extends ConsumerWidget {
  final Widget child;
  const WorkerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(workerNavIndexProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          ref.read(workerNavIndexProvider.notifier).state = i;
          switch (i) {
            case 0: context.go('/worker'); break;
            case 1: context.go('/worker/browse'); break;
            case 2: context.go('/chats'); break;
            case 3: {
              final user = ref.read(currentUserProvider).value;
              if (user != null) context.go('/reviews/${user.uid}');
            }
            case 4: context.go('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline_rounded),
            activeIcon: Icon(Icons.work_rounded),
            label: 'Browse Jobs'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Messages'),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_outline_rounded),
            activeIcon: Icon(Icons.star_rounded),
            label: 'Reviews'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile'),
        ],
      ),
    );
  }
}
