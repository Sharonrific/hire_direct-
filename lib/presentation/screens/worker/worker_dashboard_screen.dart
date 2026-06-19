// lib/presentation/screens/worker/worker_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';

class WorkerDashboardScreen extends ConsumerWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: userAsync.when(
                  data: (user) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white24,
                            backgroundImage: user?.photoUrl != null
                                ? NetworkImage(user!.photoUrl!)
                                : null,
                            child: user?.photoUrl == null
                                ? Text(
                                    user?.fullName.substring(0, 1) ?? 'W',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hi, ${user?.fullName.split(' ').first ?? 'Worker'}! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                              Text(user?.tradeTitle ?? 'General Worker',
                                style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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
                  // Earnings summary
                  _EarningsCard(),
                  const SizedBox(height: 24),

                  // Quick actions
                  Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _QuickAction(
                        icon: Icons.work_outline_rounded,
                        label: 'Browse Jobs',
                        color: AppColors.primary,
                        onTap: () => context.go('/worker/browse'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickAction(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'My Earnings',
                        color: AppColors.accent,
                        onTap: () => context.go('/worker/earnings'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: _QuickAction(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Messages',
                        color: AppColors.info,
                        onTap: () => context.go('/chats'),
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Active bookings
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Bookings', style: Theme.of(context).textTheme.titleLarge),
                      TextButton(
                        onPressed: () => context.go('/worker/browse'),
                        child: const Text('Browse More'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _WorkerBookingsSection(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.accentDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Earnings',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          const Text('\$0.00',
            style: TextStyle(
              color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              _EarningsStat('Jobs Done', '0'),
              const SizedBox(width: 24),
              _EarningsStat('This Month', '\$0'),
              const SizedBox(width: 24),
              _EarningsStat('Rating', '—'),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label, value;
  const _EarningsStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700)),
        Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label,
              style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _WorkerBookingsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final jobsAsync = ref.watch(workerJobsProvider(user.uid));
        return jobsAsync.when(
          data: (jobs) {
            final active = jobs.where((j) =>
              j.status != 'Posted' &&
              j.status != 'Payment Released' &&
              j.status != 'Cancelled'
            ).take(5).toList();

            if (active.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.work_off_outlined,
                      color: AppColors.textTertiary, size: 40),
                    const SizedBox(height: 8),
                    const Text('No active bookings yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => context.go('/worker/browse'),
                      child: const Text('Browse available jobs'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: active.map((job) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WorkerJobTile(job: job),
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

class _WorkerJobTile extends StatelessWidget {
  final dynamic job;
  const _WorkerJobTile({required this.job});

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
                  color: AppColors.accentSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline_rounded, color: AppColors.accent),
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
                  Text('Client: ${job.clientName}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('\$${job.budget.toStringAsFixed(0)} • ${job.status}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
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
