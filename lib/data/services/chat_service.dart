// lib/data/services/chat_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Dio _dio = Dio();
  final _uuid = const Uuid();

  Future<ChatModel> getOrCreateChat({
    required String jobId,
    required String jobTitle,
    required String clientId,
    required String clientName,
    String? clientPhotoUrl,
    required String workerId,
    required String workerName,
    String? workerPhotoUrl,
  }) async {
    // Check for existing chat
    final existing = await _firestore
        .collection(AppConstants.chatsCollection)
        .where('jobId', isEqualTo: jobId)
        .where('participantIds', arrayContains: clientId)
        .get();

    for (final doc in existing.docs) {
      final chat = ChatModel.fromMap(doc.data());
      if (chat.participantIds.contains(workerId)) return chat;
    }

    // Create new chat
    final chatId = _uuid.v4();
    final chat = ChatModel(
      id: chatId,
      jobId: jobId,
      jobTitle: jobTitle,
      participantIds: [clientId, workerId],
      participantNames: {clientId: clientName, workerId: workerName},
      participantPhotos: {clientId: clientPhotoUrl, workerId: workerPhotoUrl},
      unreadCounts: {clientId: 0, workerId: 0},
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .set(chat.toMap());

    return chat;
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChatModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String text,
    required String senderLanguage,
    String? imageUrl,
    String? jobReference,
    bool isSystemMessage = false,
  }) async {
    final msgId = _uuid.v4();
    final message = MessageModel(
      id: msgId,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderPhotoUrl: senderPhotoUrl,
      text: text,
      originalText: text,
      originalLanguage: senderLanguage,
      imageUrl: imageUrl,
      jobReference: jobReference,
      isSystemMessage: isSystemMessage,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();

    batch.set(
      _firestore
          .collection(AppConstants.chatsCollection)
          .doc(chatId)
          .collection(AppConstants.messagesCollection)
          .doc(msgId),
      message.toMap(),
    );

    // Update chat metadata
    batch.update(
      _firestore.collection(AppConstants.chatsCollection).doc(chatId),
      {
        'lastMessage': text,
        'lastMessageAt': Timestamp.now(),
      },
    );

    await batch.commit();
  }

  Future<String> uploadChatImage(String chatId, File image) async {
    final ref = _storage.ref('chats/$chatId/${_uuid.v4()}.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<String> translateText({
    required String text,
    required String targetLanguage,
    required String sourceLanguage,
  }) async {
    if (targetLanguage == sourceLanguage) return text;
    if (AppConstants.googleTranslateApiKey == 'YOUR_GOOGLE_TRANSLATE_API_KEY') {
      // Demo translation when API key not set
      return _demoTranslate(text, targetLanguage);
    }
    try {
      final response = await _dio.post(
        'https://translation.googleapis.com/language/translate/v2',
        queryParameters: {'key': AppConstants.googleTranslateApiKey},
        data: {
          'q': text,
          'source': sourceLanguage,
          'target': targetLanguage,
          'format': 'text',
        },
      );
      return response.data['data']['translations'][0]['translatedText'] as String;
    } catch (e) {
      return text;
    }
  }

  String _demoTranslate(String text, String targetLang) {
    // Demo translations for prototype
    final translations = {
      'Puedo llegar a las 3pm.': 'I can arrive at 3pm.',
      'El trabajo está casi terminado.': 'The work is almost done.',
      'Necesito más tiempo.': 'I need more time.',
      'Gracias por el trabajo.': 'Thank you for the job.',
      'I can arrive at 3pm.': 'Puedo llegar a las 3pm.',
      'The work is almost done.': 'El trabajo está casi terminado.',
    };
    return translations[text] ?? text;
  }

  Future<void> markMessagesRead(String chatId, String userId) async {
    await _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .update({'unreadCounts.$userId': 0});
  }
}
