import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Role qaytaradi — Firestore dan bir marta o'qiydi
    final role = await ref.read(authNotifierProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!mounted) return;

    if (role == null) {
      // Xato tekshirish
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(authState.error.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    // Role bor — yo'naltir
    if (role == UserRole.parent) {
      context.go('/parent');
    } else {
      context.go('/child');
    }
  }

  String _friendlyError(String error) {
    if (error.contains('user-not-found') ||
        error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Email yoki parol noto\'g\'ri';
    }
    if (error.contains('too-many-requests')) {
      return 'Juda ko\'p urinish. Keyinroq urinib ko\'ring';
    }
    if (error.contains('network')) {
      return 'Internet aloqasi yo\'q';
    }
    return 'Xatolik yuz berdi. Qayta urinib ko\'ring';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: Text('🧠', style: TextStyle(fontSize: 30)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Xush kelibsiz!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hisobingizga kiring',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 36),
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
                  hint: '••••••••',
                  obscureText: _obscure,
                  validator: (v) =>
                  v!.length >= 6 ? null : 'Kamida 6 ta belgi',
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: 'Kirish',
                  isLoading: isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text.rich(
                      TextSpan(
                        text: 'Hisob yo\'qmi? ',
                        style: TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: 'Ro\'yxatdan o\'tish',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}