import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/models/user_model.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Firebase auth tayyor bo'lishini kutamiz
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final auth = ref.read(firebaseAuthProvider);
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      // Login qilinmagan
      context.go('/login');
      return;
    }

    // Login qilingan — Firestore dan role o'qiymiz
    try {
      final doc = await ref
          .read(firestoreProvider)
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!mounted) return;

      if (!doc.exists) {
        // Firestore da user yo'q — login ga
        await ref.read(firebaseAuthProvider).signOut();
        context.go('/login');
        return;
      }

      final user = UserModel.fromMap(doc.data()!, doc.id);
      context.go(user.isParent ? '/parent' : '/child');
    } catch (e) {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Center(
                child: Text('🧠', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 20),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                children: [
                  TextSpan(text: 'BolaJon '),
                  TextSpan(
                    text: 'OS',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'After-School Growth System',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}