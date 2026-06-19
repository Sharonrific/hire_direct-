// lib/data/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String workerId;
  final String workerName;
  final String? workerPhotoUrl;
  final double commitmentFee;
  final String? clientCommitmentPaymentId;
  final String? workerCommitmentPaymentId;
  final bool clientPaid;
  final bool workerPaid;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BookingModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.workerId,
    required this.workerName,
    this.workerPhotoUrl,
    required this.commitmentFee,
    this.clientCommitmentPaymentId,
    this.workerCommitmentPaymentId,
    this.clientPaid = false,
    this.workerPaid = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] ?? '',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhotoUrl: map['clientPhotoUrl'],
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      workerPhotoUrl: map['workerPhotoUrl'],
      commitmentFee: (map['commitmentFee'] as num?)?.toDouble() ?? 20.0,
      clientCommitmentPaymentId: map['clientCommitmentPaymentId'],
      workerCommitmentPaymentId: map['workerCommitmentPaymentId'],
      clientPaid: map['clientPaid'] ?? false,
      workerPaid: map['workerPaid'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'jobId': jobId, 'jobTitle': jobTitle,
    'clientId': clientId, 'clientName': clientName,
    'clientPhotoUrl': clientPhotoUrl, 'workerId': workerId,
    'workerName': workerName, 'workerPhotoUrl': workerPhotoUrl,
    'commitmentFee': commitmentFee,
    'clientCommitmentPaymentId': clientCommitmentPaymentId,
    'workerCommitmentPaymentId': workerCommitmentPaymentId,
    'clientPaid': clientPaid, 'workerPaid': workerPaid,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };
}

// lib/data/models/review_model.dart
class ReviewModel {
  final String id;
  final String jobId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final String revieweeId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.jobId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      jobId: map['jobId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      reviewerName: map['reviewerName'] ?? '',
      reviewerPhotoUrl: map['reviewerPhotoUrl'],
      revieweeId: map['revieweeId'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'jobId': jobId, 'reviewerId': reviewerId,
    'reviewerName': reviewerName, 'reviewerPhotoUrl': reviewerPhotoUrl,
    'revieweeId': revieweeId, 'rating': rating, 'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

// lib/data/models/message_model.dart
class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String text;
  final String originalText;
  final String originalLanguage;
  final String? imageUrl;
  final String? jobReference;
  final bool isSystemMessage;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.text,
    required this.originalText,
    required this.originalLanguage,
    this.imageUrl,
    this.jobReference,
    this.isSystemMessage = false,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      text: map['text'] ?? '',
      originalText: map['originalText'] ?? '',
      originalLanguage: map['originalLanguage'] ?? 'en',
      imageUrl: map['imageUrl'],
      jobReference: map['jobReference'],
      isSystemMessage: map['isSystemMessage'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'chatId': chatId, 'senderId': senderId,
    'senderName': senderName, 'senderPhotoUrl': senderPhotoUrl,
    'text': text, 'originalText': originalText,
    'originalLanguage': originalLanguage,
    'imageUrl': imageUrl, 'jobReference': jobReference,
    'isSystemMessage': isSystemMessage,
    'createdAt': Timestamp.fromDate(createdAt),
    'isRead': isRead,
  };
}

// lib/data/models/chat_model.dart
class ChatModel {
  final String id;
  final String jobId;
  final String jobTitle;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;

  ChatModel({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCounts,
    required this.createdAt,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      jobId: map['jobId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(map['participantPhotos'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'jobId': jobId, 'jobTitle': jobTitle,
    'participantIds': participantIds, 'participantNames': participantNames,
    'participantPhotos': participantPhotos,
    'lastMessage': lastMessage,
    'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
    'unreadCounts': unreadCounts,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
