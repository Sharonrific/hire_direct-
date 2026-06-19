// lib/data/services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../../core/constants/app_constants.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<ReviewModel> submitReview({
    required String jobId,
    required String reviewerId,
    required String reviewerName,
    String? reviewerPhotoUrl,
    required String revieweeId,
    required double rating,
    required String comment,
  }) async {
    final reviewId = _uuid.v4();
    final review = ReviewModel(
      id: reviewId,
      jobId: jobId,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerPhotoUrl: reviewerPhotoUrl,
      revieweeId: revieweeId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection(AppConstants.reviewsCollection)
        .doc(reviewId)
        .set(review.toMap());

    // Update user's average rating
    await _updateUserRating(revieweeId);

    return review;
  }

  Future<void> _updateUserRating(String userId) async {
    final snap = await _firestore
        .collection(AppConstants.reviewsCollection)
        .where('revieweeId', isEqualTo: userId)
        .get();

    if (snap.docs.isEmpty) return;

    final reviews = snap.docs
        .map((d) => ReviewModel.fromMap(d.data()))
        .toList();

    final avg = reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length;

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'rating': avg, 'reviewCount': reviews.length});
  }

  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection(AppConstants.reviewsCollection)
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReviewModel.fromMap(d.data()))
            .toList());
  }

  Future<bool> hasReviewed(String jobId, String reviewerId) async {
    final snap = await _firestore
        .collection(AppConstants.reviewsCollection)
        .where('jobId', isEqualTo: jobId)
        .where('reviewerId', isEqualTo: reviewerId)
        .get();
    return snap.docs.isNotEmpty;
  }
}
