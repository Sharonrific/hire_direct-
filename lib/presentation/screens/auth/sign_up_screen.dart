// lib/presentation/screens/auth/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_providers.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  final UserType userType;
  const SignUpScreen({super.key, required this.userType});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  String get _title => widget.userType == UserType.client
      ? "Create Client Account"
      : "Create Worker Account";

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await ref.read(authServiceProvider).signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        userType: widget.userType,
      );

      if (!mounted) return;
      if (widget.userType == UserType.worker) {
        context.go('/worker');
      } else {
        context.go('/client');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = widget.userType == UserType.worker;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isWorker ? AppColors.accentSurface : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isWorker ? Icons.construction_rounded : Icons.person_search_rounded,
                      color: isWorker ? AppColors.accent : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_title,
                          style: Theme.of(context).textTheme.headlineSmall),
                        Text(
                          isWorker ? 'Find local jobs and grow your business'
                              : 'Hire skilled workers near you',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildField('Full Name', _nameCtrl, Icons.person_outline_rounded,
                validator: (v) => v!.isEmpty ? 'Enter your full name' : null),
              const SizedBox(height: 16),
              _buildField('Email Address', _emailCtrl, Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => !v!.contains('@') ? 'Enter a valid email' : null),
              const SizedBox(height: 16),
              _buildField('Phone Number', _phoneCtrl, Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length < 10 ? 'Enter a valid phone number' : null),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                validator: (v) => v!.length < 6 ? 'Password must be 6+ characters' : null,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Worker perks
              if (isWorker) ...[
                _PerksCard(),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium),
                    GestureDetector(
                      onTap: () => context.go('/auth/login'),
                      child: const Text('Sign In',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController ctrl, IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

class _PerksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text('Worker Benefits',
                style: TextStyle(
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                )),
            ],
          ),
          const SizedBox(height: 10),
          for (final perk in [
            'Get paid directly — no middleman',
            'Set your own rates & availability',
            'Escrow protection on every job',
            'Build your reputation with reviews',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                    color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(perk, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
