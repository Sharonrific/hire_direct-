// lib/presentation/screens/shared/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../data/services/payment_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String paymentType;
  final double amount;

  const PaymentScreen({
    super.key,
    required this.jobId,
    required this.paymentType,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _loading = false;

  String get _title {
    switch (widget.paymentType) {
      case 'escrow': return 'Escrow Payment';
      case 'commitment_fee': return 'Commitment Fee';
      default: return 'Payment';
    }
  }

  String get _description {
    switch (widget.paymentType) {
      case 'escrow':
        return 'Your payment will be held securely in escrow until the job is '
            'confirmed complete by both parties.';
      case 'commitment_fee':
        return 'A \$20 commitment fee protects both you and the worker from no-shows.';
      default:
        return 'Complete your payment to proceed.';
    }
  }

  Future<void> _processPayment() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      final result = widget.paymentType == 'escrow'
          ? await ref.read(paymentServiceProvider).holdEscrow(
              clientId: user.uid,
              jobId: widget.jobId,
              amount: widget.amount,
            )
          : await ref.read(paymentServiceProvider).processPayment(
              amount: widget.amount,
              currency: 'usd',
              description: _title,
              customerId: user.uid,
              jobId: widget.jobId,
              paymentType: widget.paymentType,
            );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.isDemo
                ? '✓ Payment recorded (Demo mode — configure Stripe for real payments)'
                : '✓ Payment successful'),
            backgroundColor: AppColors.accent,
          ),
        );
        context.go('/jobs/${widget.jobId}');
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
        title: Text(_title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: jobAsync.when(
        data: (job) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Secure Payment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(_description,
                            style: const TextStyle(
                              color: Colors.white70, fontSize: 12, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Order summary
              Text('Payment Summary',
                style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    if (job != null) ...[
                      _SummaryRow('Job', job.title),
                      const Divider(height: 20),
                    ],
                    _SummaryRow(
                      widget.paymentType == 'escrow' ? 'Escrow Amount' : 'Amount',
                      '\$${widget.amount.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 20),
                    _SummaryRow('Processing Fee', '\$0.00',
                      note: 'No hidden fees'),
                    const Divider(height: 20),
                    _SummaryRow('Total',
                      '\$${widget.amount.toStringAsFixed(2)}',
                      isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stripe badge
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6772E5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('stripe',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.5)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Payments are processed securely by Stripe. '
                        'We never store your card information.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12, height: 1.4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _processPayment,
                  icon: _loading
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_rounded, size: 18),
                  label: Text(
                    _loading ? 'Processing...'
                        : 'Pay \$${widget.amount.toStringAsFixed(2)} Securely',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_outlined, size: 13, color: AppColors.textTertiary),
                    SizedBox(width: 4),
                    Text('256-bit SSL encryption',
                      style: TextStyle(
                        color: AppColors.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final String? note;
  final bool isTotal;

  const _SummaryRow(this.label, this.value, {this.note, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: TextStyle(
                color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
                fontSize: isTotal ? 16 : 14)),
            if (note != null)
              Text(note!,
                style: const TextStyle(
                  color: AppColors.accent, fontSize: 11)),
          ],
        ),
        Text(value,
          style: TextStyle(
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: isTotal ? 18 : 14)),
      ],
    );
  }
}
