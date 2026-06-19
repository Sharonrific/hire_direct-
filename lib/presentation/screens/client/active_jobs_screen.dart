// lib/presentation/screens/client/active_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

class ActiveJobsScreen extends ConsumerWidget {
  const ActiveJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Jobs')),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('Not logged in'));
          final jobsAsync = ref.watch(clientJobsProvider(user.uid));
          return jobsAsync.when(
            data: (jobs) {
              if (jobs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.work_off_outlined,
                        size: 56, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      const Text("You haven't posted any jobs yet",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.push('/post-job'),
                        child: const Text('Post a Job'),
                      ),
                    ],
                  ),
                );
              }

              // Group by status
              final statusOrder = [
                AppConstants.statusInProgress,
                AppConstants.statusAwaitingConfirmation,
                AppConstants.statusBooked,
                AppConstants.statusPosted,
                AppConstants.statusCompleted,
                AppConstants.statusPaymentReleased,
              ];

              final grouped = <String, List<dynamic>>{};
              for (final s in statusOrder) {
                final matching = jobs.where((j) => j.status == s).toList();
                if (matching.isNotEmpty) grouped[s] = matching;
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: grouped.entries.map((entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 4),
                      child: Text(entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textSecondary)),
                    ),
                    ...entry.value.map((job) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _JobCard(job: job),
                    )),
                    const SizedBox(height: 8),
                  ],
                )).toList(),
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

class _JobCard extends StatelessWidget {
  final dynamic job;
  const _JobCard({required this.job});

  Color _statusColor(String status) {
    switch (status) {
      case 'Posted': return AppColors.statusPosted;
      case 'Booked': return AppColors.statusBooked;
      case 'In Progress': return AppColors.statusInProgress;
      case 'Awaiting Confirmation': return AppColors.statusAwaiting;
      case 'Completed': return AppColors.statusCompleted;
      case 'Payment Released': return AppColors.statusReleased;
      default: return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (job.status == AppConstants.statusPosted) {
          context.push('/jobs/${job.id}');
        } else {
          context.push('/jobs/${job.id}/active');
        }
      },
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
                  width: 56, height: 56, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56, height: 56, color: AppColors.surfaceVariant),
                ),
              )
            else
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.work_outline_rounded,
                  color: AppColors.primary),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusColor(job.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)),
                        child: Text(job.status,
                          style: TextStyle(
                            color: _statusColor(job.status),
                            fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Text('\$${job.budget.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                  if (job.workerName != null) ...[
                    const SizedBox(height: 3),
                    Text('Worker: ${job.workerName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
