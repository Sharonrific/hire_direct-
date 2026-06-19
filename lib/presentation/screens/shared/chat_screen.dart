// lib/presentation/screens/shared/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/models.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/chat_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String jobId;
  const ChatScreen({super.key, required this.chatId, required this.jobId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  bool _sending = false;
  // Track which messages are showing original
  final Set<String> _showingOriginal = {};

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    try {
      await ref.read(chatServiceProvider).sendMessage(
        chatId: widget.chatId,
        senderId: user.uid,
        senderName: user.fullName,
        senderPhotoUrl: user.photoUrl,
        text: text.isNotEmpty ? text : '📷 Photo',
        senderLanguage: user.preferredLanguage,
        imageUrl: imageUrl,
      );
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickAndSendImage() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final url = await ref.read(chatServiceProvider)
          .uploadChatImage(widget.chatId, File(picked.path));
      await _sendMessage(imageUrl: url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')));
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;
    final lang = ref.watch(chatLanguageProvider(widget.chatId));

    // Mark as read
    if (user != null) {
      ref.read(chatServiceProvider).markMessagesRead(widget.chatId, user.uid);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat', style: TextStyle(fontSize: 16)),
            if (widget.jobId.isNotEmpty)
              Text('Job #${widget.jobId.substring(0, 8)}',
                style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        actions: [
          // Language toggle
          _LanguageToggle(
            chatId: widget.chatId,
            currentLang: lang,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Translation notice banner
          if (lang == 'es')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.primarySurface,
              child: Row(
                children: const [
                  Icon(Icons.translate_rounded,
                    size: 14, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text('Messages auto-translated to Spanish',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                          size: 48, color: AppColors.textTertiary),
                        SizedBox(height: 12),
                        Text('No messages yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                        SizedBox(height: 4),
                        Text('Start the conversation!',
                          style: TextStyle(color: AppColors.textTertiary)),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == user?.uid;
                    final showDate = i == 0 ||
                        !_isSameDay(messages[i - 1].createdAt, msg.createdAt);

                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: msg.createdAt),
                        if (msg.isSystemMessage)
                          _SystemMessage(text: msg.text)
                        else
                          _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            displayLang: lang,
                            showingOriginal: _showingOriginal.contains(msg.id),
                            onToggleOriginal: () {
                              setState(() {
                                if (_showingOriginal.contains(msg.id)) {
                                  _showingOriginal.remove(msg.id);
                                } else {
                                  _showingOriginal.add(msg.id);
                                }
                              });
                            },
                          ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12, 8, 12, MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, -2),
              )],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo_outlined,
                    color: AppColors.textSecondary),
                  onPressed: _pickAndSendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: lang == 'es'
                          ? 'Escribe un mensaje...'
                          : 'Type a message...',
                      filled: true,
                      fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : () => _sendMessage(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _LanguageToggle extends ConsumerWidget {
  final String chatId, currentLang;
  const _LanguageToggle({required this.chatId, required this.currentLang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final newLang = currentLang == 'en' ? 'es' : 'en';
        ref.read(chatLanguageProvider(chatId).notifier).state = newLang;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate_rounded,
              size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              currentLang == 'en' ? 'EN' : 'ES',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12, fontWeight: FontWeight.w700)),
            const Icon(Icons.swap_horiz_rounded,
              size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String displayLang;
  final bool showingOriginal;
  final VoidCallback onToggleOriginal;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.displayLang,
    required this.showingOriginal,
    required this.onToggleOriginal,
  });

  bool get _isTranslated =>
      displayLang != message.originalLanguage &&
      message.text != message.originalText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primarySurface,
              backgroundImage: message.senderPhotoUrl != null
                  ? NetworkImage(message.senderPhotoUrl!)
                  : null,
              child: message.senderPhotoUrl == null
                  ? Text(message.senderName.substring(0, 1),
                      style: const TextStyle(
                        fontSize: 11, color: AppColors.primary,
                        fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(message.senderName.split(' ').first,
                      style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            message.imageUrl!,
                            width: 200, fit: BoxFit.cover,
                          ),
                        ),
                        if (message.text != '📷 Photo') const SizedBox(height: 6),
                      ],
                      if (message.text != '📷 Photo') ...[
                        Text(
                          showingOriginal
                              ? message.originalText
                              : message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : AppColors.textPrimary,
                            fontSize: 14, height: 1.4),
                        ),
                        if (_isTranslated) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: onToggleOriginal,
                            child: Text(
                              showingOriginal
                                  ? 'View Translation'
                                  : 'View Original',
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white70
                                    : AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Text(
                    DateFormat('h:mm a').format(message.createdAt),
                    style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final String text;
  const _SystemMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(text,
            style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12)),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year && date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
              style: const TextStyle(
                color: AppColors.textTertiary, fontSize: 11,
                fontWeight: FontWeight.w500)),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
