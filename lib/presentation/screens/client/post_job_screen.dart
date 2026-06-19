// lib/presentation/screens/client/post_job_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

class PostJobScreen extends ConsumerStatefulWidget {
  const PostJobScreen({super.key});

  @override
  ConsumerState<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends ConsumerState<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? _selectedCategory;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _paymentType = 'escrow';
  final List<File> _images = [];
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final remaining = AppConstants.maxJobImages - _images.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 images reached')));
      return;
    }
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        for (final img in picked.take(remaining)) {
          _images.add(File(img.path));
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  void _proceed() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a job category')));
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least 1 photo')));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date')));
      return;
    }

    // Save to state
    ref.read(jobPostingProvider.notifier).update((s) => s.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _selectedCategory!,
      budget: double.tryParse(_budgetCtrl.text) ?? 0,
      location: _locationCtrl.text.trim(),
      scheduledDate: _selectedDate,
      scheduledTime: _selectedTime?.format(context) ?? '',
      paymentType: _paymentType,
      images: _images,
    ));

    context.push('/review-job');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress
              _ProgressBar(step: 1),
              const SizedBox(height: 24),

              _SectionLabel('Job Category'),
              const SizedBox(height: 10),
              _CategoryDropdown(
                value: _selectedCategory,
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Job Title'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleCtrl,
                validator: (v) => v!.isEmpty ? 'Enter a job title' : null,
                decoration: const InputDecoration(
                  hintText: 'e.g. Lawn cutting and leaf cleanup',
                ),
              ),
              const SizedBox(height: 20),

              _SectionLabel('Description'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                validator: (v) => v!.length < 20 ? 'Please describe the job (20+ chars)' : null,
                decoration: const InputDecoration(
                  hintText: 'Describe what needs to be done, any special requirements, tools needed...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Budget (USD)'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _budgetCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Enter a valid budget';
                            return null;
                          },
                          decoration: const InputDecoration(
                            hintText: '80',
                            prefixText: '\$ ',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Location'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _locationCtrl,
                          validator: (v) => v!.isEmpty ? 'Enter location' : null,
                          decoration: const InputDecoration(
                            hintText: 'City, State',
                            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionLabel('Date & Time'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat('MMM d, yyyy').format(_selectedDate!),
                              style: TextStyle(
                                color: _selectedDate == null
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                              size: 18, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                              style: TextStyle(
                                color: _selectedTime == null
                                    ? AppColors.textTertiary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionLabel('Payment Option'),
              const SizedBox(height: 10),
              _PaymentTypeSelector(
                value: _paymentType,
                onChanged: (v) => setState(() => _paymentType = v),
              ),
              const SizedBox(height: 24),

              // Image Upload
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel('📸 Job Photos'),
                  Text('${_images.length}/${AppConstants.maxJobImages}',
                    style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload photos of the job site to attract the best workers',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _ImageUploadGrid(
                images: _images,
                onAdd: _pickImages,
                onRemove: (i) => setState(() => _images.removeAt(i)),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proceed,
                  child: const Text('Review Job →'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: step >= 2 ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: const TextStyle(
        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: const Text('Select a category'),
      onChanged: onChanged,
      decoration: const InputDecoration(),
      items: AppConstants.jobCategories.map((c) => DropdownMenuItem(
        value: c,
        child: Text(c),
      )).toList(),
    );
  }
}

class _PaymentTypeSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _PaymentTypeSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaymentOption(
          value: 'escrow',
          groupValue: value,
          onChanged: onChanged,
          title: 'Secure Payment Now (Escrow)',
          subtitle: 'Funds held safely until job is complete. Maximum protection.',
          icon: Icons.shield_rounded,
          badge: 'RECOMMENDED',
        ),
        const SizedBox(height: 10),
        _PaymentOption(
          value: 'after_completion',
          groupValue: value,
          onChanged: onChanged,
          title: 'Pay After Completion',
          subtitle: 'Pay the worker directly after the job is done.',
          icon: Icons.payments_outlined,
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value, groupValue, title, subtitle;
  final IconData icon;
  final String? badge;
  final ValueChanged<String> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                color: selected ? Colors.white : AppColors.textSecondary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13,
                          color: selected ? AppColors.primary : AppColors.textPrimary)),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge!,
                            style: const TextStyle(
                              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (_) => onChanged(value),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageUploadGrid extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  const _ImageUploadGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length + 1,
      itemBuilder: (context, index) {
        if (index == images.length) {
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border,
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                    color: AppColors.textTertiary, size: 28),
                  SizedBox(height: 4),
                  Text('Add Photos',
                    style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 11,
                      fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        }

        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                images[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => onRemove(index),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                ),
              ),
            ),
            if (index == 0)
              Positioned(
                bottom: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
    );
  }
}
