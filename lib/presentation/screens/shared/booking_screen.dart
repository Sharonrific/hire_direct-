// lib/presentation/screens/shared/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../data/services/payment_service.dart';
import '../../../data/services/job_service.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String jobId;
  const BookingScreen({super.key, required this.jobId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  bool _agreed = false;
  bool _loading = false;

  Future<void> _confirmBooking() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the commitment fee terms')));
      return;
    }

    setState(() => _loading = true);

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      // Charge commitment fee
      final result = await ref.read(paymentServiceProvider).chargeCommitmentFee(
        userId: user.uid,
        jobId: widget.jobId,
        userType: 'worker',
      );

      if (!mounted) return;

      if (result.success) {
        // Assign worker to job
        final job = await ref.read(jobServiceProvider).getJobById(widget.jobId);
        if (job != null) {
          await ref.read(jobServiceProvider).assignWorker(
            widget.jobId, user.uid, user.fullName, user.photoUrl);
        }

        if (!mounted) return;
        context.go('/jobs/${widget.jobId}/active');
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Payment failed')));
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book This Job'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) return const Center(child: Text('Job not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      if (job.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            job.imageUrls.first,
                            width: 64, height: 64, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64, height: 64, color: AppColors.surfaceVariant),
                          ),
                        )
                      else
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.work_outline_rounded,
                            color: AppColors.primary),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(job.location,
                              style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('\$${job.budget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text('Commitment Fee',
                  style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text(
                  'To book this job, both you and the client pay a \$20 commitment fee.',
                  style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),

                // How it works
                _HowItWorksCard(),
                const SizedBox(height: 20),

                // Fee breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _FeeRow('Job Budget', '\$${job.budget.toStringAsFixed(0)}'),
                      const Divider(height: 20),
                      _FeeRow('Your Commitment Fee',
                        '\$${AppConstants.commitmentFee.toStringAsFixed(0)}',
                        highlight: true),
                      const SizedBox(height: 4),
                      const Text(
                        '* Refunded or applied to your payment if both parties show up',
                        style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Agreement checkbox
                GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreed,
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'I agree to the commitment fee terms. I understand that if I fail to show up, '
                            'the client receives my \$20 fee.',
                            style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent),
                    child: _loading
                        ? const SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Pay \$${AppConstants.commitmentFee.toStringAsFixed(0)} & Book Job',
                            style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('How Commitment Protection Works',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),
          _Step(
            icon: Icons.check_circle_rounded,
            color: AppColors.accent,
            title: 'Both show up',
            desc: '\$20 fee is refunded or applied toward the job cost',
          ),
          const SizedBox(height: 10),
          _Step(
            icon: Icons.cancel_rounded,
            color: AppColors.error,
            title: 'Client is a no-show',
            desc: 'You receive the client\'s \$20 for your time',
          ),
          const SizedBox(height: 10),
          _Step(
            icon: Icons.cancel_rounded,
            color: AppColors.warning,
            title: 'You are a no-show',
            desc: 'Client receives your \$20 for their inconvenience',
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, desc;
  const _Step({required this.icon, required this.color,
    required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
              Text(desc,
                style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label, value;
  final bool highlight;
  const _FeeRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: TextStyle(
            color: highlight ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14)),
        Text(value,
          style: TextStyle(
            color: highlight ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }
}
