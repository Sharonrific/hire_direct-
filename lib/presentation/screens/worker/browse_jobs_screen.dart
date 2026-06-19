// lib/presentation/screens/worker/browse_jobs_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/job_model.dart';

class BrowseJobsScreen extends ConsumerStatefulWidget {
  const BrowseJobsScreen({super.key});

  @override
  ConsumerState<BrowseJobsScreen> createState() => _BrowseJobsScreenState();
}

class _BrowseJobsScreenState extends ConsumerState<BrowseJobsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  final List<String> _tabs = ['All', 'General Labor', 'Lawn & Garden',
    'Plumbing', 'Electrical', 'Carpentry', 'Cleaning'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedCategory = _tabs[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Browse Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((cat) => _JobsList(
          category: cat == 'All' ? null : cat,
        )).toList(),
      ),
    );
  }
}

class _JobsList extends ConsumerWidget {
  final String? category;
  const _JobsList({this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(allJobsProvider(category));

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
                const Text('No jobs available',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
                const SizedBox(height: 6),
                Text(
                  category == null
                      ? 'Check back soon for new postings'
                      : 'No ${category!} jobs right now',
                  style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _JobCard(job: jobs[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobModel job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (job.imageUrls.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  job.imageUrls.first,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.image_outlined,
                      color: AppColors.textTertiary, size: 48),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Icon(Icons.work_outline_rounded,
                  color: AppColors.primary, size: 40),
              ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(job.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 2),
                      Text(job.location,
                        style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(job.title,
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(job.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Budget
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentSurface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('\$${job.budget.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.accentDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                      ),
                      const SizedBox(width: 10),
                      // Payment type badge
                      if (job.paymentType == 'escrow')
                        Row(
                          children: const [
                            Icon(Icons.shield_outlined, size: 13, color: AppColors.primary),
                            SizedBox(width: 3),
                            Text('Escrow',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      const Spacer(),
                      // Client name + avatar
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primarySurface,
                            backgroundImage: job.clientPhotoUrl != null
                                ? NetworkImage(job.clientPhotoUrl!)
                                : null,
                            child: job.clientPhotoUrl == null
                                ? Text(
                                    job.clientName.substring(0, 1),
                                    style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      color: AppColors.primary))
                                : null,
                          ),
                          const SizedBox(width: 5),
                          Text(job.clientName.split(' ').first,
                            style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
