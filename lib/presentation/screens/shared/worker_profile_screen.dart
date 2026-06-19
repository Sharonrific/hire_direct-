// lib/presentation/screens/shared/worker_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class WorkerProfileScreen extends ConsumerWidget {
  final String workerId;
  const WorkerProfileScreen({super.key, required this.workerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerFuture = ref.watch(authServiceProvider);

    return FutureBuilder(
      future: workerFuture.getUserById(workerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final worker = snapshot.data;
        if (worker == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Worker not found')));
        }

        final reviewsAsync = ref.watch(userReviewsProvider(workerId));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white, size: 18),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white24,
                          backgroundImage: worker.photoUrl != null
                              ? NetworkImage(worker.photoUrl!) : null,
                          child: worker.photoUrl == null
                              ? Text(worker.fullName.substring(0, 1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32, fontWeight: FontWeight.w700))
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(worker.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(worker.tradeTitle ?? 'General Worker',
                          style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rating + stats row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _Stat('Rating',
                              worker.rating > 0
                                  ? worker.rating.toStringAsFixed(1)
                                  : '—',
                              icon: Icons.star_rounded,
                              color: AppColors.warning),
                            _Divider(),
                            _Stat('Reviews',
                              '${worker.reviewCount}',
                              icon: Icons.reviews_outlined,
                              color: AppColors.primary),
                            _Divider(),
                            _Stat('Rate',
                              worker.hourlyRate != null
                                  ? '\$${worker.hourlyRate!.toStringAsFixed(0)}/hr'
                                  : 'Varies',
                              icon: Icons.attach_money_rounded,
                              color: AppColors.accent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating stars visual
                      if (worker.rating > 0)
                        Center(
                          child: RatingBarIndicator(
                            rating: worker.rating,
                            itemBuilder: (_, __) => const Icon(
                              Icons.star_rounded, color: AppColors.warning),
                            itemCount: 5,
                            itemSize: 20,
                          ),
                        ),
                      const SizedBox(height: 20),

                      // General labor badge
                      if (worker.availableForGeneralLabor == true)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle_rounded,
                                color: AppColors.accent, size: 18),
                              SizedBox(width: 8),
                              Text('Available for General Labor Jobs',
                                style: TextStyle(
                                  color: AppColors.accentDark,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                            ],
                          ),
                        ),

                      if (worker.bio != null && worker.bio!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('About', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(worker.bio!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14, height: 1.6)),
                      ],

                      if (worker.skills != null && worker.skills!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Skills & Specialties',
                          style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: worker.skills!.map((skill) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Text(skill,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                          )).toList(),
                        ),
                      ],

                      // Portfolio
                      if (worker.portfolioImages != null &&
                          worker.portfolioImages!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Portfolio',
                              style: Theme.of(context).textTheme.titleLarge),
                            TextButton(
                              onPressed: () => context.push('/gallery',
                                extra: {
                                  'images': worker.portfolioImages,
                                  'initialIndex': 0,
                                }),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: worker.portfolioImages!.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => context.push('/gallery',
                                extra: {
                                  'images': worker.portfolioImages,
                                  'initialIndex': i,
                                }),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  worker.portfolioImages![i],
                                  width: 100, height: 100, fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // Availability calendar
                      const SizedBox(height: 24),
                      Text('Availability',
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TableCalendar(
                          firstDay: DateTime.now(),
                          lastDay: DateTime.now().add(const Duration(days: 60)),
                          focusedDay: DateTime.now(),
                          calendarStyle: const CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              shape: BoxShape.circle),
                            todayTextStyle: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700),
                            selectedDecoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle),
                          ),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                        ),
                      ),

                      // Reviews preview
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reviews',
                            style: Theme.of(context).textTheme.titleLarge),
                          TextButton(
                            onPressed: () => context.push('/reviews/$workerId'),
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      reviewsAsync.when(
                        data: (reviews) {
                          if (reviews.isEmpty) {
                            return const Text('No reviews yet.',
                              style: TextStyle(color: AppColors.textSecondary));
                          }
                          return Column(
                            children: reviews.take(3).map((r) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _ReviewCard(review: r),
                              )
                            ).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(
                color: AppColors.shadow, blurRadius: 12,
                offset: Offset(0, -2))],
            ),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/post-job'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: AppColors.accent),
                    child: const Text('Hire This Worker',
                      style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, {required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
          style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label,
          style: const TextStyle(
            color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.border);
  }
}

class _ReviewCard extends StatelessWidget {
  final dynamic review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primarySurface,
                backgroundImage: review.reviewerPhotoUrl != null
                    ? NetworkImage(review.reviewerPhotoUrl!) : null,
                child: review.reviewerPhotoUrl == null
                    ? Text(review.reviewerName.substring(0, 1),
                        style: const TextStyle(fontSize: 10, color: AppColors.primary))
                    : null,
              ),
              const SizedBox(width: 8),
              Text(review.reviewerName,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              RatingBarIndicator(
                rating: review.rating.toDouble(),
                itemBuilder: (_, __) => const Icon(
                  Icons.star_rounded, color: AppColors.warning),
                itemCount: 5,
                itemSize: 14,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment,
            style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
