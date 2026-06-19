// lib/presentation/screens/client/client_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class ClientShell extends ConsumerWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  static const _tabs = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.search_outlined, 'activeIcon': Icons.search_rounded, 'label': 'Search'},
    {'icon': Icons.chat_bubble_outline_rounded, 'activeIcon': Icons.chat_bubble_rounded, 'label': 'Messages'},
    {'icon': Icons.star_outline_rounded, 'activeIcon': Icons.star_rounded, 'label': 'Reviews'},
    {'icon': Icons.person_outline_rounded, 'activeIcon': Icons.person_rounded, 'label': 'Profile'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(clientNavIndexProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          ref.read(clientNavIndexProvider.notifier).state = i;
          switch (i) {
            case 0: context.go('/client'); break;
            case 1: context.go('/search'); break;
            case 2: context.go('/chats'); break;
            case 3: {
              final user = ref.read(currentUserProvider).value;
              if (user != null) context.go('/reviews/${user.uid}');
            }
            case 4: context.go('/profile'); break;
          }
        },
        items: _tabs.map((tab) => BottomNavigationBarItem(
          icon: Icon(tab['icon'] as IconData),
          activeIcon: Icon(tab['activeIcon'] as IconData),
          label: tab['label'] as String,
        )).toList(),
      ),
    );
  }
}
