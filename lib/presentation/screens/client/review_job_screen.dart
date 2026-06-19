// lib/presentation/screens/client/review_job_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../data/services/job_service.dart';

class ReviewJobScreen extends ConsumerStatefulWidget {
  const ReviewJobScreen({super.key});

  @override
  ConsumerState<ReviewJobScreen> createState() => _ReviewJobScreenState();
}

class _ReviewJobScreenState extends ConsumerState<ReviewJobScreen> {
  bool _loading = false;

  Future<void> _postJob() async {
    setState(() => _loading = true);

    final state = ref.read(jobPostingProvider);
    final user = ref.read(currentUserProvider).value;

    if (user == null) return;

    try {
      final job = await ref.read(jobServiceProvider).createJob(
        clientId: user.uid,
        clientName: user.fullName,
        clientPhotoUrl: user.photoUrl,
        title: state.title,
        description: state.description,
        category: state.category,
        budget: state.budget,
        location: state.location,
        latitude: state.latitude,
        longitude: state.longitude,
        scheduledDate: state.scheduledDate!,
        scheduledTime: state.scheduledTime,
        paymentType: state.paymentType,
        images: state.images.whereType<File>().toList(),
      );

      ref.read(jobPostingProvider.notifier).reset();

      if (!mounted) return;
      // If escrow, go to payment screen. Otherwise, go to job details.
      if (state.paymentType == 'escrow') {
        context.go('/jobs/${job.id}/pay?type=escrow&amount=${state.budget}');
      } else {
        context.go('/jobs/${job.id}');
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error posting job: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobPostingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Job'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress step 2
            Row(
              children: [
                Expanded(child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(width: 6),
                Expanded(child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 8),
            Text('Step 2 of 2 — Review & Post',
              style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),

            Text('Review Your Job', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Make sure everything looks correct before posting.',
              style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),

            // Photo thumbnails
            if (state.images.isNotEmpty) ...[
              _Section('Photos (${state.images.length})'),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final img = state.images[i];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: img is File
                              ? Image.file(img, width: 90, height: 90, fit: BoxFit.cover)
                              : Image.network(img as String, width: 90, height: 90,
                                  fit: BoxFit.cover),
                        ),
                        if (i == 0)
                          Positioned(
                            bottom: 4, left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Cover',
                                style: TextStyle(color: Colors.white, fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Job details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _DetailRow('Job Title', state.title),
                  _DetailRow('Category', state.category),
                  _DetailRow('Description', state.description, multiLine: true),
                  _DetailRow('Budget', '\$${state.budget.toStringAsFixed(0)}',
                    valueColor: AppColors.primary, valueBold: true),
                  _DetailRow('Location', state.location),
                  _DetailRow('Date', state.scheduledDate != null
                    ? DateFormat('EEEE, MMM d, yyyy').format(state.scheduledDate!)
                    : '-'),
                  _DetailRow('Time', state.scheduledTime, isLast: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment type
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: state.paymentType == 'escrow'
                    ? AppColors.primarySurface
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: state.paymentType == 'escrow'
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.paymentType == 'escrow'
                        ? Icons.shield_rounded
                        : Icons.payments_outlined,
                    color: state.paymentType == 'escrow'
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.paymentType == 'escrow'
                              ? 'Secure Escrow Payment'
                              : 'Pay After Completion',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          state.paymentType == 'escrow'
                              ? 'Funds held securely until job is complete'
                              : 'Pay the worker directly after the job',
                          style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Commitment fee notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warningSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Commitment Fee Notice',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(AppConstants.commitmentFeeDesc,
                          style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _postJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : const Text('Post Job',
                        style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15));
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool valueBold, multiLine, isLast;

  const _DetailRow(
    this.label, this.value, {
    this.valueColor,
    this.valueBold = false,
    this.multiLine = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: multiLine
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: Text(label,
                  style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
              ),
              Expanded(
                child: Text(value,
                  style: TextStyle(
                    fontWeight: valueBold
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
