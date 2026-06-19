// lib/presentation/screens/shared/chats_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          final chatsAsync = ref.watch(userChatsProvider(user.uid));
          return chatsAsync.when(
            data: (chats) {
              if (chats.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                        size: 56, color: AppColors.textTertiary),
                      SizedBox(height: 12),
                      Text('No conversations yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600, fontSize: 16)),
                      SizedBox(height: 4),
                      Text('Messages will appear here',
                        style: TextStyle(color: AppColors.textTertiary)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final chat = chats[i];
                  final otherId = chat.participantIds
                      .firstWhere((id) => id != user.uid, orElse: () => user.uid);
                  final otherName = chat.participantNames[otherId] ?? 'Unknown';
                  final otherPhoto = chat.participantPhotos[otherId];
                  final unread = chat.unreadCounts[user.uid] ?? 0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primarySurface,
                      backgroundImage: otherPhoto != null
                          ? NetworkImage(otherPhoto) : null,
                      child: otherPhoto == null
                          ? Text(otherName.substring(0, 1),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700, fontSize: 16))
                          : null,
                    ),
                    title: Text(otherName,
                      style: TextStyle(
                        fontWeight: unread > 0
                            ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chat.jobTitle,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11, fontWeight: FontWeight.w500)),
                        if (chat.lastMessage != null)
                          Text(chat.lastMessage!,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unread > 0
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 13)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (chat.lastMessageAt != null)
                          Text(
                            DateFormat('h:mm a').format(chat.lastMessageAt!),
                            style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 11)),
                        const SizedBox(height: 4),
                        if (unread > 0)
                          Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                            child: Center(
                              child: Text('$unread',
                                style: const TextStyle(
                                  color: Colors.white, fontSize: 10,
                                  fontWeight: FontWeight.w700))),
                          ),
                      ],
                    ),
                    onTap: () => context.push('/chats/${chat.id}?jobId=${chat.jobId}'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
