// lib/presentation/screens/shared/addon_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../data/models/job_model.dart';

class AddOnScreen extends ConsumerStatefulWidget {
  final String jobId;
  const AddOnScreen({super.key, required this.jobId});

  @override
  ConsumerState<AddOnScreen> createState() => _AddOnScreenState();
}

class _AddOnScreenState extends ConsumerState<AddOnScreen> {
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a description')));
      return;
    }
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')));
      return;
    }

    setState(() => _loading = true);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      final addOn = AddOnModel(
        id: const Uuid().v4(),
        jobId: widget.jobId,
        workerId: user.uid,
        description: _descCtrl.text.trim(),
        price: price,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await ref.read(jobServiceProvider).addAddOn(widget.jobId, addOn);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add-on request sent to client'),
          backgroundColor: AppColors.accent));
      context.pop();
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Add-On Work'),
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Request additional work from the client. They will need to approve and pay before you begin.',
                      style: TextStyle(
                        color: AppColors.primary, fontSize: 13, height: 1.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Description',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Gutter cleaning — noticed gutters are clogged while on site',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Additional Price',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '40',
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                    : const Text('Send Add-On Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/presentation/screens/shared/addon_approval_screen.dart
class AddOnApprovalScreen extends ConsumerWidget {
  final String jobId, addOnId;
  const AddOnApprovalScreen({
    super.key, required this.jobId, required this.addOnId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add-On Request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) return const Center(child: Text('Job not found'));
          final addOn = job.addOns.firstWhere(
            (a) => a.id == addOnId,
            orElse: () => throw Exception('Add-on not found'),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      const Text('Worker is requesting additional work',
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 16),
                      const Text('Description',
                        style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(addOn.description,
                        style: const TextStyle(fontSize: 15, height: 1.5)),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Additional Cost',
                            style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                          Text('\$${addOn.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800, fontSize: 20)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Current Job Total',
                  style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
                Text('\$${job.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('New Total if Approved',
                  style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
                Text('\$${(job.budget + addOn.price).toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800, fontSize: 22)),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await ref.read(jobServiceProvider).updateAddOnStatus(
                            jobId, addOnId, 'declined');
                          if (context.mounted) context.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push(
                          '/jobs/$jobId/pay?type=addon&amount=${addOn.price}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                        child: const Text('Approve & Pay',
                          style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
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
