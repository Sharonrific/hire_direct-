// lib/presentation/screens/shared/job_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/user_model.dart';

class JobDetailsScreen extends ConsumerWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final userAsync = ref.watch(currentUserProvider);

    return jobAsync.when(
      data: (job) {
        if (job == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Job not found')),
          );
        }

        final currentUser = userAsync.value;
        final isWorker = currentUser?.userType == UserType.worker;
        final isOwner = currentUser?.uid == job.clientId;
        final isBooked = job.workerID == currentUser?.uid;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // Image gallery header
              SliverAppBar(
                expandedHeight: job.imageUrls.isNotEmpty ? 280 : 120,
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
                  background: job.imageUrls.isNotEmpty
                      ? _ImageCarousel(
                          images: job.imageUrls,
                          jobId: jobId,
                        )
                      : Container(
                          color: AppColors.primarySurface,
                          child: const Icon(Icons.work_outline_rounded,
                            size: 60, color: AppColors.primary),
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(job.category,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(status: job.status),
                          const Spacer(),
                          if (job.paymentType == 'escrow')
                            Row(
                              children: const [
                                Icon(Icons.shield_rounded,
                                  size: 14, color: AppColors.primary),
                                SizedBox(width: 3),
                                Text('Escrow',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Text(job.title,
                        style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Text('\$${job.budget.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w800,
                              color: AppColors.accent)),
                          if (job.addOns.where((a) => a.status == 'approved').isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '+ \$${job.addOns.where((a) => a.status == "approved").fold(0.0, (s, a) => s + a.price).toStringAsFixed(0)} add-ons',
                              style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Client info
                      _ClientInfo(
                        name: job.clientName,
                        photoUrl: job.clientPhotoUrl,
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),

                      // Details
                      _InfoRow(Icons.location_on_outlined, job.location),
                      const SizedBox(height: 8),
                      _InfoRow(Icons.calendar_today_outlined,
                        DateFormat('EEEE, MMM d, yyyy').format(job.scheduledDate)),
                      const SizedBox(height: 8),
                      if (job.scheduledTime.isNotEmpty)
                        _InfoRow(Icons.access_time_rounded, job.scheduledTime),
                      const SizedBox(height: 20),

                      const Divider(),
                      const SizedBox(height: 16),

                      Text('Job Description',
                        style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(job.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 15, height: 1.6)),
                      const SizedBox(height: 24),

                      // Escrow info box
                      if (job.paymentType == 'escrow')
                        _EscrowInfoBox(),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom action bar
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              boxShadow: [BoxShadow(
                color: AppColors.shadow,
                blurRadius: 12,
                offset: Offset(0, -2),
              )],
            ),
            child: Row(
              children: [
                // Message button
                OutlinedButton.icon(
                  onPressed: () async {
                    if (currentUser == null) return;
                    final chat = await ref.read(chatServiceProvider).getOrCreateChat(
                      jobId: jobId,
                      jobTitle: job.title,
                      clientId: job.clientId,
                      clientName: job.clientName,
                      clientPhotoUrl: job.clientPhotoUrl,
                      workerId: isWorker ? currentUser.uid : job.workerID ?? currentUser.uid,
                      workerName: isWorker ? currentUser.fullName : job.workerName ?? currentUser.fullName,
                      workerPhotoUrl: isWorker ? currentUser.photoUrl : job.workerPhotoUrl,
                    );
                    if (context.mounted) {
                      context.push('/chats/${chat.id}?jobId=$jobId');
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(width: 12),

                // Main action button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isWorker && job.status == AppConstants.statusPosted) {
                        context.push('/jobs/${job.id}/book');
                      } else if (isOwner && job.status == AppConstants.statusPosted) {
                        // Client can edit
                      } else if (job.status != AppConstants.statusPosted) {
                        context.push('/jobs/${job.id}/active');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      backgroundColor: isWorker && job.status == AppConstants.statusPosted
                          ? AppColors.accent
                          : AppColors.primary,
                    ),
                    child: Text(
                      isWorker && job.status == AppConstants.statusPosted
                          ? 'Book This Job'
                          : isOwner
                              ? 'View Details'
                              : 'View Progress',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  final List<String> images;
  final String jobId;
  const _ImageCarousel({required this.images, required this.jobId});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  final _controller = PageController();
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          onPageChanged: (i) => setState(() => _current = i),
          itemCount: widget.images.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => context.push('/gallery', extra: {
              'images': widget.images,
              'initialIndex': i,
            }),
            child: Image.network(
              widget.images[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.image_outlined,
                  color: AppColors.textTertiary, size: 48),
              ),
            ),
          ),
        ),
        // Dots indicator
        Positioned(
          bottom: 12,
          left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _current == i ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _current == i ? Colors.white : Colors.white54,
                borderRadius: BorderRadius.circular(3),
              ),
            )),
          ),
        ),
        // Image count
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${_current + 1}/${widget.images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status,
        style: TextStyle(
          color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _ClientInfo extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback onTap;

  const _ClientInfo({required this.name, this.photoUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(name.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Text('Client',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
      ],
    );
  }
}

class _EscrowInfoBox extends StatelessWidget {
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
          Row(
            children: const [
              Icon(Icons.shield_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Escrow Protection',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Payment is held securely in escrow until both parties confirm the job is complete. '
            'Your money is protected throughout the entire process.',
            style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}
