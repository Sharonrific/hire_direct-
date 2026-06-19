// lib/presentation/screens/shared/review_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String jobId, revieweeId, revieweeName;
  const ReviewScreen({
    super.key,
    required this.jobId,
    required this.revieweeId,
    required this.revieweeName,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  double _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')));
      return;
    }
    if (_commentCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write at least 10 characters')));
      return;
    }

    setState(() => _loading = true);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      await ref.read(reviewServiceProvider).submitReview(
        jobId: widget.jobId,
        reviewerId: user.uid,
        reviewerName: user.fullName,
        reviewerPhotoUrl: user.photoUrl,
        revieweeId: widget.revieweeId,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted! Thank you.'),
          backgroundColor: AppColors.accent));

      context.go('/client');
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_rounded,
                color: AppColors.warning, size: 38),
            ),
            const SizedBox(height: 16),
            Text('How was your experience?',
              style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('with ${widget.revieweeName}',
              style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 28),

            RatingBar.builder(
              initialRating: _rating,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemSize: 48,
              itemBuilder: (_, __) => const Icon(
                Icons.star_rounded, color: AppColors.warning),
              onRatingUpdate: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 12),
            Text(
              _rating == 0 ? 'Tap to rate'
                : _rating == 1 ? 'Poor'
                : _rating == 2 ? 'Fair'
                : _rating == 3 ? 'Good'
                : _rating == 4 ? 'Very Good'
                : 'Excellent!',
              style: TextStyle(
                color: _rating == 0 ? AppColors.textTertiary : AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 16),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _commentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Share your experience... Was the worker professional? '
                    'Did they complete the job as expected?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/presentation/screens/shared/reviews_list_screen.dart
class ReviewsListScreen extends ConsumerWidget {
  final String userId;
  const ReviewsListScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(userReviewsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: reviewsAsync.when(
        data: (reviews) {
          if (reviews.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border_rounded,
                    size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text('No reviews yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final r = reviews[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primarySurface,
                          backgroundImage: r.reviewerPhotoUrl != null
                              ? NetworkImage(r.reviewerPhotoUrl!) : null,
                          child: r.reviewerPhotoUrl == null
                              ? Text(r.reviewerName.substring(0, 1),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.reviewerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                            RatingBarIndicator(
                              rating: r.rating.toDouble(),
                              itemBuilder: (_, __) => const Icon(
                                Icons.star_rounded, color: AppColors.warning),
                              itemCount: 5, itemSize: 14),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '${r.createdAt.month}/${r.createdAt.day}/${r.createdAt.year}',
                          style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(r.comment,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13, height: 1.5)),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
