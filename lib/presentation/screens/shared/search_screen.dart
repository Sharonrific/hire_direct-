// lib/presentation/screens/shared/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedCategory;
  RangeValues _budgetRange = const RangeValues(0, 1000);
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Check for initial category from query params
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchCtrl.addListener(() {
        ref.read(searchQueryProvider.notifier).state = _searchCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(searchCategoryProvider.notifier).state = _selectedCategory;
    ref.read(searchMinBudgetProvider.notifier).state =
        _budgetRange.start > 0 ? _budgetRange.start : null;
    ref.read(searchMaxBudgetProvider.notifier).state =
        _budgetRange.end < 1000 ? _budgetRange.end : null;
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Jobs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search jobs...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(searchQueryProvider.notifier).state = '';
                              })
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  child: Container(
                    width: 48, height: 52,
                    decoration: BoxDecoration(
                      color: _showFilters
                          ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.tune_rounded,
                      color: _showFilters ? Colors.white : AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Filters
          if (_showFilters) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters',
                    style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 14),
                  const Text('Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13,
                      color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: const Text('All Categories'),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    decoration: const InputDecoration(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...AppConstants.jobCategories.map((c) => DropdownMenuItem(
                        value: c, child: Text(c))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Budget Range',
                        style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13,
                          color: AppColors.textSecondary)),
                      Text(
                        '\$${_budgetRange.start.toInt()} – \$${_budgetRange.end.toInt()}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  RangeSlider(
                    values: _budgetRange,
                    min: 0,
                    max: 1000,
                    divisions: 20,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _budgetRange = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _budgetRange = const RangeValues(0, 1000);
                            });
                            _applyFilters();
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _applyFilters();
                            setState(() => _showFilters = false);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Category chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: ['All', ...AppConstants.jobCategories.take(8)].length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cats = ['All', ...AppConstants.jobCategories.take(8)];
                final cat = cats[i];
                final selected = i == 0
                    ? _selectedCategory == null
                    : _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = i == 0 ? null : cat;
                    });
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(cat,
                      style: TextStyle(
                        color: selected
                            ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600 : FontWeight.w400)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Results
          Expanded(
            child: resultsAsync.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                          size: 56, color: AppColors.textTertiary),
                        SizedBox(height: 12),
                        Text('No jobs found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final job = jobs[i];
                    return GestureDetector(
                      onTap: () => context.push('/jobs/${job.id}'),
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
                                  width: 64, height: 64, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 64, height: 64,
                                    color: AppColors.surfaceVariant),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(job.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600, fontSize: 14),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySurface,
                                          borderRadius: BorderRadius.circular(6)),
                                        child: Text(job.category,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 10, fontWeight: FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(job.location,
                                        style: const TextStyle(
                                          color: AppColors.textTertiary, fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('\$${job.budget.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
