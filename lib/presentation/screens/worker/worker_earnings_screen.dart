// lib/presentation/screens/worker/worker_earnings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

class WorkerEarningsScreen extends ConsumerWidget {
  const WorkerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Earnings')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          final jobsAsync = ref.watch(workerJobsProvider(user.uid));
          return jobsAsync.when(
            data: (jobs) {
              final completed = jobs.where((j) =>
                j.status == AppConstants.statusCompleted ||
                j.status == AppConstants.statusPaymentReleased
              ).toList();

              final totalEarned = completed.fold(
                0.0, (sum, j) => sum + j.totalWithAddOns);

              final released = jobs.where((j) =>
                j.status == AppConstants.statusPaymentReleased).toList();
              final totalReleased = released.fold(
                0.0, (sum, j) => sum + j.totalWithAddOns);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earnings summary card
                    Container(
                      width: double.infinity,
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
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text('\$${totalEarned.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _Stat('Jobs Done', '${completed.length}'),
                              const SizedBox(width: 28),
                              _Stat('Released', '\$${totalReleased.toStringAsFixed(0)}'),
                              const SizedBox(width: 28),
                              _Stat('Pending', '\$${(totalEarned - totalReleased).toStringAsFixed(0)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    Text('Job History',
                      style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),

                    if (completed.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('No completed jobs yet.\nComplete your first job to see earnings here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ...completed.map((job) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
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
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentSurface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_circle_rounded,
                                    color: AppColors.accent, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(job.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 14),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Text(job.clientName,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('\$${job.totalWithAddOns.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: job.status == AppConstants.statusPaymentReleased
                                            ? AppColors.accentSurface
                                            : AppColors.warningSurface,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        job.status == AppConstants.statusPaymentReleased
                                            ? 'Paid'
                                            : 'Pending',
                                        style: TextStyle(
                                          color: job.status == AppConstants.statusPaymentReleased
                                              ? AppColors.accentDark
                                              : AppColors.warning,
                                          fontSize: 10, fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}
