// lib/data/models/job_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String title;
  final String description;
  final String category;
  final double budget;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String paymentType; // 'escrow' or 'after_completion'
  final List<String> imageUrls;
  final String status;
  final String? workerID;
  final String? workerName;
  final String? workerPhotoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final double? escrowAmount;
  final String? stripePaymentIntentId;
  final bool appearsInGeneralLabor;
  final List<AddOnModel> addOns;

  JobModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    required this.location,
    this.latitude,
    this.longitude,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.paymentType,
    required this.imageUrls,
    required this.status,
    this.workerID,
    this.workerName,
    this.workerPhotoUrl,
    required this.createdAt,
    this.updatedAt,
    this.escrowAmount,
    this.stripePaymentIntentId,
    this.appearsInGeneralLabor = true,
    this.addOns = const [],
  });

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      id: map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? '',
      clientPhotoUrl: map['clientPhotoUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      budget: (map['budget'] as num?)?.toDouble() ?? 0.0,
      location: map['location'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      scheduledDate: (map['scheduledDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledTime: map['scheduledTime'] ?? '',
      paymentType: map['paymentType'] ?? 'after_completion',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      status: map['status'] ?? 'Posted',
      workerID: map['workerID'],
      workerName: map['workerName'],
      workerPhotoUrl: map['workerPhotoUrl'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      escrowAmount: (map['escrowAmount'] as num?)?.toDouble(),
      stripePaymentIntentId: map['stripePaymentIntentId'],
      appearsInGeneralLabor: map['appearsInGeneralLabor'] ?? true,
      addOns: (map['addOns'] as List<dynamic>? ?? [])
          .map((a) => AddOnModel.fromMap(a as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'clientPhotoUrl': clientPhotoUrl,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'scheduledTime': scheduledTime,
      'paymentType': paymentType,
      'imageUrls': imageUrls,
      'status': status,
      'workerID': workerID,
      'workerName': workerName,
      'workerPhotoUrl': workerPhotoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'escrowAmount': escrowAmount,
      'stripePaymentIntentId': stripePaymentIntentId,
      'appearsInGeneralLabor': appearsInGeneralLabor,
      'addOns': addOns.map((a) => a.toMap()).toList(),
    };
  }

  JobModel copyWith({
    String? id, String? clientId, String? clientName, String? clientPhotoUrl,
    String? title, String? description, String? category, double? budget,
    String? location, double? latitude, double? longitude,
    DateTime? scheduledDate, String? scheduledTime, String? paymentType,
    List<String>? imageUrls, String? status, String? workerID,
    String? workerName, String? workerPhotoUrl, DateTime? createdAt,
    DateTime? updatedAt, double? escrowAmount, String? stripePaymentIntentId,
    bool? appearsInGeneralLabor, List<AddOnModel>? addOns,
  }) {
    return JobModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      clientPhotoUrl: clientPhotoUrl ?? this.clientPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      paymentType: paymentType ?? this.paymentType,
      imageUrls: imageUrls ?? this.imageUrls,
      status: status ?? this.status,
      workerID: workerID ?? this.workerID,
      workerName: workerName ?? this.workerName,
      workerPhotoUrl: workerPhotoUrl ?? this.workerPhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      escrowAmount: escrowAmount ?? this.escrowAmount,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      appearsInGeneralLabor: appearsInGeneralLabor ?? this.appearsInGeneralLabor,
      addOns: addOns ?? this.addOns,
    );
  }

  double get totalWithAddOns {
    double total = budget;
    for (final addOn in addOns) {
      if (addOn.status == 'approved') total += addOn.price;
    }
    return total;
  }
}

class AddOnModel {
  final String id;
  final String jobId;
  final String workerId;
  final String description;
  final double price;
  final String status; // 'pending', 'approved', 'declined'
  final DateTime createdAt;
  final String? stripePaymentIntentId;

  AddOnModel({
    required this.id,
    required this.jobId,
    required this.workerId,
    required this.description,
    required this.price,
    required this.status,
    required this.createdAt,
    this.stripePaymentIntentId,
  });

  factory AddOnModel.fromMap(Map<String, dynamic> map) {
    return AddOnModel(
      id: map['id'] ?? '',
      jobId: map['jobId'] ?? '',
      workerId: map['workerId'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stripePaymentIntentId: map['stripePaymentIntentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobId': jobId,
      'workerId': workerId,
      'description': description,
      'price': price,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'stripePaymentIntentId': stripePaymentIntentId,
    };
  }
}
