// lib/presentation/screens/shared/active_job_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/job_service.dart';
import '../../../data/services/payment_service.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  final String jobId;
  const ActiveJobScreen({super.key, required this.jobId});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  bool _loading = false;

  final _stages = [
    AppConstants.statusBooked,
    AppConstants.statusInProgress,
    AppConstants.statusAwaitingConfirmation,
    AppConstants.statusCompleted,
    AppConstants.statusPaymentReleased,
  ];

  int _stageIndex(String status) => _stages.indexOf(status).clamp(0, _stages.length - 1);

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _loading = true);
    try {
      await ref.read(jobServiceProvider).updateJobStatus(widget.jobId, newStatus);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _releasePayment(String jobId, String? paymentIntentId) async {
    setState(() => _loading = true);
    try {
      await ref.read(jobServiceProvider).releaseEscrowPayment(jobId);
      if (!mounted) return;
      // Navigate to review screen
      final job = ref.read(jobDetailProvider(jobId)).value;
      if (job != null) {
        context.pushReplacement('/jobs/$jobId/review?revieweeId=${job.workerID}&revieweeName=${job.workerName}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailProvider(widget.jobId));
    final userAsync = ref.watch(currentUserProvider);

    return jobAsync.when(
      data: (job) {
        if (job == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Job not found')));
        }

        final user = userAsync.value;
        final isWorker = user?.userType == UserType.worker;
        final isClient = user?.userType == UserType.client;
        final currentStage = _stageIndex(job.status);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Active Job'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                onPressed: () async {
                  if (user == null) return;
                  final chat = await ref.read(chatServiceProvider).getOrCreateChat(
                    jobId: widget.jobId,
                    jobTitle: job.title,
                    clientId: job.clientId,
                    clientName: job.clientName,
                    clientPhotoUrl: job.clientPhotoUrl,
                    workerId: job.workerID ?? user.uid,
                    workerName: job.workerName ?? user.fullName,
                    workerPhotoUrl: job.workerPhotoUrl,
                  );
                  if (context.mounted) context.push('/chats/${chat.id}?jobId=${widget.jobId}');
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('\$${job.budget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 20)),
                          if (job.addOns.where((a) => a.status == 'approved').isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '+ \$${job.addOns.where((a) => a.status == "approved").fold(0.0, (s, a) => s + a.price).toStringAsFixed(0)} add-ons',
                              style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                          ],
                          const Spacer(),
                          if (job.paymentType == 'escrow')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield_rounded,
                                    color: AppColors.primary, size: 13),
                                  SizedBox(width: 4),
                                  Text('Escrow',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status progress tracker
                Text('Job Progress',
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _StatusTracker(stages: _stages, currentIndex: currentStage),
                const SizedBox(height: 28),

                // Parties
                Row(
                  children: [
                    Expanded(child: _PartyCard(
                      label: 'Client',
                      name: job.clientName,
                      photoUrl: job.clientPhotoUrl,
                    )),
                    const SizedBox(width: 12),
                    if (job.workerName != null)
                      Expanded(child: _PartyCard(
                        label: 'Worker',
                        name: job.workerName!,
                        photoUrl: job.workerPhotoUrl,
                      )),
                  ],
                ),
                const SizedBox(height: 24),

                // Add-ons section
                if (job.addOns.isNotEmpty) ...[
                  Text('Add-On Work',
                    style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...job.addOns.map((addOn) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AddOnTile(
                      addOn: addOn,
                      isClient: isClient,
                      jobId: widget.jobId,
                    ),
                  )),
                  const SizedBox(height: 12),
                ],

                // Action buttons
                if (isWorker) ...[
                  if (job.status == AppConstants.statusBooked) ...[
                    _ActionButton(
                      label: 'Mark as In Progress',
                      icon: Icons.play_arrow_rounded,
                      color: AppColors.statusInProgress,
                      onTap: () => _updateStatus(AppConstants.statusInProgress),
                      loading: _loading,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (job.status == AppConstants.statusInProgress) ...[
                    _ActionButton(
                      label: 'Mark Job Complete',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.accent,
                      onTap: () => _updateStatus(AppConstants.statusAwaitingConfirmation),
                      loading: _loading,
                    ),
                    const SizedBox(height: 12),
                    _ActionButton(
                      label: '+ Add Work / Request Add-On',
                      icon: Icons.add_circle_outline_rounded,
                      color: AppColors.primary,
                      outlined: true,
                      onTap: () => context.push('/jobs/${widget.jobId}/addon'),
                      loading: false,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                if (isClient) ...[
                  if (job.status == AppConstants.statusAwaitingConfirmation) ...[
                    _ActionButton(
                      label: 'Confirm Job Complete',
                      icon: Icons.verified_rounded,
                      color: AppColors.statusCompleted,
                      onTap: () => _updateStatus(AppConstants.statusCompleted),
                      loading: _loading,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (job.status == AppConstants.statusCompleted &&
                      job.paymentType == 'escrow') ...[
                    _ActionButton(
                      label: 'Release Payment to Worker',
                      icon: Icons.payments_rounded,
                      color: AppColors.accent,
                      onTap: () => _releasePayment(
                        widget.jobId, job.stripePaymentIntentId),
                      loading: _loading,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (job.status == AppConstants.statusCompleted ||
                      job.status == AppConstants.statusPaymentReleased) ...[
                    _ActionButton(
                      label: 'Leave a Review',
                      icon: Icons.star_rounded,
                      color: AppColors.warning,
                      outlined: true,
                      onTap: () => context.push(
                        '/jobs/${widget.jobId}/review?revieweeId=${job.workerID}&revieweeName=${job.workerName}'),
                      loading: false,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e'))),
    );
  }
}

class _StatusTracker extends StatelessWidget {
  final List<String> stages;
  final int currentIndex;
  const _StatusTracker({required this.stages, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stages.length, (i) {
        final isDone = i < currentIndex;
        final isCurrent = i == currentIndex;
        final isLast = i == stages.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.accent
                        : isCurrent
                            ? AppColors.primary
                            : AppColors.border,
                    border: isCurrent
                        ? Border.all(color: AppColors.primary, width: 3)
                        : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 16)
                      : isCurrent
                          ? const SizedBox.shrink()
                          : null,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: isDone ? AppColors.accent : AppColors.border,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stages[i],
                    style: TextStyle(
                      fontWeight: isCurrent
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.primary
                          : isDone
                              ? AppColors.accent
                              : AppColors.textTertiary,
                      fontSize: 14)),
                  if (isCurrent)
                    const Text('Current status',
                      style: TextStyle(
                        color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final String label, name;
  final String? photoUrl;
  const _PartyCard({required this.label, required this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(name.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11)),
                Text(name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddOnTile extends StatelessWidget {
  final dynamic addOn;
  final bool isClient;
  final String jobId;
  const _AddOnTile({required this.addOn, required this.isClient, required this.jobId});

  Color get _statusColor {
    switch (addOn.status) {
      case 'approved': return AppColors.accent;
      case 'declined': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addOn.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('\$${addOn.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(addOn.status.toString().toUpperCase(),
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isClient && addOn.status == 'pending')
            TextButton(
              onPressed: () => context.push(
                '/jobs/$jobId/addon-approval/${addOn.id}'),
              child: const Text('Review'),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool loading;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.loading,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: loading ? null : onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
            : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
