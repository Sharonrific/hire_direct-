// lib/presentation/screens/shared/profile_settings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/job_service.dart';
import '../../../providers/app_providers.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _tradeTitleCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  String _selectedLang = 'en';
  bool _generalLabor = true;
  bool _saving = false;
  File? _newPhoto;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _nameCtrl.text = user.fullName;
        _bioCtrl.text = user.bio ?? '';
        _locationCtrl.text = user.location ?? '';
        _tradeTitleCtrl.text = user.tradeTitle ?? '';
        _rateCtrl.text = user.hourlyRate?.toStringAsFixed(0) ?? '';
        _skillsCtrl.text = (user.skills ?? []).join(', ');
        _selectedLang = user.preferredLanguage;
        _generalLabor = user.availableForGeneralLabor ?? true;
      }
    });
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _bioCtrl, _locationCtrl,
        _tradeTitleCtrl, _rateCtrl, _skillsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _newPhoto = File(picked.path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      String? photoUrl = user.photoUrl;
      if (_newPhoto != null) {
        photoUrl = await ref.read(jobServiceProvider).uploadSingleImage(
          'users/${user.uid}/avatar.jpg', _newPhoto!);
      }

      final updated = user.copyWith(
        fullName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        photoUrl: photoUrl,
        preferredLanguage: _selectedLang,
        tradeTitle: user.userType == UserType.worker ? _tradeTitleCtrl.text.trim() : null,
        hourlyRate: user.userType == UserType.worker
            ? double.tryParse(_rateCtrl.text) : null,
        skills: user.userType == UserType.worker
            ? _skillsCtrl.text.split(',').map((s) => s.trim())
                .where((s) => s.isNotEmpty).toList()
            : null,
        availableForGeneralLabor: user.userType == UserType.worker
            ? _generalLabor : null,
      );

      await ref.read(authServiceProvider).updateUser(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: AppColors.accent));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));
        final isWorker = user.userType == UserType.worker;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile & Settings'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.primarySurface,
                          backgroundImage: _newPhoto != null
                              ? FileImage(_newPhoto!)
                              : user.photoUrl != null
                                  ? NetworkImage(user.photoUrl!) as ImageProvider
                                  : null,
                          child: _newPhoto == null && user.photoUrl == null
                              ? Text(user.fullName.substring(0, 1),
                                  style: const TextStyle(
                                    fontSize: 32, color: AppColors.primary,
                                    fontWeight: FontWeight.w700))
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(user.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
                ),
                const SizedBox(height: 28),

                _Section('Personal Info'),
                const SizedBox(height: 12),
                _Field('Full Name', _nameCtrl, Icons.person_outline_rounded),
                const SizedBox(height: 14),
                _Field('Location', _locationCtrl, Icons.location_on_outlined),
                const SizedBox(height: 14),
                _Field('Bio', _bioCtrl, Icons.info_outline_rounded, maxLines: 3),
                const SizedBox(height: 24),

                _Section('Preferences'),
                const SizedBox(height: 12),
                // Language preference
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.translate_rounded,
                        color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Preferred Language',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                      DropdownButton<String>(
                        value: _selectedLang,
                        underline: const SizedBox.shrink(),
                        onChanged: (v) =>
                            setState(() => _selectedLang = v ?? 'en'),
                        items: AppConstants.supportedLanguages.entries
                            .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value)))
                            .toList(),
                      ),
                    ],
                  ),
                ),

                if (isWorker) ...[
                  const SizedBox(height: 24),
                  _Section('Worker Profile'),
                  const SizedBox(height: 12),
                  _Field('Trade Title', _tradeTitleCtrl, Icons.work_outline_rounded),
                  const SizedBox(height: 14),
                  _Field('Hourly Rate (\$)', _rateCtrl, Icons.attach_money_rounded,
                    keyboardType: TextInputType.number),
                  const SizedBox(height: 14),
                  _Field('Skills (comma separated)', _skillsCtrl,
                    Icons.star_outline_rounded, maxLines: 2),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_rounded,
                          color: AppColors.accent, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Available for General Labor',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('Appear in General Labor job listings',
                                style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _generalLabor,
                          onChanged: (v) => setState(() => _generalLabor = v),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
                // Sign out
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/onboarding');
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: const TextStyle(
        fontWeight: FontWeight.w700, fontSize: 16,
        color: AppColors.textPrimary));
  }
}

class _Field extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field(this.hint, this.ctrl, this.icon, {
    this.maxLines = 1, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}
