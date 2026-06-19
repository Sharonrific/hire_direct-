// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserType { client, worker }

class UserModel {
  final String uid;
  final String email;
  final String phone;
  final String fullName;
  final String? photoUrl;
  final UserType userType;
  final String preferredLanguage;
  final String? bio;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  // Worker specific
  final String? tradeTitle;
  final List<String>? skills;
  final double? hourlyRate;
  final bool? availableForGeneralLabor;
  final List<String>? portfolioImages;
  final Map<String, bool>? weeklyAvailability;

  UserModel({
    required this.uid,
    required this.email,
    required this.phone,
    required this.fullName,
    this.photoUrl,
    required this.userType,
    required this.preferredLanguage,
    this.bio,
    this.location,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.tradeTitle,
    this.skills,
    this.hourlyRate,
    this.availableForGeneralLabor,
    this.portfolioImages,
    this.weeklyAvailability,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      fullName: map['fullName'] ?? '',
      photoUrl: map['photoUrl'],
      userType: map['userType'] == 'worker' ? UserType.worker : UserType.client,
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      bio: map['bio'],
      location: map['location'],
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      tradeTitle: map['tradeTitle'],
      skills: List<String>.from(map['skills'] ?? []),
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble(),
      availableForGeneralLabor: map['availableForGeneralLabor'],
      portfolioImages: List<String>.from(map['portfolioImages'] ?? []),
      weeklyAvailability: Map<String, bool>.from(map['weeklyAvailability'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'userType': userType == UserType.worker ? 'worker' : 'client',
      'preferredLanguage': preferredLanguage,
      'bio': bio,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
      'tradeTitle': tradeTitle,
      'skills': skills,
      'hourlyRate': hourlyRate,
      'availableForGeneralLabor': availableForGeneralLabor,
      'portfolioImages': portfolioImages,
      'weeklyAvailability': weeklyAvailability,
    };
  }

  UserModel copyWith({
    String? uid, String? email, String? phone, String? fullName,
    String? photoUrl, UserType? userType, String? preferredLanguage,
    String? bio, String? location, double? latitude, double? longitude,
    DateTime? createdAt, bool? isVerified, double? rating, int? reviewCount,
    String? tradeTitle, List<String>? skills, double? hourlyRate,
    bool? availableForGeneralLabor, List<String>? portfolioImages,
    Map<String, bool>? weeklyAvailability,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      userType: userType ?? this.userType,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      tradeTitle: tradeTitle ?? this.tradeTitle,
      skills: skills ?? this.skills,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availableForGeneralLabor: availableForGeneralLabor ?? this.availableForGeneralLabor,
      portfolioImages: portfolioImages ?? this.portfolioImages,
      weeklyAvailability: weeklyAvailability ?? this.weeklyAvailability,
    );
  }
}
