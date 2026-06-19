// lib/presentation/screens/client/client_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 130,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: userAsync.when(
                  data: (user) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.fullName.split(' ').first ?? 'there'} 👋',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'What do you need help with today?',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post a Job CTA
                  _PostJobCard(onTap: () => context.push('/post-job')),
                  const SizedBox(height: 24),

                  // Quick actions
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  _QuickActionsGrid(),
                  const SizedBox(height: 24),

                  // Active Jobs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Active Jobs', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.push('/client/active-jobs'),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ActiveJobsSection(),
                  const SizedBox(height: 24),

                  // Browse Categories
                  Text('Browse Categories', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  _CategoriesGrid(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post-job'),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Post a Job',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _PostJobCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PostJobCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need Something Done?',
                    style: TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Post a job and get quotes from skilled workers near you.',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Post a Job →',
                      style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      {'icon': Icons.work_outline_rounded, 'label': 'Post Job', 'color': AppColors.primary,
       'route': '/post-job'},
      {'icon': Icons.assignment_outlined, 'label': 'Active Jobs', 'color': AppColors.warning,
       'route': '/client/active-jobs'},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Messages', 'color': AppColors.info,
       'route': '/chats'},
      {'icon': Icons.person_search_rounded, 'label': 'Find Worker', 'color': AppColors.accent,
       'route': '/search'},
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      children: actions.map((a) => GestureDetector(
        onTap: () => context.push(a['route'] as String),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: (a['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(a['icon'] as IconData, color: a['color'] as Color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(a['label'] as String,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          ],
        ),
      )).toList(),
    );
  }
}

class _ActiveJobsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final jobsAsync = ref.watch(clientJobsProvider(user.uid));
        return jobsAsync.when(
          data: (jobs) {
            final active = jobs.where((j) =>
              j.status != 'Posted' &&
              j.status != 'Payment Released' &&
              j.status != 'Cancelled'
            ).take(3).toList();

            if (active.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('No active jobs yet. Post your first job!',
                    style: TextStyle(color: AppColors.textSecondary)),
                ),
              );
            }

            return Column(
              children: active.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActiveJobTile(job: job),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ActiveJobTile extends StatelessWidget {
  final dynamic job;
  const _ActiveJobTile({required this.job});

  Color _statusColor(String status) {
    switch (status) {
      case 'Booked': return AppColors.statusBooked;
      case 'In Progress': return AppColors.statusInProgress;
      case 'Awaiting Confirmation': return AppColors.statusAwaiting;
      case 'Completed': return AppColors.statusCompleted;
      default: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}/active'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            if (job.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  job.imageUrls.first,
                  width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52, height: 52, color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_outlined, color: AppColors.textTertiary),
                  ),
                ),
              )
            else
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline_rounded, color: AppColors.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(job.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(job.status,
                          style: TextStyle(
                            color: _statusColor(job.status),
                            fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text('\$${job.budget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _CategoriesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> _categories = const [
    {'icon': Icons.grass_rounded, 'label': 'Lawn & Garden', 'color': Color(0xFF16a34a)},
    {'icon': Icons.plumbing_rounded, 'label': 'Plumbing', 'color': Color(0xFF0891b2)},
    {'icon': Icons.electrical_services_rounded, 'label': 'Electrical', 'color': Color(0xFFd97706)},
    {'icon': Icons.carpenter_rounded, 'label': 'Carpentry', 'color': Color(0xFF92400e)},
    {'icon': Icons.format_paint_rounded, 'label': 'Painting', 'color': Color(0xFF7c3aed)},
    {'icon': Icons.cleaning_services_rounded, 'label': 'Cleaning', 'color': Color(0xFF0e7490)},
    {'icon': Icons.local_shipping_rounded, 'label': 'Moving', 'color': Color(0xFFdc2626)},
    {'icon': Icons.handyman_rounded, 'label': 'Handyman', 'color': Color(0xFF1e3a8a)},
    {'icon': Icons.ac_unit_rounded, 'label': 'HVAC', 'color': Color(0xFF0284c7)},
    {'icon': Icons.people_rounded, 'label': 'General Labor', 'color': Color(0xFF059669)},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 16,
      childAspectRatio: 0.75,
      children: _categories.map((cat) => GestureDetector(
        onTap: () => context.push('/search?category=${cat['label']}'),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (cat['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 26),
            ),
            const SizedBox(height: 5),
            Text(cat['label'] as String,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      )).toList(),
    );
  }
}
