import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'models/user_model.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  UserRole _role = UserRole.parent;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      role: _role,
      parentCode: _role == UserRole.child
          ? _codeCtrl.text.trim()
          : null,
    );
    final state = ref.read(authNotifierProvider);
    if (mounted && state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ro'yxatdan o'tish"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Role selector
                const Text(
                  'Siz kimsiz?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _RoleChip(
                      icon: '👨‍👩‍👧',
                      label: 'Ota-ona',
                      selected: _role == UserRole.parent,
                      onTap: () => setState(() => _role = UserRole.parent),
                    ),
                    const SizedBox(width: 12),
                    _RoleChip(
                      icon: '🧒',
                      label: 'Bola',
                      selected: _role == UserRole.child,
                      onTap: () => setState(() => _role = UserRole.child),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Ism',
                  hint: 'To\'liq ismingiz',
                  validator: (v) =>
                  v!.length >= 2 ? null : 'Ismni kiriting',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'email@misol.uz',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  v!.contains('@') ? null : 'Email noto\'g\'ri',
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Parol',
                  hint: 'Kamida 6 ta belgi',
                  obscureText: true,
                  validator: (v) =>
                  v!.length >= 6 ? null : 'Kamida 6 ta belgi',
                ),
                if (_role == UserRole.child) ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _codeCtrl,
                    label: "Ota-ona kodi",
                    hint: 'Masalan: ABC123',
                    validator: (v) =>
                    v!.length == 6 ? null : '6 ta belgi kiriting',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ota-ona kodini ota-onangizdan oling.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                AppButton(
                  label: "Ro'yxatdan o'tish",
                  isLoading: isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}